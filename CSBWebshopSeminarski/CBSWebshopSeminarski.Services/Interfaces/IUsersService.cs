using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IUsersService : ICRUDService<User, UserSearchRequest, UserUpsertRequest, UserUpsertRequest>
    {
        Task<User> Authenticate(UserAuthenticationRequest request);
        Task<User> Login(UserUpsertRequest request);
        Task<List<Bag>> GetLikedBags(int ID, BagSearchRequest request);
        Task<Bag> InsertLikedBags(int ID, int BagID);
        Task<Bag> DeleteLikedBags(int ID, int BagID);
        Task<List<Belt>> GetLikedBelts(int ID, BeltSearchRequest request);
        Task<Belt> InsertLikedBelts(int ID, int BeltID);
        Task<Belt> DeleteLikedBelts(int ID, int BeltID);
    }
}
