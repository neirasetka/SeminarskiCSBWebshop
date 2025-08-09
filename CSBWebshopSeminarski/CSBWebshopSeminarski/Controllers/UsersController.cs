using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : BaseCRUDController<User, UserSearchRequest, UserUpsertRequest, UserUpsertRequest>
    {
        private readonly IUsersService _service;
        public UsersController(IUsersService service) : base(service)
        {
            _service = service;
        }

        [HttpPost("Authenticate")]
        public async Task<User> Authenticate(UserAuthenticationRequest request)
        {
            return await _service.Authenticate(request);
        }

        [HttpPost("Login")]
        public async Task<User> Login(UserAuthenticationRequest request)
        {
            return await _service.Authenticate(request);
        }

        [HttpPost("Register")]
        public async Task<User> Register(UserUpsertRequest request)
        {
            return await _service.Insert(request);
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
