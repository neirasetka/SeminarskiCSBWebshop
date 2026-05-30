using CBSWebshopSeminarski.Model.Models;
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
        public async Task<IActionResult> GetSubscribers([FromQuery] PagedSearchRequest search)
        {
            var result = await _newsletterService.GetSubscribersAsync(search);
            return Ok(new
            {
                items = result.Items.Select(s => new
                {
                    id = s.Id,
                    email = s.Email,
                    isSubscribedToGiveaway = s.IsSubscribedToGiveaway,
                    isSubscribedToNewCollections = s.IsSubscribedToNewCollections
                }),
                totalCount = result.TotalCount,
                page = result.Page,
                pageSize = result.PageSize
            });
        }
    }
}
