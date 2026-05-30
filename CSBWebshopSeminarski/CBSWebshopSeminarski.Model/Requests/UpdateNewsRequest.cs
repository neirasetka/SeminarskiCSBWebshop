using System.ComponentModel.DataAnnotations;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UpdateNewsRequest
    {
        [MinLength(2, ErrorMessage = "Title must be at least 2 characters long.")]
        [MaxLength(200, ErrorMessage = "Title can be up to 200 characters.")]
        public string? Title { get; set; }

        [MinLength(1, ErrorMessage = "Body cannot be empty when provided.")]
        [MaxLength(10_000, ErrorMessage = "Body can be up to 10000 characters.")]
        public string? Body { get; set; }
    }
}
