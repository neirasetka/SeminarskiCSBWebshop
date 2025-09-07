using System.Security.Claims;
using CBSWebshopSeminarski.Model.Models;
using Microsoft.AspNetCore.Authorization;

namespace CSBWebshopSeminarski.Security
{
    public class CanModifyRateRequirement : IAuthorizationRequirement { }

    public class CanModifyRateHandler : AuthorizationHandler<CanModifyRateRequirement, Rate>
    {
        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, CanModifyRateRequirement requirement, Rate resource)
        {
            if (resource == null)
            {
                return Task.CompletedTask;
            }

            if (context.User.IsInRole("Admin"))
            {
                context.Succeed(requirement);
                return Task.CompletedTask;
            }

            var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId) && resource.UserID == userId)
            {
                context.Succeed(requirement);
            }

            return Task.CompletedTask;
        }
    }
}

