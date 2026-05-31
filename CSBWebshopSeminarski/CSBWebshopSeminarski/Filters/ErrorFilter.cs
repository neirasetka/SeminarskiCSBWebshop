using CBSWebshopSeminarski.Services.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace CSBWebshopSeminarski.Filters
{
    public class ErrorFilter : ExceptionFilterAttribute
    {
        public override void OnException(ExceptionContext context)
        {
            var statusCode = context.Exception switch
            {
                NotFoundException => StatusCodes.Status404NotFound,
                ValidationException => StatusCodes.Status400BadRequest,
                ForbiddenException => StatusCodes.Status403Forbidden,
                ConflictException => StatusCodes.Status409Conflict,
                BusinessException => StatusCodes.Status400BadRequest,
                _ => StatusCodes.Status500InternalServerError
            };

            var includeExceptionDetails = context.HttpContext.RequestServices
                .GetRequiredService<IHostEnvironment>()
                .IsDevelopment();

            var problemDetails = ApiProblemDetailsFactory.Create(
                context.Exception,
                statusCode,
                context.HttpContext,
                includeExceptionDetails);

            context.Result = ApiProblemDetailsFactory.ToResult(problemDetails);
            context.ExceptionHandled = true;
        }
    }
}
