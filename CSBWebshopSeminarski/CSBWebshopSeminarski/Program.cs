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
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<CocoSunBagsWebshopDbContext>(options =>
       options.UseSqlServer(builder.Configuration.GetConnectionString("CocoSunBagsWebshop")));
builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>())
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
            ApiProblemDetailsFactory.ToResult(
                ApiProblemDetailsFactory.CreateValidation(context.ModelState, context.HttpContext));
    })
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
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

// Rate limiting policies
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

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

    options.AddPolicy("PasswordResetPolicy", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                Window = TimeSpan.FromMinutes(15),
                PermitLimit = 5,
                QueueLimit = 0,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst
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
builder.Services.AddTransient<IBaseService<Role, RoleSearchRequest>, RolesService>();
builder.Services.AddTransient<ICRUDService<Transaction, TransactionSearchRequest, TransactionUpsertRequest, TransactionUpsertRequest>, TransactionsService>();
builder.Services.AddTransient<ICRUDService<Favorite, FavoriteSearchRequest, FavoriteUpsertRequest, FavoriteUpsertRequest>, FavoritesService>();
builder.Services.AddTransient<IReviewsService, ReviewsService>();
builder.Services.AddTransient<ICRUDService<Purchase, PurchaseSearchRequest, PurchaseUpsertRequest, PurchaseUpsertRequest>, PurchasesService>();
builder.Services.AddTransient<IOrderService, OrdersService>();

builder.Services.AddSingleton<RabbitMqMailPublisher>();
builder.Services.AddTransient<ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>, OrderItemsService>();
builder.Services.AddTransient<IRatesService, RatesService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();
builder.Services.AddTransient<IParticipantsService, ParticipantsService>();
builder.Services.AddTransient<IGiveawaysService, GiveawaysService>();
builder.Services.AddTransient<INewsService, NewsService>();
builder.Services.AddTransient<INewsletterService, NewsletterService>();
builder.Services.AddTransient<NotificationsService>();
builder.Services.AddTransient<IInAppNotificationService, InAppNotificationService>();
builder.Services.AddSingleton<CBSWebshopSeminarski.Services.Interfaces.ITemplateRenderer, CBSWebshopSeminarski.Services.Services.TemplateRenderer>();
builder.Services.AddTransient<AnnouncementAuditService>();
builder.Services.AddTransient<IShipmentTrackingService, ShipmentTrackingService>();
builder.Services.AddTransient<IReportsService, ReportsService>();
builder.Services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
builder.Services.AddHostedService<ShippingStatusRefreshWorker>();

// Payments
builder.Services.AddTransient<IPaymentsService, PaymentsService>();
builder.Services.AddTransient<IStripeWebhookService, StripeWebhookService>();

// Email service registration
builder.Services.AddSingleton(provider =>
    new EmailService(
        builder.Configuration["Smtp:Host"] ?? "",
        int.TryParse(builder.Configuration["Smtp:Port"], out var port) ? port : 587,
        builder.Configuration["Smtp:User"] ?? "",
        builder.Configuration["Smtp:Pass"] ?? ""
    )
);

builder.Services.AddTransient<IPasswordResetService, PasswordResetService>();
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
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        RoleClaimType = System.Security.Claims.ClaimTypes.Role,
        NameClaimType = System.Security.Claims.ClaimTypes.Name
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
// Enable buffering so request body can be read multiple times (e.g. by OutfitIdeasController.Insert)
app.Use(async (context, next) =>
{
    context.Request.EnableBuffering();
    await next();
});
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

app.MapGet("/checkout-success", () => Results.Content(
    """
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"><title>Plaćanje uspješno</title></head>
    <body style="font-family:sans-serif;text-align:center;padding:40px;">
    <h1 style="color:green;">✓ Plaćanje uspješno!</h1>
    <p>Zatvorite ovaj prozor i vratite se u aplikaciju.</p>
    <p><small>CSB Webshop</small></p>
    </body>
    </html>
    """, "text/html"));

app.MapGet("/checkout-cancel", () => Results.Content(
    """
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"><title>Plaćanje otkazano</title></head>
    <body style="font-family:sans-serif;text-align:center;padding:40px;">
    <h1 style="color:orange;">Plaćanje otkazano</h1>
    <p>Zatvorite ovaj prozor i vratite se u aplikaciju.</p>
    <p><small>CSB Webshop</small></p>
    </body>
    </html>
    """, "text/html"));

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

        // Idempotent schema patches run before EF migrate so legacy DBs stay usable even when
        // MigrateAsync fails (e.g. pending model changes block new migrations).
        await context.Database.ExecuteSqlRawAsync(
            OrderItemsSchemaCompatibility.EnsureOrderItemsBagOrBeltColumnsNullableSql);

        await context.Database.ExecuteSqlRawAsync(
            OrdersSchemaCompatibility.EnsurePaymentConfirmationEmailSentColumnSql);

        await context.Database.ExecuteSqlRawAsync(
            OrdersSchemaCompatibility.EnsureStripePaymentRefColumnsSql);

        await context.Database.ExecuteSqlRawAsync(
            OrdersSchemaCompatibility.EnsureOrderCancellationColumnsSql);

        await context.Database.ExecuteSqlRawAsync(
            PurchasesSchemaCompatibility.EnsureUniquePurchaseOrderIdIndexSql);

        await context.Database.ExecuteSqlRawAsync(
            ProductBagBeltSchemaCompatibility.EnsureReviewsRatesFavoritesBagOrBeltXorSql);

        await context.Database.ExecuteSqlRawAsync(
            BusinessIdentifiersSchemaCompatibility.EnsureBusinessIdentifierUniqueIndexesSql);

        await context.Database.ExecuteSqlRawAsync(
            PasswordResetTokensSchemaCompatibility.EnsurePasswordResetTokensTableSql);

        await context.Database.ExecuteSqlRawAsync(
            NotificationsSchemaCompatibility.EnsureNotificationsTableSql);

        try
        {
            await context.Database.MigrateAsync();
        }
        catch (Exception migrateEx)
        {
            logger.LogWarning(migrateEx,
                "EF migrations could not be applied (pending model changes or migration conflict). " +
                "Idempotent schema patches above were still applied.");
        }

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
