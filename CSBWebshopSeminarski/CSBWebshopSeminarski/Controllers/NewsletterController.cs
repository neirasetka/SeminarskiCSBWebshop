using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NewsletterController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _context;

        public NewsletterController(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        ///Public endpoint for newsletter subscription.
        [HttpPost("subscribe")]
        [AllowAnonymous]
        public async Task<IActionResult> Subscribe([FromBody] Subscribers subscriber)
        {
            _context.Subscribers.Add(subscriber);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}
