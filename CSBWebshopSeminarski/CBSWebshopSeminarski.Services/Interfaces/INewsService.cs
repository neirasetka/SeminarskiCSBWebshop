using CBSWebshopSeminarski.Model.DTOs;
using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;

namespace CBSWebshopSeminarski.Services.Interfaces
{
    public interface INewsService
    {
        Task<PagedResult<NewsItemDto>> GetAllAsync(int page, int pageSize, string? segment);
        Task<NewsItemDto?> GetByIdAsync(int id);
        Task<NewsItemDto?> UpdateAsync(int id, UpdateNewsRequest request);
        Task CreateFromAnnouncementAsync(
            string subject,
            string body,
            AnnouncementRequest request,
            AnnouncementSegment segment,
            string? createdBy);
    }
}
