using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface ILookbookService : ICRUDService<LookbookItem, LookbookSearchRequest, LookbookUpsertRequest, LookbookUpsertRequest>
    {
    }
}