using CBSWebshopSeminarski.Services.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace CSBWebshopSeminarski.Filters
{
    public class ErrorFilter : ExceptionFilterAttribute
    {
        public override void OnException(ExceptionContext context)
        {
            var (statusCode, message) = context.Exception switch
            {
                NotFoundException ex => (StatusCodes.Status404NotFound, ex.Message),
                ValidationException ex => (StatusCodes.Status400BadRequest, ex.Message),
                ForbiddenException ex => (StatusCodes.Status403Forbidden, ex.Message),
                ConflictException ex => (StatusCodes.Status409Conflict, ex.Message),
                BusinessException ex => (StatusCodes.Status400BadRequest, ex.Message),
                _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.")
            };

            context.Result = new ObjectResult(new { error = message }) { StatusCode = statusCode };
            context.ExceptionHandled = true;
        }
    }
}
