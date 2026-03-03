# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["CSBWebshopSeminarski/CSBWebshopSeminarski.csproj", "CSBWebshopSeminarski/"]
COPY ["CSBWebshopSeminarski.Core/CSBWebshopSeminarski.Core.csproj", "CSBWebshopSeminarski.Core/"]
COPY ["CSBWebshopSeminarski.Database/CSBWebshopSeminarski.Database.csproj", "CSBWebshopSeminarski.Database/"]
COPY ["CBSWebshopSeminarski.Model/CBSWebshopSeminarski.Model.csproj", "CBSWebshopSeminarski.Model/"]
COPY ["CBSWebshopSeminarski.Services/CBSWebshopSeminarski.Services.csproj", "CBSWebshopSeminarski.Services/"]
COPY ["CSBWebshopSeminarski.Notifications/CSBWebshopSeminarski.Notifications.csproj", "CSBWebshopSeminarski.Notifications/"]
RUN dotnet restore "./CSBWebshopSeminarski/CSBWebshopSeminarski.csproj"
COPY . .
WORKDIR "/src/CSBWebshopSeminarski"
RUN dotnet build "./CSBWebshopSeminarski.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./CSBWebshopSeminarski.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "CSBWebshopSeminarski.dll"]
