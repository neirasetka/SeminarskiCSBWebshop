using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class OutfitIdeasController : BaseCRUDController<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>
    {
        /// <summary>
        /// Override to allow anonymous viewing of outfit ideas (e.g. GET ?bagID=1 or ?beltID=1).
        /// </summary>
        [HttpGet]
        [AllowAnonymous]
        public override async Task<List<OutfitIdea>> Get([FromQuery] OutfitIdeaSearchRequest search)
        {
            return await _outfitIdeasService.Get(search);
        }
        private readonly IOutfitIdeasService _outfitIdeasService;

        public OutfitIdeasController(IOutfitIdeasService service) : base(service)
        {
            _outfitIdeasService = service;
        }

        [HttpGet("bag/{bagId}/user/{userId}")]
        public async Task<ActionResult<OutfitIdea>> GetByBagAndUser(int bagId, int userId)
        {
            var result = await _outfitIdeasService.GetByBagAndUser(bagId, userId);
            if (result == null)
            {
                return NotFound();
            }
            return Ok(result);
        }

        [HttpGet("belt/{beltId}/user/{userId}")]
        public async Task<ActionResult<OutfitIdea>> GetByBeltAndUser(int beltId, int userId)
        {
            var result = await _outfitIdeasService.GetByBeltAndUser(beltId, userId);
            if (result == null)
            {
                return NotFound();
            }
            return Ok(result);
        }

        [HttpPost("{outfitIdeaId}/images")]
        public async Task<ActionResult<OutfitIdeaImage>> AddImage(int outfitIdeaId, [FromBody] OutfitIdeaImageUpsertRequest request)
        {
            request.OutfitIdeaID = outfitIdeaId;
            var result = await _outfitIdeasService.AddImage(request);
            return Ok(result);
        }

        [HttpDelete("images/{imageId}")]
        public async Task<ActionResult> RemoveImage(int imageId)
        {
            var success = await _outfitIdeasService.RemoveImage(imageId);
            if (!success)
            {
                return NotFound();
            }
            return Ok();
        }

        [HttpGet("{outfitIdeaId}/images")]
        public async Task<ActionResult<List<OutfitIdeaImage>>> GetImages(int outfitIdeaId)
        {
            var result = await _outfitIdeasService.GetImages(outfitIdeaId);
            return Ok(result);
        }
    }
}
