using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

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
    }
}
