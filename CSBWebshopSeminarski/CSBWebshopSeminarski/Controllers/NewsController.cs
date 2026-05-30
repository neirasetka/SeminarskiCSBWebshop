using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class NewsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _context;

        public NewsController(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<NewsItemDto>>> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? segment = null)
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

            return Ok(new PagedResult<NewsItemDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = normalizedPage,
                PageSize = normalizedPageSize
            });
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<NewsItemDto>> GetById(int id)
        {
            var n = await _context.News.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
            if (n == null) return NotFound();

            return Ok(new NewsItemDto
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
            });
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<NewsItemDto>> Update(int id, [FromBody] UpdateNewsRequest request)
        {
            var entity = await _context.News.FindAsync(id);
            if (entity == null) return NotFound();

            if (!string.IsNullOrWhiteSpace(request.Title))
                entity.Title = request.Title;
            if (!string.IsNullOrWhiteSpace(request.Body))
                entity.Body = request.Body;

            await _context.SaveChangesAsync();

            return Ok(new NewsItemDto
            {
                Id = entity.Id,
                PublishedAtUtc = entity.PublishedAtUtc,
                Title = entity.Title,
                Body = entity.Body,
                Segment = entity.Segment,
                LaunchDate = entity.LaunchDate,
                ProductName = entity.ProductName,
                Price = entity.Price,
                Color = entity.Color
            });
        }
    }
}
