using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class OutfitIdeasService : CRUDService<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeas, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>, IOutfitIdeasService
    {
        private new readonly CocoSunBagsWebshopDbContext _context;
        private new readonly IMapper _mapper;

        public OutfitIdeasService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<OutfitIdea>> Get(OutfitIdeaSearchRequest request)
        {
            request ??= new OutfitIdeaSearchRequest();
            var query = _context.OutfitIdeas
                .Include(x => x.Images)
                .AsQueryable();

            if (request.BagID.HasValue && request.BagID.Value > 0)
            {
                query = query.Where(x => x.BagID == request.BagID.Value);
            }

            if (request.BeltID.HasValue && request.BeltID.Value > 0)
            {
                query = query.Where(x => x.BeltID == request.BeltID.Value);
            }

            if (request.UserID.HasValue && request.UserID.Value > 0)
            {
                query = query.Where(x => x.UserID == request.UserID.Value);
            }

            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                query = query.Where(x => x.Title != null && x.Title.Contains(request.Title));
            }

            var list = await query.OrderByDescending(x => x.CreatedAt).ToListAsync();
            return _mapper.Map<List<OutfitIdea>>(list);
        }

        public override async Task<OutfitIdea> GetById(int id)
        {
            var entity = await _context.OutfitIdeas
                .Include(x => x.Images.OrderBy(i => i.DisplayOrder))
                .FirstOrDefaultAsync(x => x.OutfitIdeaID == id);

            return _mapper.Map<OutfitIdea>(entity);
        }

        public async Task<OutfitIdea?> GetByBagAndUser(int bagId, int userId)
        {
            var entity = await _context.OutfitIdeas
                .Include(x => x.Images.OrderBy(i => i.DisplayOrder))
                .FirstOrDefaultAsync(x => x.BagID == bagId && x.UserID == userId);

            return entity != null ? _mapper.Map<OutfitIdea>(entity) : null;
        }

        public async Task<OutfitIdea?> GetByBeltAndUser(int beltId, int userId)
        {
            var entity = await _context.OutfitIdeas
                .Include(x => x.Images.OrderBy(i => i.DisplayOrder))
                .FirstOrDefaultAsync(x => x.BeltID == beltId && x.UserID == userId);

            return entity != null ? _mapper.Map<OutfitIdea>(entity) : null;
        }

        public override async Task<OutfitIdea> Insert(OutfitIdeaUpsertRequest request)
        {
            if (!request.BagID.HasValue && !request.BeltID.HasValue)
            {
                throw new ArgumentException("Either BagID or BeltID must be set.");
            }
            if (request.BagID.HasValue && request.BeltID.HasValue)
            {
                throw new ArgumentException("Only one of BagID or BeltID should be set.");
            }
            // Validate foreign keys exist before insert
            var userExists = await _context.Users.AnyAsync(u => u.UserID == request.UserID);
            if (!userExists)
                throw new ArgumentException("Korisnik sa tim ID-om ne postoji.");
            if (request.BeltID.HasValue)
            {
                var beltExists = await _context.Belts.AnyAsync(b => b.BeltID == request.BeltID.Value);
                if (!beltExists)
                    throw new ArgumentException("Kaiš sa tim ID-om ne postoji.");
            }
            if (request.BagID.HasValue)
            {
                var bagExists = await _context.Bags.AnyAsync(b => b.BagID == request.BagID.Value);
                if (!bagExists)
                    throw new ArgumentException("Torba sa tim ID-om ne postoji.");
            }
            var entity = _mapper.Map<OutfitIdeas>(request);
            entity.CreatedAt = DateTime.UtcNow;
            
            _context.OutfitIdeas.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<OutfitIdea>(entity);
        }

        public override async Task<OutfitIdea> Update(int id, OutfitIdeaUpsertRequest request)
        {
            var entity = await _context.OutfitIdeas.FindAsync(id);
            if (entity == null)
            {
                throw new Exception("Outfit idea not found");
            }

            _mapper.Map(request, entity);
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return _mapper.Map<OutfitIdea>(entity);
        }

        public async Task<OutfitIdeaImage> AddImage(OutfitIdeaImageUpsertRequest request)
        {
            var outfitIdea = await _context.OutfitIdeas.FindAsync(request.OutfitIdeaID);
            if (outfitIdea == null)
            {
                throw new Exception("Outfit idea not found");
            }

            var imageEntity = new OutfitIdeaImages
            {
                OutfitIdeaID = request.OutfitIdeaID,
                Image = !string.IsNullOrWhiteSpace(request.Image)
                    ? Convert.FromBase64String(request.Image)
                    : Array.Empty<byte>(),
                Caption = request.Caption,
                DisplayOrder = request.DisplayOrder,
                CreatedAt = DateTime.UtcNow
            };

            _context.OutfitIdeaImages.Add(imageEntity);
            
            outfitIdea.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();

            return _mapper.Map<OutfitIdeaImage>(imageEntity);
        }

        public async Task<bool> RemoveImage(int imageId)
        {
            var image = await _context.OutfitIdeaImages.FindAsync(imageId);
            if (image == null)
            {
                return false;
            }

            var outfitIdea = await _context.OutfitIdeas.FindAsync(image.OutfitIdeaID);
            if (outfitIdea != null)
            {
                outfitIdea.UpdatedAt = DateTime.UtcNow;
            }

            _context.OutfitIdeaImages.Remove(image);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<List<OutfitIdeaImage>> GetImages(int outfitIdeaId)
        {
            var images = await _context.OutfitIdeaImages
                .Where(x => x.OutfitIdeaID == outfitIdeaId)
                .OrderBy(x => x.DisplayOrder)
                .ToListAsync();

            return _mapper.Map<List<OutfitIdeaImage>>(images);
        }
    }
}
