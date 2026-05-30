using System.Security.Claims;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CSBWebshopSeminarski.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : BaseCRUDController<User, UserSearchRequest, UserUpsertRequest, UserUpsertRequest>
    {
        private readonly IUsersService _service;
        private readonly IJwtTokenGenerator _tokenGenerator;
        public UsersController(IUsersService service, IJwtTokenGenerator tokenGenerator) : base(service)
        {
            _service = service;
            _tokenGenerator = tokenGenerator;
        }

        [HttpPost("Authenticate")]
        [AllowAnonymous]
        public async Task<ActionResult<User>> Authenticate(UserAuthenticationRequest request)
        {
            var user = await _service.Authenticate(request);
            return user == null ? Unauthorized() : user;
        }

        [HttpPost("Register")]
        [AllowAnonymous]
        public async Task<User> Register(RegisterRequest request)
        {
            return await _service.Register(request);
        }

        public class TokenResponse
        {
            public string Token { get; set; } = string.Empty;
            public DateTime ExpiresUtc { get; set; }
            public User User { get; set; } = null!;
        }

        [HttpPut("profile")]
        [Authorize]
        public async Task<ActionResult<User>> UpdateMyProfile([FromBody] UserProfileUpdateRequest request)
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var userId))
            {
                return Unauthorized();
            }

            try
            {
                return await _service.UpdateMyProfile(userId, request);
            }
            catch (ArgumentException)
            {
                return NotFound();
            }
        }

        [HttpPost("Token")]
        [AllowAnonymous]
        public async Task<ActionResult<TokenResponse>> Token([FromBody] UserAuthenticationRequest request)
        {
            var user = await _service.Authenticate(request);
            if (user == null)
            {
                return Unauthorized();
            }

            var token = _tokenGenerator.GenerateToken(user);
            var response = new TokenResponse
            {
                Token = token,
                ExpiresUtc = _tokenGenerator.GetExpiration(),
                User = user
            };
            return Ok(response);
        }

        private int GetCurrentUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var id) ? id : 0;
        }

        [HttpGet("me/LikedBags")]
        [Authorize]
        public async Task<PagedResult<Bag>> GetMyLikedBags([FromQuery] BagSearchRequest request)
        {
            return await _service.GetLikedBags(GetCurrentUserId(), request);
        }

        [HttpPost("me/LikedBags/{BagID}")]
        [Authorize]
        public async Task<Bag> InsertMyLikedBags(int BagID)
        {
            return await _service.InsertLikedBags(GetCurrentUserId(), BagID);
        }

        [HttpDelete("me/LikedBags/{BagID}")]
        [Authorize]
        public async Task<Bag> DeleteMyLikedBags(int BagID)
        {
            return await _service.DeleteLikedBags(GetCurrentUserId(), BagID);
        }

        [HttpGet("me/LikedBelts")]
        [Authorize]
        public async Task<PagedResult<Belt>> GetMyLikedBelts([FromQuery] BeltSearchRequest request)
        {
            return await _service.GetLikedBelts(GetCurrentUserId(), request);
        }

        [HttpPost("me/LikedBelts/{BeltID}")]
        [Authorize]
        public async Task<Belt> InsertMyLikedBelts(int BeltID)
        {
            return await _service.InsertLikedBelts(GetCurrentUserId(), BeltID);
        }

        [HttpDelete("me/LikedBelts/{BeltID}")]
        [Authorize]
        public async Task<Belt> DeleteMyLikedBelts(int BeltID)
        {
            return await _service.DeleteLikedBelts(GetCurrentUserId(), BeltID);
        }
    }
}
