using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PasswordResetController : ControllerBase
    {
        private readonly CocoSunBagsWebshopDbContext _db;
        private readonly RabbitMqMailPublisher _mailPublisher;

        public PasswordResetController(CocoSunBagsWebshopDbContext db, RabbitMqMailPublisher mailPublisher)
        {
            _db = db;
            _mailPublisher = mailPublisher;
        }

        [HttpPost("request")]
        public async Task<ActionResult> RequestReset([FromBody] RequestPasswordResetRequest request)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
            {
                return Ok(new { message = "Ako email postoji, link za reset je poslan." });
            }

            var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
            var entity = new PasswordResetTokens
            {
                UserID = user.UserID,
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                Used = false
            };
            _db.PasswordResetTokens.Add(entity);
            await _db.SaveChangesAsync();

            try
            {
                _mailPublisher.Publish(
                    sender: "no-reply@cocosunbags.local",
                    recipient: user.Email,
                    subject: "Reset lozinke - CocoSunBags",
                    content: $"Poštovani/a {user.Name},\n\n" +
                             $"Vaš kod za reset lozinke je: {token}\n\n" +
                             "Kod vrijedi 30 minuta.\n\n" +
                             "Ako niste zatražili reset, ignorirajte ovu poruku.\n\n" +
                             "CocoSunBags tim");
            }
            catch
            {
            }

            return Ok(new { message = "Ako email postoji, link za reset je poslan." });
        }

        [HttpPost("reset")]
        public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (request.NewPassword != request.ConfirmPassword)
            {
                return BadRequest("Lozinke se ne podudaraju.");
            }

            var tokenEntity = await _db.PasswordResetTokens
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Token == request.Token && !t.Used && t.ExpiresAt > DateTime.UtcNow);

            if (tokenEntity == null)
            {
                return BadRequest("Token je nevažeći ili je istekao.");
            }

            var user = tokenEntity.User;
            user.PasswordSalt = UsersService.GenerateSalt();
            user.PasswordHash = UsersService.GenerateHash(user.PasswordSalt, request.NewPassword);

            tokenEntity.Used = true;
            await _db.SaveChangesAsync();

            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }
    }
}
