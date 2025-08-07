using AutoMapper;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
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
            var entity = _mapper.Map<Review>(request);
            _context.Set<Review>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<Review>(entity);
        }
        public async Task<Review> Update(int ID, ReviewUpsertRequest request)
        {
            var entity = _context.Set<Review>().Find(ID);
            _context.Set<Review>().Attach(entity);
            _context.Set<Review>().Update(entity);

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
    }
}
