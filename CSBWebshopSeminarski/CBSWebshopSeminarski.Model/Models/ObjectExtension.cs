using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Globalization;

namespace CBSWebshopSeminarski.Model.Models
{
    public static class ObjectExtension
    {
        private static Newtonsoft.Json.JsonSerializer jsonSerializerSettings;

        public static Newtonsoft.Json.JsonSerializer GetJsonSerializerSettings()
        {
            return jsonSerializerSettings;
        }

        static ObjectExtension()
        {
            Newtonsoft.Json.JsonSerializer jsonSerializer = GetJsonSerializerSettings(new Newtonsoft.Json.JsonSerializer());
            GetJsonSerializerSettings().PreserveReferencesHandling = PreserveReferencesHandling.None;
            GetJsonSerializerSettings().ReferenceLoopHandling = ReferenceLoopHandling.Ignore;
            GetJsonSerializerSettings().NullValueHandling = NullValueHandling.Ignore;
        }

        private static Newtonsoft.Json.JsonSerializer GetJsonSerializerSettings(Newtonsoft.Json.JsonSerializer jsonSerializer)
        {
            throw new NotImplementedException();
        }

        public static IDictionary<string, string> ToKeyValue(this object metaToken)
        {
            if (metaToken == null)
            {
                return null;
            }

            JToken? token = metaToken as JToken;
            if (token == null)
            {
                try
                {
                    return JObject.FromObject(metaToken, GetJsonSerializerSettings()).ToKeyValue();
                }
                catch (ArgumentException)
                {
                    var dict = new Dictionary<string, string>();
                    dict.Add("id", metaToken.ToString());
                    return dict;
                }
            }

            if (token.HasValues)
            {
                var contentData = new Dictionary<string, string>();
                foreach (var child in token.Children().ToList())
                {
                    var childContent = child.ToKeyValue();
                    if (childContent != null)
                    {
                        contentData = contentData.Concat(childContent)
                            .ToDictionary(k => k.Key, v => v.Value);
                    }
                }

                return contentData;
            }

            var jValue = token as JValue;
            if (jValue?.Value == null)
            {
                return null;
            }

            var value = jValue?.Type == JTokenType.Date ?
                jValue?.ToString("u", CultureInfo.InvariantCulture) :
                jValue?.ToString(CultureInfo.InvariantCulture);

            return new Dictionary<string, string> { { token.Path, value } };
        }

        public static async Task<string> ToQueryString(this object metaToken)
        {
            var keyValueContent = metaToken.ToKeyValue();
            var formUrlEncodedContent = new FormUrlEncodedContent(keyValueContent);
            var urlEncodedString = await formUrlEncodedContent.ReadAsStringAsync();

            return urlEncodedString;
        }

        public static async Task<string> WithQueryString(this string url, object metaToken)
        {
            if (metaToken != null)
            {
                url += await metaToken.ToQueryString();
            }
            return url;
        }

        public static string MaskEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return string.Empty;
            var parts = email.Split('@');
            if (parts.Length != 2) return email;
            var local = parts[0];
            var domain = parts[1];
            if (local.Length <= 2)
            {
                return local[0] + "***@" + domain;
            }
            var visible = local.Substring(0, 2);
            return visible + new string('*', Math.Max(1, local.Length - 2)) + "@" + domain;
        }
    }
}
