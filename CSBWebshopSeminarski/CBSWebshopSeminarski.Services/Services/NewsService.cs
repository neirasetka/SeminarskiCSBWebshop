using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Database;
using Microsoft.EntityFrameworkCore;

namespace CBSWebshopSeminarski.Services.Services
{
    public class NewsService : INewsService
    {
        private readonly CocoSunBagsWebshopDbContext _context;

        public NewsService(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<NewsItemDto>> GetAllAsync(int page, int pageSize, string? segment)
        {
            var search = new PagedSearchRequest { Page = page, PageSize = pageSize };
            var (normalizedPage, normalizedPageSize) = PaginationHelper.Normalize(search);

            var query = _context.News.AsNoTracking().OrderByDescending(n => n.PublishedAtUtc).AsQueryable();
            if (!string.IsNullOrWhiteSpace(segment))
            {
                query = query.Where(n => n.Segment == segment);
            }

            var totalCount = await query.CountAsync();
            var items = await query
                .Skip((normalizedPage - 1) * normalizedPageSize)
                .Take(normalizedPageSize)
                .Select(n => new NewsItemDto
                {
                    Id = n.Id,
                    PublishedAtUtc = n.PublishedAtUtc,
                    Title = n.Title,
                    Body = n.Body,
                    Segment = n.Segment,
                    LaunchDate = n.LaunchDate,
                    ProductName = n.ProductName,
                    Price = n.Price,
                    Color = n.Color
                })
                .ToListAsync();

            return new PagedResult<NewsItemDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = normalizedPage,
                PageSize = normalizedPageSize
            };
        }

        public async Task<NewsItemDto?> GetByIdAsync(int id)
        {
            var n = await _context.News.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
            if (n == null)
                return null;

            return MapToDto(n);
        }

        public async Task<NewsItemDto?> UpdateAsync(int id, UpdateNewsRequest request)
        {
            var entity = await _context.News.FindAsync(id);
            if (entity == null)
                return null;

            if (!string.IsNullOrWhiteSpace(request.Title))
                entity.Title = request.Title;
            if (!string.IsNullOrWhiteSpace(request.Body))
                entity.Body = request.Body;

            await _context.SaveChangesAsync();
            return MapToDto(entity);
        }

        public async Task CreateFromAnnouncementAsync(
            string subject,
            string body,
            AnnouncementRequest request,
            AnnouncementSegment segment,
            string? createdBy)
        {
            var item = new CSBWebshopSeminarski.Core.Entities.NewsItem
            {
                PublishedAtUtc = DateTime.UtcNow,
                Title = subject,
                Body = body,
                Segment = segment.ToString(),
                LaunchDate = request.LaunchDate,
                ProductName = request.ProductName,
                Price = request.Price,
                Color = request.Color,
                CreatedBy = createdBy
            };
            _context.News.Add(item);
            await _context.SaveChangesAsync();
        }

        private static NewsItemDto MapToDto(CSBWebshopSeminarski.Core.Entities.NewsItem n) =>
            new()
            {
                Id = n.Id,
                PublishedAtUtc = n.PublishedAtUtc,
                Title = n.Title,
                Body = n.Body,
                Segment = n.Segment,
                LaunchDate = n.LaunchDate,
                ProductName = n.ProductName,
                Price = n.Price,
                Color = n.Color
            };
    }
}
