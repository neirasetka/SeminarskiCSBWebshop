using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
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
        public async override Task<List<User>> Get(UserSearchRequest search)
        {
            var query = _context.Users.Include(x => x.UserRoles).AsQueryable().OrderBy(c => c.UserName);

            if (!string.IsNullOrWhiteSpace(search?.UserName))
            {
                query = query.Where(x => x.UserName.ToLower().StartsWith(search.UserName.ToLower())).OrderBy(c => c.UserName);
            }
            var list = await query.ToListAsync();
            return _mapper.Map<List<User>>(list);
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
                throw new Exception("Passwords do not match!");
            }

            if (await _context.Users.AnyAsync(u => u.UserName == request.UserName))
            {
                throw new InvalidOperationException("Korisničko ime je već zauzeto.");
            }

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new InvalidOperationException("Email adresa je već registrirana.");
            }

            var entity = _mapper.Map<Users>(request);
            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            entity.Image = request.Image ?? Array.Empty<byte>();

            await _context.Users.AddAsync(entity);
            await _context.SaveChangesAsync();

            foreach (var roleID in request.Roles)
            {
                var roles = new UserRoles()
                {
                    UserID = entity.UserID,
                    RolesID = roleID
                };

                await _context.UserRoles.AddAsync(roles);
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<User>(entity);
        }
        public override async Task<User> Update(int ID, UserUpsertRequest request)
        {
            var entity = _context.Users.Find(ID);
            if (entity == null)
                throw new ArgumentException($"User with ID {ID} not found.");

            _context.Users.Attach(entity);
            _context.Users.Update(entity);

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                if (request.Password != request.PasswordConfirmation)
                {
                    throw new Exception("Passwords do not match!");
                }

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            foreach (var RoleID in request.Roles)
            {
                var userRoles = await _context.UserRoles
                    .Where(i => i.RolesID == RoleID && i.UserID == ID)
                    .SingleOrDefaultAsync();

                if (userRoles == null)
                {
                    var newRole = new UserRoles()
                    {
                        UserID = ID,
                        RolesID = RoleID
                    };
                    await _context.Set<UserRoles>().AddAsync(newRole);
                }
            }
            foreach (var RolesID in request.RolesDelete)
            {
                var userRoles = await _context.UserRoles
                    .Where(i => i.RolesID == RolesID && i.UserID == ID)
                    .SingleOrDefaultAsync();

                if (userRoles != null)
                {
                    _context.Set<UserRoles>().Remove(userRoles);
                }
            }
            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<User>(entity);
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
        public async Task<User> Login(UserUpsertRequest request)
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new Exception("Passwords do not match!");
            }
            request.Roles = new List<int> { 1, 2 };
            var entity = _mapper.Map<Users>(request);
            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

            await _context.Users.AddAsync(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<User>(entity);
        }

        public async Task<List<Bag>> GetLikedBags(int ID, BagSearchRequest request)
        {
            var query = _context.Favorites
                .Include(i => i.Bag)
                .ThenInclude(i => i.User)
                .Where(i => i.UserID == ID && i.BagID.HasValue)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.BagName))
            {
                query = query.Where(x => x.Bag.BagName.StartsWith(request.BagName));
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<Bag>>(list.Select(i => i.Bag!).ToList());
        }

        public async Task<Bag> InsertLikedBags(int ID, int BagID)
        {
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
                throw new ArgumentException("Favorite not found.");

            _context.Favorites.Remove(entity);
            await _context.SaveChangesAsync();

            var bag = await _context.Bags.FindAsync(BagID);
            return _mapper.Map<Bag>(bag!);
        }

        public async Task<List<Belt>> GetLikedBelts(int ID, BeltSearchRequest request)
        {
            var query = _context.Favorites
                .Include(i => i.Belt)
                .ThenInclude(i => i.User)
                .Where(i => i.UserID == ID && i.BeltID.HasValue)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(request?.BeltName))
            {
                query = query.Where(x => x.Belt.BeltName.StartsWith(request.BeltName));
            }
            var list = await query.ToListAsync();

            return _mapper.Map<List<Belt>>(list.Select(i => i.Belt!).ToList());
        }

        public async Task<Belt> InsertLikedBelts(int ID, int BeltID)
        {
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
                throw new ArgumentException("Favorite not found.");

            _context.Favorites.Remove(entity);
            await _context.SaveChangesAsync();

            var belt = await _context.Belts.FindAsync(BeltID);
            return _mapper.Map<Belt>(belt!);
        }
    }
}
