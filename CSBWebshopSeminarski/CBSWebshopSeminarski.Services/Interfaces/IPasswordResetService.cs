using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface IPasswordResetService
    {
        Task RequestResetAsync(RequestPasswordResetRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
    }
}
