using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OutfitIdeasController : BaseCRUDController<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>
    {
        private readonly IOutfitIdeasService _outfitIdeasService;

        public OutfitIdeasController(IOutfitIdeasService service) : base(service)
        {
            _outfitIdeasService = service;
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<OutfitIdea>> Get([FromQuery] OutfitIdeaSearchRequest search)
        {
            return await _outfitIdeasService.Get(search ?? new OutfitIdeaSearchRequest());
        }

        [HttpGet("search")]
        [AllowAnonymous]
        public Task<PagedResult<OutfitIdea>> Search([FromQuery] OutfitIdeaSearchRequest search) =>
            Get(search);

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<OutfitIdea> GetById(int ID)
        {
            return await base.GetById(ID);
        }

        [HttpGet("bag/{bagId}/user/{userId}")]
        [AllowAnonymous]
        public async Task<ActionResult<OutfitIdea>> GetByBagAndUser(int bagId, int userId)
        {
            var result = await _outfitIdeasService.GetByBagAndUser(bagId, userId);
            if (result == null)
                throw new NotFoundException("Outfit idea not found.");
            return Ok(result);
        }

        [HttpGet("belt/{beltId}/user/{userId}")]
        [AllowAnonymous]
        public async Task<ActionResult<OutfitIdea>> GetByBeltAndUser(int beltId, int userId)
        {
            var result = await _outfitIdeasService.GetByBeltAndUser(beltId, userId);
            if (result == null)
                throw new NotFoundException("Outfit idea not found.");
            return Ok(result);
        }

        [HttpPost("{outfitIdeaId}/images")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<OutfitIdeaImage>> AddImage(int outfitIdeaId, [FromBody] OutfitIdeaImageUpsertRequest request)
        {
            request.OutfitIdeaID = outfitIdeaId;
            var result = await _outfitIdeasService.AddImage(request);
            return Ok(result);
        }

        [HttpDelete("images/{imageId}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> RemoveImage(int imageId)
        {
            var success = await _outfitIdeasService.RemoveImage(imageId);
            if (!success)
                throw new NotFoundException("Outfit idea image not found.");
            return Ok();
        }

        [HttpGet("{outfitIdeaId}/images")]
        [AllowAnonymous]
        public async Task<ActionResult<List<OutfitIdeaImage>>> GetImages(int outfitIdeaId)
        {
            var result = await _outfitIdeasService.GetImages(outfitIdeaId);
            return Ok(result);
        }
    }
}
