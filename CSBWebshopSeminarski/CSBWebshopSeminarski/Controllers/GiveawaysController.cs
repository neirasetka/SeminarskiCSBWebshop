using System;
using System.Linq;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CBSWebshopSeminarski.Model.Requests;
using Microsoft.Extensions.Logging;
using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;

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

        [HttpGet]
        [AllowAnonymous]
        public IActionResult GetAll([FromQuery] string? status)
        {
            var now = DateTime.UtcNow;
            var query = _context.Giveaways.AsQueryable();

            if (!string.IsNullOrWhiteSpace(status))
            {
                switch (status.Trim().ToLowerInvariant())
                {
                    case "active":
                        query = query.Where(g => !g.IsClosed && g.StartDate <= now && g.EndDate >= now);
                        break;
                    case "closed":
                        query = query.Where(g => g.IsClosed || g.EndDate < now);
                        break;
                    case "all":
                        break;
                    default:
                        return BadRequest("Invalid status. Use one of: active, closed, all");
                }
            }

            var dto = query
                .OrderByDescending(g => g.StartDate)
                .Select(g => new GiveawayDto
                {
                    Id = g.Id,
                    Title = g.Title,
                    StartDate = g.StartDate,
                    EndDate = g.EndDate,
                    IsClosed = g.IsClosed,
                    WinnerParticipantId = g.WinnerParticipantId
                })
                .ToList();

            return Ok(dto);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] CreateGiveawayRequest request)
        {
            var created = await _giveawaysService.CreateGiveawayAsync(request.Title, request.StartDate, request.EndDate);
            var dto = new GiveawayDto
            {
                Id = created.Id,
                Title = created.Title,
                StartDate = created.StartDate,
                EndDate = created.EndDate,
                IsClosed = created.IsClosed,
                WinnerParticipantId = created.WinnerParticipantId
            };
            return Ok(dto);
        }

        [HttpGet("{id:int}")]
        [AllowAnonymous]
        public async Task<IActionResult> Get(int id)
        {
            var giveaway = await _context.Giveaways.FindAsync(id);
            if (giveaway == null) return NotFound();
            var dto = new GiveawayDto
            {
                Id = giveaway.Id,
                Title = giveaway.Title,
                StartDate = giveaway.StartDate,
                EndDate = giveaway.EndDate,
                IsClosed = giveaway.IsClosed,
                WinnerParticipantId = giveaway.WinnerParticipantId
            };
            return Ok(dto);
        }

        [HttpGet("{id:int}/participants")]
        [Authorize(Roles = "Admin")]
        public IActionResult GetParticipants(int id)
        {
            var participants = _context.Participants.Where(p => p.GiveawayId == id).ToList();
            var dto = participants.Select(p => new ParticipantDto
            {
                Id = p.Id,
                Name = p.Name,
                Email = p.Email,
                EntryDate = p.EntryDate,
                GiveawayId = p.GiveawayId
            }).ToList();
            return Ok(dto);
        }

        [HttpPost("{id:int}/participants")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterParticipantOnGiveaway(int id, [FromBody] RegisterParticipantRequest request)
        {
            var created = await _giveawaysService.RegisterParticipantAsync(id, request.Name, request.Email);
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
            if (winner == null) return NotFound("No participants or giveaway closed without a winner");
            var dto = new ParticipantDto
            {
                Id = winner.Id,
                Name = winner.Name,
                Email = winner.Email,
                EntryDate = winner.EntryDate,
                GiveawayId = winner.GiveawayId
            };
            return Ok(dto);
        }
    }
}