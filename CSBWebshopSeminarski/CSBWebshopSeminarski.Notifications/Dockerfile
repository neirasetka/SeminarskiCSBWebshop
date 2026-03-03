FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CSBWebshopSeminarski.Notifications/CSBWebshopSeminarski.Notifications.csproj", "CSBWebshopSeminarski.Notifications/"]
COPY ["CBSWebshopSeminarski.Model/CBSWebshopSeminarski.Model.csproj", "CBSWebshopSeminarski.Model/"]
COPY ["CSBWebshopSeminarski.Core/CSBWebshopSeminarski.Core.csproj", "CSBWebshopSeminarski.Core/"]
COPY ["CSBWebshopSeminarski.Database/CSBWebshopSeminarski.Database.csproj", "CSBWebshopSeminarski.Database/"]
COPY ["CBSWebshopSeminarski.Services/CBSWebshopSeminarski.Services.csproj", "CBSWebshopSeminarski.Services/"]
RUN dotnet restore "CSBWebshopSeminarski.Notifications/CSBWebshopSeminarski.Notifications.csproj"

COPY . .
WORKDIR "/src/CSBWebshopSeminarski.Notifications"
RUN dotnet build "CSBWebshopSeminarski.Notifications.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CSBWebshopSeminarski.Notifications.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CSBWebshopSeminarski.Notifications.dll"]
