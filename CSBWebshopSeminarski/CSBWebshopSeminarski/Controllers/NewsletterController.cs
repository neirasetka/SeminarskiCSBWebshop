using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NewsletterController : ControllerBase
    {
        public class NewsletterSubscriptionRequest
        {
            [Required]
            [EmailAddress]
            public string Email { get; set; } = string.Empty;
            public bool? IsSubscribedToGiveaway { get; set; }
            public bool? IsSubscribedToNewCollections { get; set; }
        }

        private readonly CocoSunBagsWebshopDbContext _context;

        public NewsletterController(CocoSunBagsWebshopDbContext context)
        {
            _context = context;
        }

        ///Public endpoint for newsletter subscription.
        [HttpPost("subscribe")]
        [AllowAnonymous]
        public async Task<IActionResult> Subscribe([FromBody] NewsletterSubscriptionRequest request)
        {
            if (!ModelState.IsValid)
            {
                return ValidationProblem(ModelState);
            }

            var normalizedEmail = request.Email.Trim().ToLowerInvariant();
            var existing = await _context.Subscribers.FirstOrDefaultAsync(s => s.Email.ToLower() == normalizedEmail);

            if (existing == null)
            {
                existing = new Subscribers
                {
                    Email = normalizedEmail,
                    IsSubscribedToGiveaway = request.IsSubscribedToGiveaway ?? false,
                    IsSubscribedToNewCollections = request.IsSubscribedToNewCollections ?? false
                };
                _context.Subscribers.Add(existing);
            }
            else
            {
                if (request.IsSubscribedToGiveaway.HasValue)
                {
                    existing.IsSubscribedToGiveaway = request.IsSubscribedToGiveaway.Value;
                }
                if (request.IsSubscribedToNewCollections.HasValue)
                {
                    existing.IsSubscribedToNewCollections = request.IsSubscribedToNewCollections.Value;
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new
            {
                email = existing.Email,
                isSubscribedToGiveaway = existing.IsSubscribedToGiveaway,
                isSubscribedToNewCollections = existing.IsSubscribedToNewCollections
            });
        }

        [HttpGet("subscription-status")]
        [AllowAnonymous]
        public async Task<IActionResult> GetSubscriptionStatus([FromQuery] string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest(new { message = "Email je obavezan." });
            }

            var normalizedEmail = email.Trim().ToLowerInvariant();
            var subscriber = await _context.Subscribers.AsNoTracking().FirstOrDefaultAsync(s => s.Email.ToLower() == normalizedEmail);

            return Ok(new
            {
                email = normalizedEmail,
                isSubscribedToGiveaway = subscriber?.IsSubscribedToGiveaway ?? false,
                isSubscribedToNewCollections = subscriber?.IsSubscribedToNewCollections ?? false
            });
        }

        [HttpGet("subscribers")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetSubscribers()
        {
            var subscribers = await _context.Subscribers
                .AsNoTracking()
                .Where(s => s.IsSubscribedToNewCollections)
                .OrderBy(s => s.Email)
                .Select(s => new
                {
                    id = s.Id,
                    email = s.Email,
                    isSubscribedToGiveaway = s.IsSubscribedToGiveaway,
                    isSubscribedToNewCollections = s.IsSubscribedToNewCollections
                })
                .ToListAsync();

            return Ok(subscribers);
        }
    }
}
