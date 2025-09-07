using CBSWebshopSeminarski.Model.Models;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace CSBWebshopSeminarski.Security
{
    public interface IJwtTokenGenerator
    {
        string GenerateToken(User user);
        DateTime GetExpiration();
    }

    public class JwtTokenGenerator : IJwtTokenGenerator
    {
        private readonly IConfiguration _configuration;
        private DateTime _lastExpirationUtc;

        public JwtTokenGenerator(IConfiguration configuration)
        {
            _configuration = configuration;
            _lastExpirationUtc = DateTime.UtcNow;
        }

        public string GenerateToken(User user)
        {
            var jwtSettings = _configuration.GetSection("JWTSettings");
            var key = jwtSettings["Key"] ?? string.Empty;
            var issuer = jwtSettings["Issuer"] ?? string.Empty;
            var audience = jwtSettings["Audience"] ?? string.Empty;
            var durationMinutes = int.TryParse(jwtSettings["DurationInMinutes"], out var m) ? m : 60;

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new Claim(ClaimTypes.Name, user.UserName)
            };

            if (user.UserRole != null)
            {
                foreach (var role in user.UserRole)
                {
                    if (role?.Role?.RoleName != null)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, role.Role.RoleName));
                    }
                }
            }

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var expires = DateTime.UtcNow.AddMinutes(durationMinutes);
            _lastExpirationUtc = expires;

            var tokenDescriptor = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: expires,
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);
        }

        public DateTime GetExpiration()
        {
            return _lastExpirationUtc;
        }
    }
}
