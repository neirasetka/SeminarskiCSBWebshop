using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    [EnableRateLimiting("PasswordResetPolicy")]
    public class PasswordResetController : ControllerBase
    {
        private readonly IPasswordResetService _passwordResetService;

        public PasswordResetController(IPasswordResetService passwordResetService)
        {
            _passwordResetService = passwordResetService;
        }

        [HttpPost("request")]
        public async Task<ActionResult> RequestReset([FromBody] RequestPasswordResetRequest request)
        {
            await _passwordResetService.RequestResetAsync(request);
            return Ok(new { message = "Ako email postoji, link za reset je poslan." });
        }

        [HttpPost("reset")]
        public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _passwordResetService.ResetPasswordAsync(request);
            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }
    }
}
