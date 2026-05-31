using System.Text.Json;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Exceptions;
using CBSWebshopSeminarski.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.EntityFrameworkCore;

namespace CSBWebshopSeminarski.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OutfitIdeasController : BaseCRUDController<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>
    {
        /// <summary>
        /// Override base Get to avoid model binding issues (rawValue/attemptedValue validation errors).
        /// Reads query params manually instead of [FromQuery] binding.
        /// </summary>
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<OutfitIdea>> Get([BindNever] OutfitIdeaSearchRequest search)
        {
            return await GetSearchInternalAsync();
        }

        /// <summary>
        /// Same as Get - allows /api/OutfitIdeas/search?beltID=1 for explicit search path.
        /// </summary>
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<PagedResult<OutfitIdea>> GetSearch()
        {
            return await GetSearchInternalAsync();
        }

        private async Task<PagedResult<OutfitIdea>> GetSearchInternalAsync()
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

            if (int.TryParse(Request.Query["page"], out var page) && page > 0)
            {
                searchReq.Page = page;
            }

            if (int.TryParse(Request.Query["pageSize"], out var pageSize) && pageSize > 0)
            {
                searchReq.PageSize = pageSize;
            }

            try
            {
                return await _outfitIdeasService.Get(searchReq);
            }
            catch
            {
                return new PagedResult<OutfitIdea>();
            }
        }
        private readonly IOutfitIdeasService _outfitIdeasService;

        public OutfitIdeasController(IOutfitIdeasService service) : base(service)
        {
            _outfitIdeasService = service;
        }

        [HttpGet("{ID:int}")]
        [AllowAnonymous]
        public override async Task<OutfitIdea> GetById(int ID)
        {
            return await base.GetById(ID);
        }

        /// <summary>
        /// Override Insert to avoid model binding issues (rawValue/attemptedValue validation errors).
        /// Reads request body manually and deserializes, like GetSearchInternalAsync for query params.
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<OutfitIdea> Insert([BindNever] OutfitIdeaUpsertRequest _)
        {
            Request.EnableBuffering();
            Request.Body.Position = 0;
            using var reader = new StreamReader(Request.Body, leaveOpen: true);
            var body = await reader.ReadToEndAsync();
            Request.Body.Position = 0;
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            OutfitIdeaUpsertRequest? request;
            try
            {
                request = JsonSerializer.Deserialize<OutfitIdeaUpsertRequest>(body, options);
            }
            catch (JsonException ex)
            {
                throw new ValidationException($"Neispravan JSON u zahtjevu: {ex.Message}");
            }
            if (request == null || string.IsNullOrWhiteSpace(body))
            {
                throw new ValidationException("Request body is required.");
            }
            if (!request.BagID.HasValue && !request.BeltID.HasValue)
            {
                throw new ValidationException("Either BagID or BeltID must be set.");
            }
            if (request.BagID.HasValue && request.BeltID.HasValue)
            {
                throw new ValidationException("Only one of BagID or BeltID should be set.");
            }
            if (request.UserID < 1)
            {
                throw new ValidationException("UserID must be a valid positive integer.");
            }
            if (string.IsNullOrWhiteSpace(request.Title) || request.Title.Length < 2)
            {
                request.Title = "Outfit inspiracija";
            }

            try
            {
                return await _outfitIdeasService.Insert(request);
            }
            catch (DbUpdateException ex)
            {
                var inner = ex.InnerException?.Message ?? ex.Message;
                if (inner.Contains("FK_") || inner.Contains("foreign key"))
                    throw new NotFoundException("Greška pri kreiranju outfit ideje: referencirani kaiš ili korisnik ne postoji u bazi.");
                if (inner.Contains("duplicate") || inner.Contains("unique"))
                    throw new ConflictException("Greška pri kreiranju outfit ideje: outfit ideja za ovaj kaiš i korisnika već postoji.");
                throw;
            }
        }

        [HttpGet("bag/{bagId}/user/{userId}")]
        [AllowAnonymous]
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
        [AllowAnonymous]
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
            {
                return NotFound();
            }
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
