using CBSWebshopSeminarski.Model.Models;
using CBSWebshopSeminarski.Model.Requests;
using CBSWebshopSeminarski.Services.Interfaces;
using CBSWebshopSeminarski.Services.Services;
using CSBWebshopSeminarski;
using CSBWebshopSeminarski.Core.Entities;
using CSBWebshopSeminarski.Database;
using CSBWebshopSeminarski.Filters;
using CSBWebshopSeminarski.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Stripe;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<CocoSunBagsWebshopDbContext>(options =>
       options.UseSqlServer(builder.Configuration.GetConnectionString("CocoSunBagsWebshop")));
builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>())
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
    });
builder.Services.AddAutoMapper(typeof(Program).Assembly);
builder.Services.AddMvc();
builder.Services.AddEndpointsApiExplorer();
// Authorization policies and handlers
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanModifyReview", policy =>
        policy.Requirements.Add(new CanModifyReviewRequirement()));
    options.AddPolicy("CanModifyRate", policy =>
        policy.Requirements.Add(new CanModifyRateRequirement()));
});
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyReviewHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, CanModifyRateHandler>();

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
    c.ResolveConflictingActions(apiDescriptions => apiDescriptions.First());
});
builder.Services.AddTransient<ICRUDService<BagType, BagTypeSearchRequest, BagTypeUpsertRequest, BagTypeUpsertRequest>, BagTypesService>();
builder.Services.AddTransient<ICRUDService<BeltType, BeltTypeSearchRequest, BeltTypeUpsertRequest, BeltTypeUpsertRequest>, BeltTypesService>();
builder.Services.AddTransient<IUsersService, UsersService>();
builder.Services.AddTransient<IBagsService, BagsService>();
builder.Services.AddTransient<IBeltsService, BeltsService>();
builder.Services.AddTransient<IBaseService<Role, object>, RolesService>();
builder.Services.AddTransient<ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>, TransactionsService>();
builder.Services.AddTransient<ICRUDService<Favorite, FavoriteSearchRequest, FavoriteUpsertRequest, FavoriteUpsertRequest>, FavoritesService>();
builder.Services.AddTransient<IReviewsService, ReviewsService>();
builder.Services.AddTransient<ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>, PurchasesService>();
builder.Services.AddTransient<IOrderService, OrdersService>();

// RabbitMQ publisher for domain events (falls back to NoOp when RabbitMQ is unavailable)
builder.Services.AddSingleton<CBSWebshopSeminarski.Services.Interfaces.IEventPublisher>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var logger = sp.GetRequiredService<ILogger<Program>>();
    var host = configuration["RabbitMQ:HostName"] ?? "localhost";
    var exchange = configuration["RabbitMQ:Exchange"] ?? "webshop.events";
    try
    {
        return new CBSWebshopSeminarski.Services.Services.RabbitMqEventPublisher(host, exchange);
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "RabbitMQ unreachable at {Host}. Domain events will not be published. Start RabbitMQ to enable event publishing.", host);
        return new CBSWebshopSeminarski.Services.Services.NoOpEventPublisher();
    }
});
builder.Services.AddTransient<ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>, OrderItemsService>();
builder.Services.AddTransient<IRatesService, RatesService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();
builder.Services.AddTransient<IParticipantsService, ParticipantsService>();
builder.Services.AddTransient<GiveawaysService>();
builder.Services.AddTransient<NotificationsService>();
builder.Services.AddSingleton<CBSWebshopSeminarski.Services.Interfaces.ITemplateRenderer, CBSWebshopSeminarski.Services.Services.TemplateRenderer>();
builder.Services.AddTransient<AnnouncementAuditService>();
builder.Services.AddTransient<IShipmentTrackingService, ShipmentTrackingService>();
builder.Services.AddTransient<IReportsService, ReportsService>();
builder.Services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
builder.Services.AddHostedService<ShippingStatusRefreshWorker>();

// Payments
builder.Services.AddTransient<CBSWebshopSeminarski.Services.Interfaces.IPaymentsService, CBSWebshopSeminarski.Services.Services.PaymentsService>();

// Email service registration
builder.Services.AddSingleton(provider =>
    new EmailService(
        builder.Configuration["Smtp:Host"] ?? "",
        int.TryParse(builder.Configuration["Smtp:Port"], out var port) ? port : 587,
        builder.Configuration["Smtp:User"] ?? "",
        builder.Configuration["Smtp:Pass"] ?? ""
    )
);

builder.Services.AddTransient<ILookbookService, LookbookService>();
builder.Services.AddTransient<IOutfitIdeasService, OutfitIdeasService>();

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
app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

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
        var loggerFactory = services.GetRequiredService<ILoggerFactory>();
        var logger = loggerFactory.CreateLogger("StartupSeeding");

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

        // Run comprehensive data seeding covering all entities
        await DatabaseSeeder.SeedAllAsync(context, logger);
    }
    catch (Exception seedingEx)
    {
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("StartupSeeding");
        logger.LogError(seedingEx, "Error during startup seeding");
    }
}

app.Run();
