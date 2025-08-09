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

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<CocoSunBagsWebshopDbContext>(options =>
       options.UseSqlServer(builder.Configuration.GetConnectionString("CocoSunBagsWebshop")));
builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>());
builder.Services.AddAutoMapper(typeof(Program).Assembly);
builder.Services.AddMvc();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "CocoSunBagsWebshop API", Version = "v1" });
    c.AddSecurityDefinition("basic", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header
    });
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
       },
       {
           new OpenApiSecurityScheme
           {
               Reference=new OpenApiReference
               {
                   Type=ReferenceType.SecurityScheme,
                   Id="basic"
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
builder.Services.AddTransient<ICRUDService<OrderItem, OrderItemSearchRequest, OrderItemUpsertRequest, OrderItemUpsertRequest>, OrderItemsService>();
builder.Services.AddTransient<IRatesService, RatesService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();
// Participants service registration
builder.Services.AddTransient<IParticipantsService, ParticipantsService>();
// Shipping tracking service
builder.Services.AddTransient<IShipmentTrackingService, ShipmentTrackingService>();
// JWT token generator
builder.Services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();
builder.Services.AddHostedService<ShippingStatusRefreshWorker>();

// Email service registration (values from configuration Smtp section)
builder.Services.AddSingleton(provider =>
    new EmailService(
        builder.Configuration["Smtp:Host"] ?? "",
        int.TryParse(builder.Configuration["Smtp:Port"], out var port) ? port : 587,
        builder.Configuration["Smtp:User"] ?? "",
        builder.Configuration["Smtp:Pass"] ?? ""
    )
);

// Authentication: default to JWT, keep Basic scheme available
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
})
.AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

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
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
