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

        [HttpGet]
        public IActionResult Get()
        {
            var rabbitHost = _configuration["RabbitMQ:HostName"] ?? "not-set";
            var rabbitExchange = _configuration["RabbitMQ:Exchange"] ?? "not-set";
            return Ok(new { status = "ok", rabbitHost, rabbitExchange });
        }
    }
}