using System.Security.Claims;
using CBSWebshopSeminarski.Model.Models;
using Microsoft.AspNetCore.Authorization;

namespace CSBWebshopSeminarski.Security
{
    public class CanModifyReviewRequirement : IAuthorizationRequirement { }

    public class CanModifyReviewHandler : AuthorizationHandler<CanModifyReviewRequirement, Review>
    {
        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, CanModifyReviewRequirement requirement, Review resource)
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

