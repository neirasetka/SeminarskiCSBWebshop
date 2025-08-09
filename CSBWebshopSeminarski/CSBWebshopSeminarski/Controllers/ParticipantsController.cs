using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ParticipantsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IParticipantsService _service;
        private readonly CBSWebshopSeminarski.Services.Services.EmailService _emailService;
        public ParticipantsController(CocoSunBagsWebshopDbContext context, IParticipantsService service, CBSWebshopSeminarski.Services.Services.EmailService emailService)
        {
            _context = context;
            _service = service;
            _emailService = emailService;
        }

        [HttpPost("participant")]
        public async Task<IActionResult> AddParticipant(Participants participant)
        {
            var created = await _service.AddAsync(participant);
            return Ok(created);
        }

        [HttpGet]
        public async Task<Participants?> SelectRandomWinner()
        {
            return await _service.GetRandomWinnerAsync();
        }

        [HttpPost("winner")]
        public async Task<IActionResult> NotifyWinner([FromBody] Participants winner)
        {
            if (string.IsNullOrWhiteSpace(winner?.Email)) return BadRequest("Email is required");

            await _emailService.SendEmailAsync(
                winner.Email,
                "Congratulations, You Are a Winner!",
                "You have won the giveaway!"
            );
            return Ok();
        }
    }
}
