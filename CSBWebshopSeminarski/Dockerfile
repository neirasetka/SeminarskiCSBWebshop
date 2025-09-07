## Multi-stage Dockerfile for .NET 8 Web API
## Builds solution and publishes only API project

# Builder image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files first for better layer caching
COPY CSBWebshopSeminarski.sln ./
COPY CSBWebshopSeminarski/CSBWebshopSeminarski.csproj CSBWebshopSeminarski/CSBWebshopSeminarski.csproj
COPY CBSWebshopSeminarski.Model/CBSWebshopSeminarski.Model.csproj CBSWebshopSeminarski.Model/CBSWebshopSeminarski.Model.csproj
COPY CBSWebshopSeminarski.Services/CBSWebshopSeminarski.Services.csproj CBSWebshopSeminarski.Services/CBSWebshopSeminarski.Services.csproj
COPY CSBWebshopSeminarski.Core/CSBWebshopSeminarski.Core.csproj CSBWebshopSeminarski.Core/CSBWebshopSeminarski.Core.csproj
COPY CSBWebshopSeminarski.Database/CSBWebshopSeminarski.Database.csproj CSBWebshopSeminarski.Database/CSBWebshopSeminarski.Database.csproj

# Restore first
RUN dotnet restore CSBWebshopSeminarski/CSBWebshopSeminarski.csproj

# Copy the rest of the source
COPY . .

# Build and publish
RUN dotnet publish CSBWebshopSeminarski/CSBWebshopSeminarski.csproj -c Release -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# App listens on 8080 by default in container
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# Copy published output
COPY --from=build /app/publish .

# Healthcheck (simple root check; adjust if you add a dedicated endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD wget -qO- http://localhost:8080/ | grep -q "swagger" || exit 1

ENTRYPOINT ["dotnet", "CSBWebshopSeminarski.dll"]

