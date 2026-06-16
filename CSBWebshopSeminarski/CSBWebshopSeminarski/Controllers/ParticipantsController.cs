using CBSWebshopSeminarski.Model;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ParticipantsController : ControllerBase
    {
        private readonly EmailService _emailService;
        private readonly IGiveawaysService _giveawaysService;

        public ParticipantsController(
            EmailService emailService,
            IGiveawaysService giveawaysService)
        {
            _emailService = emailService;
            _giveawaysService = giveawaysService;
        }

        [HttpPost("winner")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> NotifyWinner([FromBody] Participants winner)
        {
            if (string.IsNullOrWhiteSpace(winner?.Email))
                throw new ValidationException(ValidationMessages.EmailRequired);

            await _emailService.SendEmailAsync(
                winner.Email,
                "Congratulations, You Are a Winner!",
                "You have won the giveaway!");
            return Ok();
        }

        [HttpPost("{giveawayId:int}/notify-winner")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> NotifyWinnerForGiveaway(int giveawayId)
        {
            var winner = await _giveawaysService.NotifyWinnerForGiveawayAsync(giveawayId);
            return Ok(new
            {
                message = "Uspješno obaviješten korisnik",
                winnerEmail = winner.Email
            });
        }
    }
}
