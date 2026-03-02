using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class OutfitIdeasController : BaseCRUDController<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>
    {
        /// <summary>
        /// Override base Get to avoid model binding issues (rawValue/attemptedValue validation errors).
        /// Reads query params manually instead of [FromQuery] binding.
        /// </summary>
        [HttpGet]
        [AllowAnonymous]
        public override async Task<List<OutfitIdea>> Get([BindNever] OutfitIdeaSearchRequest search)
        {
            return await GetSearchInternalAsync();
        }

        /// <summary>
        /// Same as Get - allows /api/OutfitIdeas/search?beltID=1 for explicit search path.
        /// </summary>
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<List<OutfitIdea>> GetSearch()
        {
            return await GetSearchInternalAsync();
        }

        private async Task<List<OutfitIdea>> GetSearchInternalAsync()
        {
            var searchReq = new OutfitIdeaSearchRequest();

            if (int.TryParse(Request.Query["bagID"], out var bagId) && bagId > 0)
            {
                searchReq.BagID = bagId;
            }

            if (int.TryParse(Request.Query["beltID"], out var beltId) && beltId > 0)
            {
                searchReq.BeltID = beltId;
            }

            if (int.TryParse(Request.Query["userID"], out var userId) && userId > 0)
            {
                searchReq.UserID = userId;
            }

            if (Request.Query.TryGetValue("title", out var titleVal) && !string.IsNullOrWhiteSpace(titleVal))
            {
                searchReq.Title = titleVal;
            }

            try
            {
                return await _outfitIdeasService.Get(searchReq);
            }
            catch
            {
                // In case of any unexpected server-side error, return an empty list instead of 500
                // so the client can gracefully show "no outfit ideas" instead of an exception.
                return new List<OutfitIdea>();
            }
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
