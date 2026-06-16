using System.ComponentModel.DataAnnotations;
using CBSWebshopSeminarski.Model;

namespace CBSWebshopSeminarski.Model.Requests
{
    public class UpdateNewsRequest
    {
        [MinLength(2, ErrorMessage = ValidationMessages.TitleMinLength)]
        [MaxLength(200, ErrorMessage = ValidationMessages.TitleMaxLength)]
        public string? Title { get; set; }

        [MinLength(1, ErrorMessage = ValidationMessages.BodyMinLength)]
        [MaxLength(10_000, ErrorMessage = ValidationMessages.BodyMaxLength)]
        public string? Body { get; set; }
    }
}
