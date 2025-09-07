using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class ReviewsService : IReviewsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IMapper _mapper;
        public ReviewsService(CocoSunBagsWebshopDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }
        public async Task<List<Review>> Get(ReviewSearchRequest search)
        {
            var query = _context.Reviews.AsQueryable();

            if (search.UserID != 0)
            {
                query = query.Where(i => i.UserID == search.UserID);
            }

            if (search.BagID != 0)
            {
                query = query.Where(i => i.BagID == search.BagID);
            }

            if (search.BeltID != 0)
            {
                query = query.Where(i => i.BeltID == search.BeltID);
            }

            if (!string.IsNullOrWhiteSpace(search.Comment))
            {
                query = query.Where(i => i.Comment.Contains(search.Comment));
            }

            if (search.Date != default)
            {
                query = query.Where(i => i.Date.Date == search.Date.Date);
            }

            if (search.Status.HasValue)
            {
                query = query.Where(i => i.Status == (CSBWebshopSeminarski.Core.Entities.ReviewStatus)search.Status.Value);
            }
            else
            {
                // Default to showing only approved reviews when status is not specified
                query = query.Where(i => i.Status == CSBWebshopSeminarski.Core.Entities.ReviewStatus.Approved);
            }

            var list = await query.ToListAsync();
            return _mapper.Map<List<Review>>(list);
        }
        public async Task<Review> GetById(int ID)
        {
            var entity = await _context.Reviews
                .Include(i => i.User)
                .Where(i => i.ReviewID == ID)
                .SingleOrDefaultAsync();

            return _mapper.Map<Review>(entity);
        }
        public async Task<Review> Insert(ReviewUpsertRequest request)
        {
            var entity = _mapper.Map<Reviews>(request);
            if (entity.Date == default)
            {
                entity.Date = DateTime.UtcNow;
            }
            entity.Status = CSBWebshopSeminarski.Core.Entities.ReviewStatus.Pending;
            _context.Set<Reviews>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Review>(entity);
        }
        public async Task<Review> Update(int ID, ReviewUpsertRequest request)
        {
            var entity = _context.Set<Reviews>().Find(ID);
            _context.Set<Reviews>().Attach(entity);
            _context.Set<Reviews>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<Review>(entity);
        }
        public async Task<bool> Delete(int ID)
        {
            var comment = await _context.Reviews.Where(i => i.ReviewID == ID).FirstOrDefaultAsync();
            if (comment != null)
            {
                _context.Reviews.Remove(comment);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<Review> ApproveAsync(int id)
        {
            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.ReviewID == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Review {id} not found");
            }
            entity.Status = CSBWebshopSeminarski.Core.Entities.ReviewStatus.Approved;
            await _context.SaveChangesAsync();
            return _mapper.Map<Review>(entity);
        }

        public async Task<Review> RejectAsync(int id, string? reason = null)
        {
            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.ReviewID == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Review {id} not found");
            }
            entity.Status = CSBWebshopSeminarski.Core.Entities.ReviewStatus.Rejected;
            await _context.SaveChangesAsync();
            return _mapper.Map<Review>(entity);
        }

        public async Task<Review> SetPendingAsync(int id)
        {
            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.ReviewID == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Review {id} not found");
            }
            entity.Status = CSBWebshopSeminarski.Core.Entities.ReviewStatus.Pending;
            await _context.SaveChangesAsync();
            return _mapper.Map<Review>(entity);
        }
    }
}
