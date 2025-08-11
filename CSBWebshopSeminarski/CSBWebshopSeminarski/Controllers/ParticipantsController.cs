using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using CBSWebshopSeminarski.Model.Requests;

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

        [HttpPost("{giveawayId:int}/participants")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterParticipant(int giveawayId, [FromBody] RegisterParticipantRequest request)
        {
            var created = await _giveawaysService.RegisterParticipantAsync(giveawayId, request.Name, request.Email);
            return Ok(created);
        }

        [HttpPost("winner")]
        [Authorize(Roles = "Admin")]
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
        [Authorize(Roles = "Admin")]
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
