using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class NewsController : ControllerBase
    {
        private readonly INewsService _newsService;

        public NewsController(INewsService newsService)
        {
            _newsService = newsService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<NewsItemDto>>> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? segment = null)
        {
            return Ok(await _newsService.GetAllAsync(page, pageSize, segment));
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<NewsItemDto>> GetById(int id)
        {
            var item = await _newsService.GetByIdAsync(id);
            if (item == null)
                throw new NotFoundException("News item not found.");

            return Ok(item);
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<NewsItemDto>> Update(int id, [FromBody] UpdateNewsRequest request)
        {
            var item = await _newsService.UpdateAsync(id, request);
            if (item == null)
                throw new NotFoundException("News item not found.");

            return Ok(item);
        }
    }
}
