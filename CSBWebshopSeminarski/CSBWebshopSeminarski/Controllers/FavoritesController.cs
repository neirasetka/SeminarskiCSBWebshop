using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
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
    }
}
