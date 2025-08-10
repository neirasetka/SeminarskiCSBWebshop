using System;
using System.Linq;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GiveawaysController : ControllerBase
    {
        private readonly GiveawaysService _giveawaysService;
        private readonly CSBWebshopSeminarski.Database.CocoSunBagsWebshopDbContext _context;

        public GiveawaysController(GiveawaysService giveawaysService, CSBWebshopSeminarski.Database.CocoSunBagsWebshopDbContext context)
        {
            _giveawaysService = giveawaysService;
            _context = context;
        }

        public record CreateGiveawayRequest(string Title, DateTime StartDate, DateTime EndDate);

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateGiveawayRequest request)
        {
            var created = await _giveawaysService.CreateGiveawayAsync(request.Title, request.StartDate, request.EndDate);
            return Ok(created);
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> Get(int id)
        {
            var giveaway = await _context.Giveaways.FindAsync(id);
            if (giveaway == null) return NotFound();
            return Ok(giveaway);
        }

        [HttpGet("{id:int}/participants")]
        public IActionResult GetParticipants(int id)
        {
            var participants = _context.Participants.Where(p => p.GiveawayId == id).ToList();
            return Ok(participants);
        }
    }
}