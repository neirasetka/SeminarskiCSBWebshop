using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NewsletterController : ControllerBase
    {
        private readonly INewsletterService _newsletterService;

        public NewsletterController(INewsletterService newsletterService)
        {
            _newsletterService = newsletterService;
        }

        [HttpPost("subscribe")]
        [AllowAnonymous]
        public async Task<IActionResult> Subscribe([FromBody] NewsletterSubscriptionRequest request)
        {
            if (!ModelState.IsValid)
            {
                return ValidationProblem(ModelState);
            }

            var result = await _newsletterService.SubscribeAsync(request);
            return Ok(new
            {
                email = result.Email,
                isSubscribedToGiveaway = result.IsSubscribedToGiveaway,
                isSubscribedToNewCollections = result.IsSubscribedToNewCollections
            });
        }

        [HttpGet("subscription-status")]
        [AllowAnonymous]
        public async Task<IActionResult> GetSubscriptionStatus([FromQuery] string email)
        {
            var result = await _newsletterService.GetSubscriptionStatusAsync(email);
            return Ok(new
            {
                email = result.Email,
                isSubscribedToGiveaway = result.IsSubscribedToGiveaway,
                isSubscribedToNewCollections = result.IsSubscribedToNewCollections
            });
        }

        [HttpGet("subscribers")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetSubscribers()
        {
            var subscribers = await _newsletterService.GetSubscribersAsync();
            return Ok(subscribers.Select(s => new
            {
                id = s.Id,
                email = s.Email,
                isSubscribedToGiveaway = s.IsSubscribedToGiveaway,
                isSubscribedToNewCollections = s.IsSubscribedToNewCollections
            }));
        }
    }
}
