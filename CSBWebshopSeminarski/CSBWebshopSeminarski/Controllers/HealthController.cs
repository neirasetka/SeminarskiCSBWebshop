using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        public HealthController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        ///Basic health check endpoint - returns only status for public consumption.
        [HttpGet]
        [AllowAnonymous]
        public IActionResult Get()
        {
            return Ok(new { status = "ok" });
        }

        ///Detailed health check with configuration info - Admin only.
        [HttpGet("detailed")]
        [Authorize(Roles = "Admin")]
        public IActionResult GetDetailed()
        {
            var rabbitHost = _configuration["RabbitMQ:HostName"] ?? "not-set";
            var rabbitExchange = _configuration["RabbitMQ:Exchange"] ?? "not-set";
            return Ok(new { status = "ok", rabbitHost, rabbitExchange });
        }
    }
}
