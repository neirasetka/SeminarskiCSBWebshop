using CBSWebshopSeminarski.Services.Interfaces;
using System.Text.RegularExpressions;

namespace CBSWebshopSeminarski.Services.Services
{
    public class TemplateRenderer : ITemplateRenderer
    {
        private static readonly Dictionary<string, string> BuiltInTemplates = new()
        {
            ["giveaway-default"] = "Hello,\n\nWe're excited to announce a new giveaway! {{message}}\n\nGood luck!",
            ["new-collection-default"] = "Hello,\n\nDiscover our new collection! {{message}}\n\nShop now!"
        };

        public string Render(string? templateKey, string? fallbackBodyTemplate, IDictionary<string, string>? variables)
        {
            string template = fallbackBodyTemplate ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(templateKey) && BuiltInTemplates.TryGetValue(templateKey!, out var found))
            {
                template = found;
            }

            if (variables == null || variables.Count == 0)
            {
                return template;
            }

            return ReplacePlaceholders(template, variables);
        }

        private static string ReplacePlaceholders(string template, IDictionary<string, string> variables)
        {
            return Regex.Replace(template, "\\{\\{(.*?)\\}\\}", match =>
            {
                var key = match.Groups[1].Value.Trim();
                if (variables.TryGetValue(key, out var value))
                {
                    return value ?? string.Empty;
                }
                return match.Value;
            });
        }
    }
}
