using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class LookbookService : CRUDService<LookbookItem, LookbookSearchRequest, LookbookItems, LookbookUpsertRequest, LookbookUpsertRequest>, ILookbookService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;

        public LookbookService(CocoSunBagsWebshopDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public override async Task<List<LookbookItem>> Get(LookbookSearchRequest request)
        {
            var query = _context.LookbookItems.AsQueryable();

            if (request?.BagID.HasValue == true)
            {
                query = query.Where(x => x.BagID == request.BagID);
            }

            if (request?.BeltID.HasValue == true)
            {
                query = query.Where(x => x.BeltID == request.BeltID);
            }

            if (request?.IsFeatured.HasValue == true)
            {
                query = query.Where(x => x.IsFeatured == request.IsFeatured.Value);
            }

            if (!string.IsNullOrWhiteSpace(request?.Tag))
            {
                query = query.Where(x => x.Tags != null && x.Tags.Contains(request.Tag));
            }

            if (!string.IsNullOrWhiteSpace(request?.Title))
            {
                query = query.Where(x => x.Title != null && x.Title.Contains(request.Title));
            }

            // New filters
            if (request?.Occasion.HasValue == true)
            {
                var occ = (CSBWebshopSeminarski.Core.Entities.OccasionType)request.Occasion.Value;
                query = query.Where(x => x.Occasion == occ);
            }

            if (request?.Style.HasValue == true)
            {
                var st = (CSBWebshopSeminarski.Core.Entities.StyleType)request.Style.Value;
                query = query.Where(x => x.Style == st);
            }

            if (request?.Season.HasValue == true)
            {
                var sn = (CSBWebshopSeminarski.Core.Entities.SeasonType)request.Season.Value;
                query = query.Where(x => x.Season == sn);
            }

            query = query.OrderBy(x => x.SortOrder).ThenByDescending(x => x.CreatedAt);

            var list = await query.ToListAsync();
            return _mapper.Map<List<LookbookItem>>(list);
        }

        public override async Task<LookbookItem> Insert(LookbookUpsertRequest request)
        {
            var entity = _mapper.Map<LookbookItems>(request);
            _context.Set<LookbookItems>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<LookbookItem>(entity);
        }

        public override async Task<LookbookItem> Update(int ID, LookbookUpsertRequest request)
        {
            var entity = await _context.LookbookItems.FindAsync(ID);
            _context.Set<LookbookItems>().Attach(entity);
            _context.Set<LookbookItems>().Update(entity);
            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<LookbookItem>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.LookbookItems.FindAsync(ID);
            if (entity == null)
            {
                return false;
            }

            _context.LookbookItems.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}