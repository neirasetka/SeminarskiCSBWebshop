using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski.Database;
using CSBWebshopSeminarski.Filters;
using CSBWebshopSeminarski.Security;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using CSBWebshopSeminarski;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Stripe;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;
using Microsoft.Extensions.DependencyInjection;
using CSBWebshopSeminarski.Core.Entities;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<CocoSunBagsWebshopDbContext>(options =>
       options.UseSqlServer(builder.Configuration.GetConnectionString("CocoSunBagsWebshop")));
builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>());
builder.Services.AddAutoMapper(typeof(Program).Assembly);
builder.Services.AddMvc();
builder.Services.AddEndpointsApiExplorer();

// CORS: allow local dev from any origin (adjust in production)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());
});

// Rate limiting policy for announcements
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("AnnouncementsPolicy", httpContext =>
        RateLimitPartition.GetTokenBucketLimiter(
            partitionKey: httpContext.User?.Identity?.Name ?? httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            factory: _ => new TokenBucketRateLimiterOptions
            {
                TokenLimit = 5,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                ReplenishmentPeriod = TimeSpan.FromMinutes(1),
                TokensPerPeriod = 5,
                AutoReplenishment = true
            }
        ));
});

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "CocoSunBagsWebshop API", Version = "v1" });
    c.AddSecurityDefinition("bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
   {
       {
           new OpenApiSecurityScheme
           {
               Reference=new OpenApiReference
               {
                   Type=ReferenceType.SecurityScheme,
                   Id="bearer"
               }
           },
           new string[]{}
       }
   });
    //privremeno rjesenje
    c.ResolveConflictingActions(apiDescriptions => apiDescriptions.First());
});
builder.Services.AddTransient<ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>, BagTypesService>();
builder.Services.AddTransient<ICRUDService<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest>, BeltTypesService>();
builder.Services.AddTransient<IUsersService, UsersService>();
builder.Services.AddTransient<IBagsService, BagsService>();
builder.Services.AddTransient<IBeltsService, BeltsService>();
builder.Services.AddTransient<IBaseService<Role, object>, RolesService>();
// Correct registration for Transactions generic service
builder.Services.AddTransient<ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>, TransactionsService>();
builder.Services.AddTransient<ICRUDService<Favorite, FavoriteSearchRequest, FavoriteUpsertRequest, FavoriteUpsertRequest>, FavoritesService>();
builder.Services.AddTransient<IReviewsService, ReviewsService>();
builder.Services.AddTransient<ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>, PurchasesService>();
builder.Services.AddTransient<IOrderService, OrdersService>();

// RabbitMQ publisher for domain events
builder.Services.AddSingleton<CBSWebshopSeminarski.Services.Interfaces.IEventPublisher>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var host = configuration["RabbitMQ:HostName"] ?? "localhost";
    var exchange = configuration["RabbitMQ:Exchange"] ?? "webshop.events";
    return new CBSWebshopSeminarski.Services.Services.RabbitMqEventPublisher(host, exchange);
});
builder.Services.AddTransient<ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>, OrderItemsService>();
builder.Services.AddTransient<IRatesService, RatesService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();
// Participants service registration
builder.Services.AddTransient<IParticipantsService, ParticipantsService>();
// Giveaways service registration
builder.Services.AddTransient<GiveawaysService>();
// Notifications service registration
builder.Services.AddTransient<NotificationsService>();
// Announcements support services
builder.Services.AddSingleton<CBSWebshopSeminarski.Services.Interfaces.ITemplateRenderer, CBSWebshopSeminarski.Services.Services.TemplateRenderer>();
builder.Services.AddTransient<AnnouncementAuditService>();
// Shipping tracking service
builder.Services.AddTransient<IShipmentTrackingService, ShipmentTrackingService>();
// Reports service registration
builder.Services.AddTransient<IReportsService, ReportsService>();
        // JWT token generator
builder.Services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
builder.Services.AddHostedService<ShippingStatusRefreshWorker>();

// Payments
builder.Services.AddTransient<CBSWebshopSeminarski.Services.Interfaces.IPaymentsService, CBSWebshopSeminarski.Services.Services.PaymentsService>();

// Email service registration (values from configuration Smtp section)
builder.Services.AddSingleton(provider =>
    new EmailService(
        builder.Configuration["Smtp:Host"] ?? "",
        int.TryParse(builder.Configuration["Smtp:Port"], out var port) ? port : 587,
        builder.Configuration["Smtp:User"] ?? "",
        builder.Configuration["Smtp:Pass"] ?? ""
    )
);

// Register Lookbook service
builder.Services.AddTransient<ILookbookService, LookbookService>();

// Authentication: JWT only
var jwtKey = builder.Configuration["JWTSettings:Key"] ?? string.Empty;
var jwtIssuer = builder.Configuration["JWTSettings:Issuer"] ?? string.Empty;
var jwtAudience = builder.Configuration["JWTSettings:Audience"] ?? string.Empty;
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

// Stripe configuration
StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"] ?? string.Empty;

var app = builder.Build();
//// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "CocoSunBagsWebshop API");
    });
}

app.UseRouting();
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

// Stripe recommends verifying webhook signatures using the endpoint secret from configuration
var stripeWebhookSecret = builder.Configuration["Stripe:WebhookSecret"] ?? string.Empty;
app.MapPost("/api/webhooks/stripe", async (HttpRequest request, IServiceProvider sp, ILoggerFactory loggerFactory) =>
{
    var logger = loggerFactory.CreateLogger("StripeWebhook");
    var json = await new StreamReader(request.Body).ReadToEndAsync();
    try
    {
        var signatureHeader = request.Headers["Stripe-Signature"].ToString();
        var stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, stripeWebhookSecret);

        if (stripeEvent.Type == "payment_intent.succeeded")
        {
            var paymentIntent = (PaymentIntent)stripeEvent.Data.Object;
            var paymentsService = sp.GetRequiredService<CBSWebshopSeminarski.Services.Interfaces.IPaymentsService>();
            await paymentsService.HandlePaymentSucceededAsync(paymentIntent.Id, paymentIntent.Metadata);
        }
        else if (stripeEvent.Type == "payment_intent.payment_failed")
        {
            var paymentIntent = (PaymentIntent)stripeEvent.Data.Object;
            var paymentsService = sp.GetRequiredService<CBSWebshopSeminarski.Services.Interfaces.IPaymentsService>();
            await paymentsService.HandlePaymentFailedAsync(paymentIntent.Id, paymentIntent.Metadata, paymentIntent.LastPaymentError?.Message ?? "");
        }
        return Results.Ok();
    }
    catch (StripeException e)
    {
        logger.LogError(e, "Stripe webhook error: {Message}", e.Message);
        return Results.BadRequest();
    }
});

app.MapControllers();

// Seed roles and default admin user on startup
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<CocoSunBagsWebshopDbContext>();
        var config = services.GetRequiredService<IConfiguration>();

        // Apply migrations
        await context.Database.MigrateAsync();

        // Ensure roles
        var adminRole = await context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Admin");
        if (adminRole == null)
        {
            adminRole = new Roles { RoleName = "Admin" };
            await context.Roles.AddAsync(adminRole);
            await context.SaveChangesAsync();
        }
        var buyerRole = await context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Buyer");
        if (buyerRole == null)
        {
            buyerRole = new Roles { RoleName = "Buyer" };
            await context.Roles.AddAsync(buyerRole);
            await context.SaveChangesAsync();
        }

        // Ensure admin user
        var adminSeedSection = config.GetSection("AdminSeed");
        var adminUserName = adminSeedSection["UserName"] ?? "admin";
        var adminEmail = adminSeedSection["Email"] ?? "admin@example.com";
        var adminPassword = adminSeedSection["Password"] ?? "Admin123!";

        var adminUser = await context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Roles)
            .FirstOrDefaultAsync(u => u.UserName == adminUserName);

        if (adminUser == null)
        {
            var salt = UsersService.GenerateSalt();
            var hash = UsersService.GenerateHash(salt, adminPassword);
            adminUser = new Users
            {
                Name = "System",
                Surname = "Administrator",
                Email = adminEmail,
                Phone = "",
                UserName = adminUserName,
                PasswordSalt = salt,
                PasswordHash = hash,
                Image = Array.Empty<byte>()
            };
            await context.Users.AddAsync(adminUser);
            await context.SaveChangesAsync();
        }

        // Ensure Admin role assignment
        var hasAdminRole = await context.UserRoles.AnyAsync(ur => ur.UserID == adminUser.UserID && ur.RolesID == adminRole.RoleID);
        if (!hasAdminRole)
        {
            await context.UserRoles.AddAsync(new UserRoles
            {
                UserID = adminUser.UserID,
                RolesID = adminRole.RoleID
            });
            await context.SaveChangesAsync();
        }
    }
    catch (Exception seedingEx)
    {
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("StartupSeeding");
        logger.LogError(seedingEx, "Error during startup seeding");
    }
}

app.Run();
