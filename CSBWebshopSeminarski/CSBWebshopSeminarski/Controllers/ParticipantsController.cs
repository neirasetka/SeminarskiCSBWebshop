using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using MailKit.Security;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MimeKit;
using MimeKit.Text;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ParticipantsController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _context;
        private readonly IParticipantsService _service;
        public ParticipantsController(IParticipantsService service)
        {
            _service = service;
        }

        [HttpPost("participant")]
        public async Task<IActionResult> AddParticipant(Participants participant)
        {
            _context.Participants.Add(participant);
            await _context.SaveChangesAsync();
            return Ok(participant);
        }

        [HttpGet]
        public async Task<Giveaways> SelectRandomWinner(int giveawayId)
        {
            var participants = await _context.Giveaways.Where(p => p.Id == giveawayId).ToListAsync();
            if (participants.Count == 0) return null;

            var random = new Random();
            int index = random.Next(participants.Count);
            return participants[index];
        }

        [HttpPost("winner")]
        public async Task NotifyWinner(Participants winner)
        {
            var email = new MimeMessage();
            email.From.Add(MailboxAddress.Parse("no-reply@yourshop.com"));
            email.To.Add(MailboxAddress.Parse(winner.Email));
            email.Subject = "Congratulations, You Are a Winner!";
            email.Body = new TextPart(TextFormat.Plain) { Text = "You have won the giveaway!" };

            using var smtp = new MailKit.Net.Smtp.SmtpClient();
            await smtp.ConnectAsync("smtp.your-email.com", 587, SecureSocketOptions.StartTls);
            await smtp.AuthenticateAsync("your-email", "your-password");
            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);
        }
    }
}
