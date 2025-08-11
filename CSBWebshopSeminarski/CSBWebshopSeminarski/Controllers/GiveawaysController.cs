using System;
using System.Linq;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CBSWebshopSeminarski.Model.Requests;
using Microsoft.Extensions.Logging;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GiveawaysController : ControllerBase
    {
        private readonly GiveawaysService _giveawaysService;
        private readonly CSBWebshopSeminarski.Database.CocoSunBagsWebshopDbContext _context;
        private readonly ILogger<GiveawaysController> _logger;

        public GiveawaysController(GiveawaysService giveawaysService, CSBWebshopSeminarski.Database.CocoSunBagsWebshopDbContext context, ILogger<GiveawaysController> logger)
        {
            _giveawaysService = giveawaysService;
            _context = context;
            _logger = logger;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] CreateGiveawayRequest request)
        {
            var created = await _giveawaysService.CreateGiveawayAsync(request.Title, request.StartDate, request.EndDate);
            return Ok(created);
        }

        [HttpGet("{id:int}")]
        [AllowAnonymous]
        public async Task<IActionResult> Get(int id)
        {
            var giveaway = await _context.Giveaways.FindAsync(id);
            if (giveaway == null) return NotFound();
            return Ok(giveaway);
        }

        [HttpGet("{id:int}/participants")]
        [Authorize(Roles = "Admin")]
        public IActionResult GetParticipants(int id)
        {
            var participants = _context.Participants.Where(p => p.GiveawayId == id).ToList();
            return Ok(participants);
        }

        [HttpPost("{id:int}/participants")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterParticipantOnGiveaway(int id, [FromBody] RegisterParticipantRequest request)
        {
            var created = await _giveawaysService.RegisterParticipantAsync(id, request.Name, request.Email);
            return Ok(created);
        }

        [HttpPost("{id:int}/draw")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Draw(int id)
        {
            _logger.LogInformation("Giveaway draw triggered by {User} for giveaway {GiveawayId} at {UtcNow}", User?.Identity?.Name ?? "unknown", id, DateTime.UtcNow);
            var winner = await _giveawaysService.DrawAndPersistWinnerAsync(id);
            if (winner == null) return NotFound("No participants or giveaway closed without a winner");
            return Ok(winner);
        }
    }
}