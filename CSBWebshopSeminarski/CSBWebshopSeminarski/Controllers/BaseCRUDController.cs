using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseReadController<T, TSearch>
        where TSearch : PagedSearchRequest
    {
        private readonly ICRUDService<T, TSearch, TInsert, TUpdate> _service;
        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public virtual async Task<T> Insert(TInsert request)
        {
            return await _service.Insert(request);
        }

        // {ID:int} da literalni segmenti poput "profile" ne idu u ovaj endpoint (inače binding pada s 400).
        [HttpPut("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<T> Update(int ID, TUpdate request)
        {
            return await _service.Update(ID, request);
        }

        [HttpDelete("{ID:int}")]
        [Authorize(Roles = "Admin")]
        public virtual async Task<bool> Delete(int ID)
        {
            return await _service.Delete(ID);
        }
    }
}
