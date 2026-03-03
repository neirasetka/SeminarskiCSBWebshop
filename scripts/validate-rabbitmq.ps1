# Validacija RabbitMQ integracije
# Preduslov: RabbitMQ, API i Notifications servis moraju biti pokrenuti
#
# Korak 1: docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
# Korak 2: dotnet run --project CSBWebshopSeminarski\CSBWebshopSeminarski.csproj
# Korak 3: dotnet run --project CSBWebshopSeminarski.Notifications\CSBWebshopSeminarski.Notifications.csproj
#
# Zatim pokreni ovaj script: .\scripts\validate-rabbitmq.ps1

$BaseUrl = "http://localhost:5265"
$LoginBody = @{ UserName = "buyer"; Password = "Buyer123!" } | ConvertTo-Json
$OrderBody = @{
    OrderNumber = ""
    Date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    Price = 9.99
    UserID = 2
    items = @()
} | ConvertTo-Json

Write-Host "=== Validacija RabbitMQ ===" -ForegroundColor Cyan
Write-Host "1. Dobivanje JWT tokena..." -ForegroundColor Yellow

try {
    $loginResp = Invoke-RestMethod -Uri "$BaseUrl/api/Users/Token" `
        -Method Post -ContentType "application/json" -Body $LoginBody
    $token = $loginResp.Token
    $userId = $loginResp.User.UserID
    Write-Host "   OK - UserID: $userId" -ForegroundColor Green
} catch {
    Write-Host "   GREŠKA: API nije dostupan ili lozinka nije ispravna." -ForegroundColor Red
    Write-Host "   Proveri da li API radi na $BaseUrl i da buyer/Buyer123! postoji." -ForegroundColor Red
    exit 1
}

# Koristi UserID iz odgovora umjesto hardcodiranog
$OrderBody = @{
    OrderNumber = ""
    Date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    Price = 9.99
    UserID = $userId
    items = @()
} | ConvertTo-Json

Write-Host "2. Kreiranje narudžbe (trigger za RabbitMQ event)..." -ForegroundColor Yellow

try {
    $headers = @{ Authorization = "Bearer $token" }
    $orderResp = Invoke-RestMethod -Uri "$BaseUrl/api/Orders/Create" `
        -Method Post -ContentType "application/json" -Headers $headers -Body $OrderBody
    Write-Host "   OK - OrderNumber: $($orderResp.OrderNumber)" -ForegroundColor Green
} catch {
    Write-Host "   GREŠKA: Kreiranje narudžbe nije uspjelo." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== API dio uspješan ===" -ForegroundColor Green
Write-Host "Ako RabbitMQ i Notifications servis rade, u konzoli Notifications trebalo bi da vidiš:"
Write-Host "  Received OrderCreatedEvent: $($orderResp.OrderNumber)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proveri RabbitMQ Management: http://localhost:15672 (guest/guest)" -ForegroundColor Gray
