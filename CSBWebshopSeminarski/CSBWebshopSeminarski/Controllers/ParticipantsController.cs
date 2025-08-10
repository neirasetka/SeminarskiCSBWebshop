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
        private readonly CBSWebshopSeminarski.Services.Services.GiveawaysService _giveawaysService;
        public ParticipantsController(CocoSunBagsWebshopDbContext context, IParticipantsService service, CBSWebshopSeminarski.Services.Services.EmailService emailService, CBSWebshopSeminarski.Services.Services.GiveawaysService giveawaysService)
        {
            _context = context;
            _service = service;
            _emailService = emailService;
            _giveawaysService = giveawaysService;
        }

        [HttpPost("participant")]
        public async Task<IActionResult> AddParticipant(Participants participant)
        {
            var created = await _service.AddAsync(participant);
            return Ok(created);
        }

        [HttpPost("{giveawayId:int}/participants")]
        public async Task<IActionResult> RegisterParticipant(int giveawayId, [FromBody] Participants participant)
        {
            var created = await _giveawaysService.RegisterParticipantAsync(giveawayId, participant.Name ?? string.Empty, participant.Email ?? string.Empty);
            return Ok(created);
        }

        [HttpGet]
        public async Task<Participants?> SelectRandomWinner()
        {
            return await _service.GetRandomWinnerAsync();
        }

        [HttpPost("{giveawayId:int}/draw")]
        public async Task<IActionResult> DrawWinner(int giveawayId)
        {
            var winner = await _giveawaysService.DrawAndPersistWinnerAsync(giveawayId);
            if (winner == null) return NotFound("No participants or giveaway closed without a winner");
            return Ok(winner);
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

        [HttpPost("{giveawayId:int}/notify-winner")]
        public async Task<IActionResult> NotifyWinnerForGiveaway(int giveawayId)
        {
            var giveaway = await _context.Giveaways.FindAsync(giveawayId);
            if (giveaway == null || !giveaway.WinnerParticipantId.HasValue) return NotFound("Winner not found for this giveaway");
            var winner = await _context.Participants.FindAsync(giveaway.WinnerParticipantId.Value);
            if (winner == null) return NotFound("Winner not found");
            await _giveawaysService.NotifyWinnerAsync(winner);
            return Ok();
        }
    }
}
