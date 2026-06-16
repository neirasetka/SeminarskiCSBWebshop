using CBSWebshopSeminarski.Services.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace CSBWebshopSeminarski.Filters
{
    internal static class ApiProblemDetailsFactory
    {
        private const string ProblemTypeBase = "/api/problems";

        public static ProblemDetails Create(
            Exception exception,
            int statusCode,
            HttpContext httpContext,
            bool includeExceptionDetails)
        {
            var (errorCode, title) = MapException(exception, statusCode);

            var detail = statusCode == StatusCodes.Status500InternalServerError && !includeExceptionDetails
                ? "An unexpected error occurred."
                : exception.Message;

            if (exception is ValidationException validationException
                && validationException.Errors is { Count: > 0 } errors)
            {
                return new ValidationProblemDetails(errors)
                {
                    Type = $"{ProblemTypeBase}/validation_error",
                    Title = "Validation failed",
                    Status = statusCode,
                    Detail = detail,
                    Instance = httpContext.Request.Path,
                    Extensions =
                    {
                        ["errorCode"] = "validation_error"
                    }
                };
            }

            var problem = new ProblemDetails
            {
                Type = $"{ProblemTypeBase}/{errorCode}",
                Title = title,
                Status = statusCode,
                Detail = detail,
                Instance = httpContext.Request.Path
            };

            problem.Extensions["errorCode"] = errorCode;
            return problem;
        }

        public static ValidationProblemDetails CreateValidation(ModelStateDictionary modelState, HttpContext httpContext)
        {
            var problem = new ValidationProblemDetails(modelState)
            {
                Type = $"{ProblemTypeBase}/validation_error",
                Title = "Validation failed",
                Status = StatusCodes.Status400BadRequest,
                Detail = "One or more validation errors occurred.",
                Instance = httpContext.Request.Path
            };

            problem.Extensions["errorCode"] = "validation_error";
            return problem;
        }

        public static ObjectResult ToResult(ProblemDetails problemDetails)
        {
            return new ObjectResult(problemDetails)
            {
                StatusCode = problemDetails.Status,
                DeclaredType = typeof(ProblemDetails),
                ContentTypes = { "application/problem+json", "application/json" }
            };
        }

        private static (string ErrorCode, string Title) MapException(Exception exception, int statusCode) =>
            exception switch
            {
                NotFoundException => ("not_found", "Nije pronađeno"),
                ValidationException => ("validation_error", "Validation failed"),
                ForbiddenException => ("forbidden", "Access denied"),
                ConflictException => ("conflict", "Conflict"),
                BusinessException => ("business_rule_violation", "Business rule violation"),
                _ when statusCode == StatusCodes.Status500InternalServerError => ("internal_error", "Internal server error"),
                _ => ("error", "Request failed")
            };
    }
}
