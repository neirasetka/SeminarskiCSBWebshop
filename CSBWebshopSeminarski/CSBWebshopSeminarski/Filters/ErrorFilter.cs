using System.Collections.Generic;
using CSBWebshopSeminarski.Exceptions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Hosting;
using System.Net;

namespace CSBWebshopSeminarski.Filters
{
    public class ErrorFilter : ExceptionFilterAttribute
    {
        public override void OnException(ExceptionContext context)
        {
            var env = context.HttpContext.RequestServices.GetService<IWebHostEnvironment>();
            var isDev = env?.IsDevelopment() ?? false;
            string message;

            if (context.Exception is UserException)
            {
                message = context.Exception.Message;
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else
            {
                message = isDev
                    ? $"{context.Exception.GetType().Name}: {context.Exception.Message}"
                    : "Error on the server";
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            // Return simple object instead of ModelState to avoid rawValue/attemptedValue noise
            var result = new Dictionary<string, string> { ["error"] = message };
            context.Result = new JsonResult(result);
        }
    }
}
