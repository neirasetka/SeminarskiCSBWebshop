using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavoritesController : BaseCRUDController<Favorite, FavoriteSearchRequest, FavoriteUpsertRequest, FavoriteUpsertRequest>
    {
        public FavoritesController(ICRUDService<Favorite, FavoriteSearchRequest, FavoriteUpsertRequest, FavoriteUpsertRequest> service) : base(service)
        {
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<Favorite>> Get([FromQuery] FavoriteSearchRequest search)
        {
            return await base.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public override async Task<Favorite> GetById(int ID)
        {
            return await base.GetById(ID);
        }
    }
}
