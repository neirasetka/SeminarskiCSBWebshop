using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace CBSWebshopSeminarski.Services.Services
{
    public class UsersService : CRUDService<User, UserSearchRequest, Users, UserUpsertRequest, UserUpsertRequest>, IUsersService
    {
        private const int Pbkdf2IterCount = 100_000;
        private const int Pbkdf2SaltSize = 16;
        private const int Pbkdf2KeySize = 32;

        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;
        public UsersService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public async override Task<PagedResult<User>> Get(UserSearchRequest search)
        {
            var query = _context.Users.Include(x => x.UserRoles).AsQueryable().OrderBy(c => c.UserName);

            if (!string.IsNullOrWhiteSpace(search?.UserName))
            {
                query = query.Where(x => x.UserName.ToLower().StartsWith(search.UserName.ToLower())).OrderBy(c => c.UserName);
            }

            return await ToPagedResultAsync(query, search);
        }

        public override async Task<User> GetById(int ID)
        {
            var entity = await _context.Set<Users>()
                .Where(i => i.UserID == ID)
                .Include(i => i.UserRoles)
                .SingleOrDefaultAsync();

            return _mapper.Map<User>(entity);
        }
        public override async Task<User> Insert(UserUpsertRequest request)
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new ValidationException("Passwords do not match!");
            }

            if (await _context.Users.AnyAsync(u => u.UserName == request.UserName))
            {
                throw new BusinessException("Korisničko ime je već zauzeto.");
            }

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new BusinessException("Email adresa je već registrirana.");
            }

            return await _context.ExecuteInTransactionAsync(async () =>
            {
                var roleIds = await ResolveRoleIdsByNamesAsync(request.RoleNames);
                var entity = _mapper.Map<Users>(request);
                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
                entity.Image = request.Image ?? Array.Empty<byte>();
                entity.UserRoles = roleIds
                    .Select(roleId => new UserRoles { RolesID = roleId })
                    .ToList();

                await _context.Users.AddAsync(entity);
                await _context.SaveChangesAsync();

                return _mapper.Map<User>(entity);
            });
        }
        public async Task<User> UpdateMyProfile(int userId, UserProfileUpdateRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.UserID != userId))
            {
                throw new BusinessException("Email adresa je već registrirana.");
            }

            if (await _context.Users.AnyAsync(u => u.UserName == request.UserName && u.UserID != userId))
            {
                throw new BusinessException("Korisničko ime je već zauzeto.");
            }

            var entity = await _context.Users.FindAsync(userId);
            if (entity == null)
            {
                throw new NotFoundException($"User with ID {userId} not found.");
            }

            entity.Name = request.Name;
            entity.Surname = request.Surname;
            entity.Email = request.Email;
            entity.UserName = request.UserName;
            entity.Phone = request.Phone ?? string.Empty;
            if (request.Image != null && request.Image.Length > 0)
            {
                entity.Image = request.Image;
            }

            await _context.SaveChangesAsync();

            var reloaded = await _context.Set<Users>()
                .Where(i => i.UserID == userId)
                .Include(i => i.UserRoles)
                .ThenInclude(j => j.Roles)
                .SingleAsync();

            return _mapper.Map<User>(reloaded);
        }

        public override async Task<User> Update(int ID, UserUpsertRequest request)
        {
            return await _context.ExecuteInTransactionAsync(async () =>
            {
                var entity = _context.Users.Find(ID);
                if (entity == null)
                    throw new NotFoundException($"User with ID {ID} not found.");

                _context.Users.Attach(entity);
                _context.Users.Update(entity);

                if (!string.IsNullOrWhiteSpace(request.Password))
                {
                    if (request.Password != request.PasswordConfirmation)
                    {
                        throw new ValidationException("Passwords do not match!");
                    }

                    entity.PasswordSalt = GenerateSalt();
                    entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
                }

                foreach (var roleId in await ResolveRoleIdsByNamesAsync(request.RoleNames))
                {
                    var userRoles = await _context.UserRoles
                        .Where(i => i.RolesID == roleId && i.UserID == ID)
                        .SingleOrDefaultAsync();

                    if (userRoles == null)
                    {
                        await _context.Set<UserRoles>().AddAsync(new UserRoles
                        {
                            UserID = ID,
                            RolesID = roleId
                        });
                    }
                }

                foreach (var roleId in await ResolveRoleIdsByNamesAsync(request.RoleNamesDelete))
                {
                    var userRoles = await _context.UserRoles
                        .Where(i => i.RolesID == roleId && i.UserID == ID)
                        .SingleOrDefaultAsync();

                    if (userRoles != null)
                    {
                        _context.Set<UserRoles>().Remove(userRoles);
                    }
                }
                _mapper.Map(request, entity);
                await _context.SaveChangesAsync();

                return _mapper.Map<User>(entity);
            });
        }
        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.Users.
                Include(i => i.UserRoles).Include(i => i.Reviews).Include(i => i.Rates).
                FirstOrDefaultAsync(i => i.UserID == ID);

            if (entity == null)
                return false;

            if (entity.UserRoles.Count != 0)
                _context.UserRoles.RemoveRange(entity.UserRoles);

            if (entity.Reviews.Count != 0)
                _context.Reviews.RemoveRange(entity.Reviews);
            if (entity.Rates.Count != 0)
                _context.Rates.RemoveRange(entity.Rates);


            var rates = await _context.Rates.Where(i => i.UserID == ID).ToListAsync();
            if (rates.Count > 0)
            {
                _context.Rates.RemoveRange(rates);
            }
            var reviews = await _context.Reviews.Where(i => i.UserID == ID).ToListAsync();
            if (reviews.Count > 0)
            {
                _context.Reviews.RemoveRange(reviews);
            }

            var favorites = await _context.Favorites.Where(i => i.UserID == ID).ToListAsync();
            if (favorites.Count > 0)
            {
                _context.Favorites.RemoveRange(favorites);
            }
            var transactions = await _context.Transactions.Where(i => i.UserID == ID).ToListAsync();
            if (transactions.Count > 0)
            {
                _context.Transactions.RemoveRange(transactions);
            }
            var orders = await _context.Orders.Where(i => i.UserID == ID).ToListAsync();
            if (orders.Count > 0)
            {
                _context.Orders.RemoveRange(orders);
            }
            var purchases = await _context.Purchases.Where(i => i.UserID == ID).ToListAsync();
            if (purchases.Count > 0)
            {
                _context.Purchases.RemoveRange(purchases);
            }
            _context.Users.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        public static string GenerateSalt()
        {
            var saltBytes = RandomNumberGenerator.GetBytes(Pbkdf2SaltSize);
            return Convert.ToBase64String(saltBytes);
        }

        public static string GenerateHash(string salt, string password)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var deriveBytes = new Rfc2898DeriveBytes(password, saltBytes, Pbkdf2IterCount, HashAlgorithmName.SHA256);
            var key = deriveBytes.GetBytes(Pbkdf2KeySize);
            return Convert.ToBase64String(key);
        }

        public async Task<User?> Authenticate(UserAuthenticationRequest request)
        {
            var user = await _context.Users
                .Include(i => i.UserRoles)
                .ThenInclude(j => j.Roles)
                .FirstOrDefaultAsync(i => i.UserName == request.UserName);

            if (user != null)
            {
                var newHash = GenerateHash(user.PasswordSalt, request.Password);

                if (newHash == user.PasswordHash)
                {
                    return _mapper.Map<User>(user);
                }
            }
            return null;
        }
        public async Task<User> Register(RegisterRequest request)
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new ValidationException("Passwords do not match!");
            }

            if (await _context.Users.AnyAsync(u => u.UserName == request.UserName))
            {
                throw new BusinessException("Korisničko ime je već zauzeto.");
            }

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new BusinessException("Email adresa je već registrirana.");
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var buyerRole = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Buyer");

                var entity = new Users
                {
                    Name = request.Name,
                    Surname = request.Surname,
                    Email = request.Email,
                    Phone = request.Phone ?? string.Empty,
                    UserName = request.UserName,
                    Image = request.Image ?? Array.Empty<byte>(),
                    UserRoles = buyerRole != null
                        ? new List<UserRoles> { new UserRoles { RolesID = buyerRole.RoleID } }
                        : new List<UserRoles>()
                };
                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

                await _context.Users.AddAsync(entity);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return _mapper.Map<User>(entity);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<PagedResult<Bag>> GetLikedBags(int ID, BagSearchRequest request)
        {
            request ??= new BagSearchRequest();
            var query = _context.Favorites
                .Include(i => i.Bag)
                .ThenInclude(i => i.User)
                .Where(i => i.UserID == ID && i.BagID.HasValue)
                .Select(i => i.Bag!)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request.BagName))
            {
                query = query.Where(x => x.BagName.StartsWith(request.BagName));
            }

            query = query.OrderBy(x => x.BagName);
            return await PagedQueryHelper.ToPagedResultAsync<Bags, Bag>(query, request, _mapper);
        }

        public async Task<Bag> InsertLikedBags(int ID, int BagID)
        {
            if (await _context.Favorites.AnyAsync(f => f.UserID == ID && f.BagID == BagID))
                throw new ConflictException("Ova torba je već u vašim favoritima.");

            var entity = new Favorites()
            {
                UserID = ID,
                BagID = BagID
            };

            await _context.Favorites.AddAsync(entity);
            await _context.SaveChangesAsync();

            var bag = await _context.Bags.FindAsync(BagID);
            return _mapper.Map<Bag>(bag!);
        }

        public async Task<Bag> DeleteLikedBags(int ID, int BagID)
        {
            var entity = await _context.Favorites
                .Where(i => i.UserID == ID && i.BagID == BagID).Include(i => i.Bag)
                .SingleOrDefaultAsync();

            if (entity == null)
                throw new NotFoundException("Favorite not found.");

            _context.Favorites.Remove(entity);
            await _context.SaveChangesAsync();

            var bag = await _context.Bags.FindAsync(BagID);
            return _mapper.Map<Bag>(bag!);
        }

        public async Task<PagedResult<Belt>> GetLikedBelts(int ID, BeltSearchRequest request)
        {
            request ??= new BeltSearchRequest();
            var query = _context.Favorites
                .Include(i => i.Belt)
                .ThenInclude(i => i.User)
                .Where(i => i.UserID == ID && i.BeltID.HasValue)
                .Select(i => i.Belt!)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request.BeltName))
            {
                query = query.Where(x => x.BeltName.StartsWith(request.BeltName));
            }

            query = query.OrderBy(x => x.BeltName);
            return await PagedQueryHelper.ToPagedResultAsync<Belts, Belt>(query, request, _mapper);
        }

        public async Task<Belt> InsertLikedBelts(int ID, int BeltID)
        {
            if (await _context.Favorites.AnyAsync(f => f.UserID == ID && f.BeltID == BeltID))
                throw new ConflictException("Ovaj kaiš je već u vašim favoritima.");

            var entity = new Favorites()
            {
                UserID = ID,
                BeltID = BeltID
            };

            await _context.Favorites.AddAsync(entity);
            await _context.SaveChangesAsync();

            var belt = await _context.Belts.FindAsync(BeltID);
            return _mapper.Map<Belt>(belt!);
        }

        public async Task<Belt> DeleteLikedBelts(int ID, int BeltID)
        {
            var entity = await _context.Favorites
                .Where(i => i.UserID == ID && i.BeltID == BeltID).Include(i => i.Belt)
                .SingleOrDefaultAsync();

            if (entity == null)
                throw new NotFoundException("Favorite not found.");

            _context.Favorites.Remove(entity);
            await _context.SaveChangesAsync();

            var belt = await _context.Belts.FindAsync(BeltID);
            return _mapper.Map<Belt>(belt!);
        }

        private async Task<List<int>> ResolveRoleIdsByNamesAsync(IEnumerable<string> roleNames)
        {
            var names = roleNames
                .Where(n => !string.IsNullOrWhiteSpace(n))
                .Select(n => n.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (names.Count == 0)
                return new List<int>();

            var allRoles = await _context.Roles.AsNoTracking().ToListAsync();
            var roleIds = new List<int>();

            foreach (var name in names)
            {
                var role = allRoles.FirstOrDefault(r =>
                    string.Equals(r.RoleName, name, StringComparison.OrdinalIgnoreCase));

                if (role == null)
                    throw new ValidationException($"Uloga '{name}' ne postoji.");

                roleIds.Add(role.RoleID);
            }

            return roleIds;
        }
    }
}
