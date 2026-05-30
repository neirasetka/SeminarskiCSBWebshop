using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GiveawaysController : ControllerBase
    {
        private readonly IGiveawaysService _giveawaysService;
        private readonly ILogger<GiveawaysController> _logger;

        public GiveawaysController(IGiveawaysService giveawaysService, ILogger<GiveawaysController> logger)
        {
            _giveawaysService = giveawaysService;
            _logger = logger;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetAll([FromQuery] GiveawaySearchRequest search)
        {
            return Ok(await _giveawaysService.GetAllAsync(search));
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] CreateGiveawayRequest request)
        {
            var created = await _giveawaysService.CreateGiveawayAsync(request.Title, request.StartDate, request.EndDate);
            return Ok(MapGiveaway(created));
        }

        [HttpGet("{id:int}")]
        [AllowAnonymous]
        public async Task<IActionResult> Get(int id)
        {
            var giveaway = await _giveawaysService.GetByIdAsync(id);
            if (giveaway == null)
                return NotFound();

            return Ok(giveaway);
        }

        [HttpPatch("{id:int}/duration")]
        [HttpPut("{id:int}/duration")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateDuration(int id, [FromBody] UpdateGiveawayDurationRequest request)
        {
            var updated = await _giveawaysService.UpdateGiveawayDurationAsync(id, request.StartDate, request.EndDate);
            return Ok(MapGiveaway(updated));
        }

        [HttpGet("{id:int}/participants")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetParticipants(int id, [FromQuery] PagedSearchRequest search)
        {
            return Ok(await _giveawaysService.GetParticipantsAsync(id, search));
        }

        [HttpPost("{id:int}/participants")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterParticipantOnGiveaway(int id, [FromBody] RegisterParticipantRequest request)
        {
            var created = await _giveawaysService.RegisterParticipantAsync(id, request.Name ?? string.Empty, request.Email);
            var dto = new ParticipantPublicDto
            {
                Id = created.Id,
                Name = created.Name,
                MaskedEmail = ObjectExtension.MaskEmail(created.Email ?? string.Empty),
                EntryDate = created.EntryDate,
                GiveawayId = created.GiveawayId
            };
            return Ok(dto);
        }

        [HttpPost("{id:int}/draw")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Draw(int id)
        {
            _logger.LogInformation("Giveaway draw triggered by {User} for giveaway {GiveawayId} at {UtcNow}", User?.Identity?.Name ?? "unknown", id, DateTime.UtcNow);
            var winner = await _giveawaysService.DrawAndPersistWinnerAsync(id);
            if (winner == null)
                return NotFound("No participants or giveaway closed without a winner");

            return Ok(new ParticipantDto
            {
                Id = winner.Id,
                Name = winner.Name,
                Email = winner.Email,
                EntryDate = winner.EntryDate,
                GiveawayId = winner.GiveawayId
            });
        }

        [HttpPost("{id:int}/announce-winner")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AnnounceWinner(int id)
        {
            _logger.LogInformation("Giveaway winner announcement triggered by {User} for giveaway {GiveawayId} at {UtcNow}", User?.Identity?.Name ?? "unknown", id, DateTime.UtcNow);

            var result = await _giveawaysService.AnnounceWinnerAsync(id, User?.Identity?.Name);

            if (!result.Success)
            {
                return BadRequest(new { error = result.ErrorMessage });
            }

            return Ok(new
            {
                message = "Winner announced successfully",
                winnerName = result.WinnerName,
                subscribersNotified = result.SubscribersNotified,
                newsItemId = result.NewsItemId
            });
        }

        private static GiveawayDto MapGiveaway(CSBWebshopSeminarski.Core.Entities.Giveaways g) =>
            new()
            {
                Id = g.Id,
                Title = g.Title,
                StartDate = g.StartDate,
                EndDate = g.EndDate,
                IsClosed = g.IsClosed,
                WinnerParticipantId = g.WinnerParticipantId
            };
    }
}
