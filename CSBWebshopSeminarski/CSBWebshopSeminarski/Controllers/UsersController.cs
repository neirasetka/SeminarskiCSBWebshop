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
        public async Task<User> Authenticate(UserAuthenticationRequest request)
        {
            return await _service.Authenticate(request);
        }

        [HttpPost("Login")]
        [AllowAnonymous]
        public async Task<User> Login(UserAuthenticationRequest request)
        {
            return await _service.Authenticate(request);
        }

        [HttpPost("Register")]
        [AllowAnonymous]
        public async Task<User> Register(UserUpsertRequest request)
        {
            return await _service.Insert(request);
        }

        public class TokenResponse
        {
            public string Token { get; set; } = string.Empty;
            public DateTime ExpiresUtc { get; set; }
            public User User { get; set; }
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

        [HttpGet("{ID}/LikedBags")]
        [Authorize]
        public async Task<List<Bag>> GetLikedBags(int ID, [FromQuery] BagSearchRequest request)
        {
            return await _service.GetLikedBags(ID, request);
        }

        [HttpPost("{ID}/LikedBags/{BagID}")]
        [Authorize]
        public async Task<Bag> InsertLikedBags(int ID, int BagID)
        {
            return await _service.InsertLikedBags(ID, BagID);
        }

        [HttpDelete("{ID}/LikedBags/{BagID}")]
        [Authorize]
        public async Task<Bag> DeleteLikedBags(int ID, int BagID)
        {
            return await _service.DeleteLikedBags(ID, BagID);
        }

        [HttpGet("{ID}/LikedBelts")]
        [Authorize]
        public async Task<List<Belt>> GetLikedBelts(int ID, [FromQuery] BeltSearchRequest request)
        {
            return await _service.GetLikedBelts(ID, request);
        }

        [HttpPost("{ID}/LikedBelts/{BeltID}")]
        [Authorize]
        public async Task<Belt> InsertLikedBelts(int ID, int BeltID)
        {
            return await _service.InsertLikedBelts(ID, BeltID);
        }

        [HttpDelete("{ID}/LikedBelts/{BeltID}")]
        [Authorize]
        public async Task<Belt> DeleteLikedBelts(int ID, int BeltID)
        {
            return await _service.DeleteLikedBelts(ID, BeltID);
        }
    }
}
