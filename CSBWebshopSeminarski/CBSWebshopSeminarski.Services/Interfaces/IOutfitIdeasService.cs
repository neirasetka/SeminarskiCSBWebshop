using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IOutfitIdeasService : ICRUDService<OutfitIdea, OutfitIdeaSearchRequest, OutfitIdeaUpsertRequest, OutfitIdeaUpsertRequest>
    {
        Task<OutfitIdea?> GetByBagAndUser(int bagId, int userId);
        Task<OutfitIdea?> GetByBeltAndUser(int beltId, int userId);
        Task<OutfitIdeaImage> AddImage(OutfitIdeaImageUpsertRequest request);
        Task<bool> RemoveImage(int imageId);
        Task<List<OutfitIdeaImage>> GetImages(int outfitIdeaId);
    }
}
