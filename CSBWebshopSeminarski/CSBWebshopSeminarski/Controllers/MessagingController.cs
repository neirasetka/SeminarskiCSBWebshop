using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MessagingController : ControllerBase
    {
        private readonly IRabbitMqPublisher _publisher;

        public MessagingController(IRabbitMqPublisher publisher)
        {
            _publisher = publisher;
        }

        [HttpPost("publish")]
        [Authorize] // require JWT like the rest of the API
        public async Task<IActionResult> Publish([FromBody] PublishMessageRequest request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Message))
            {
                return BadRequest("Message cannot be empty");
            }

            await _publisher.PublishAsync(request.Message, request.RoutingKey, cancellationToken);
            return Accepted();
        }
    }
}