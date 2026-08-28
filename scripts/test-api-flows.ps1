# CSB Webshop — API flow skripta
# Pokriva glavne tokove iz TEST_CASES.md / docs/ApiTestCases.md (PR #127).
#
# Preduslov: API mora biti pokrenut (Docker: http://localhost:8080, lokalno: http://localhost:5265)
#
#   cd CSBWebshopSeminarski
#   docker compose up -d --build
#   .\scripts\test-api-flows.ps1
#   .\scripts\test-api-flows.ps1 -BaseUrl http://localhost:5265
#
# Seed nalozi: admin/Admin123!  buyer/Buyer123!

param(
    [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Continue"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0

function Get-Prop {
    param($obj, [string[]]$names)
    if ($null -eq $obj) { return $null }
    foreach ($n in $names) {
        $p = $obj.PSObject.Properties | Where-Object { $_.Name -ieq $n } | Select-Object -First 1
        if ($p) { return $p.Value }
    }
    return $null
}

function Write-Step([string]$name) {
    Write-Host ""
    Write-Host "=== $name ===" -ForegroundColor Cyan
}

function Assert-Ok {
    param(
        [string]$Id,
        [string]$Name,
        [scriptblock]$Action,
        [int[]]$ExpectedStatus = @(200, 201, 204)
    )
    try {
        $result = & $Action
        $status = $script:LastStatus
        if ($null -eq $status) { $status = 200 }
        if ($ExpectedStatus -contains [int]$status) {
            $script:Pass++
            Write-Host "  OK  $Id  $Name  (HTTP $status)" -ForegroundColor Green
            return $result
        }
        $script:Fail++
        Write-Host "  FAIL $Id  $Name  (HTTP $status, expected $($ExpectedStatus -join '/'))" -ForegroundColor Red
        return $null
    }
    catch {
        $status = 0
        $resp = $_.Exception.Response
        if ($resp) { $status = [int]$resp.StatusCode }
        $script:LastStatus = $status
        if ($ExpectedStatus -contains $status) {
            $script:Pass++
            Write-Host "  OK  $Id  $Name  (HTTP $status)" -ForegroundColor Green
            return $null
        }
        $script:Fail++
        $msg = $_.Exception.Message
        Write-Host "  FAIL $Id  $Name  ($msg)" -ForegroundColor Red
        return $null
    }
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null,
        [string]$Token = $null
    )
    $headers = @{ Accept = "application/json" }
    if ($Token) { $headers["Authorization"] = "Bearer $Token" }

    $params = @{
        Uri             = "$BaseUrl$Path"
        Method          = $Method
        Headers         = $headers
        ContentType     = "application/json"
        UseBasicParsing = $true
    }
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
    }

    $resp = Invoke-WebRequest @params
    $script:LastStatus = [int]$resp.StatusCode
    if ([string]::IsNullOrWhiteSpace($resp.Content)) { return $null }
    try { return $resp.Content | ConvertFrom-Json } catch { return $resp.Content }
}

Write-Host "CSB Webshop API flows" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl" -ForegroundColor Gray

# ---------------------------------------------------------------------------
Write-Step "Health"
Assert-Ok "TC-API-HEALTH-001" "GET /api/Health" {
    Invoke-Api GET "/api/Health"
} | Out-Null

# ---------------------------------------------------------------------------
Write-Step "Authentication"
$buyer = Assert-Ok "TC-API-AUTH-001" "Buyer login (Token)" {
    Invoke-Api POST "/api/Users/Token" @{ UserName = "buyer"; Password = "Buyer123!" }
}
$buyerToken = Get-Prop $buyer @("token", "Token")
$buyerUser = Get-Prop $buyer @("user", "User")
$buyerId = Get-Prop $buyerUser @("userID", "UserID", "id", "Id")

$admin = Assert-Ok "TC-API-AUTH-007" "Admin login (Token)" {
    Invoke-Api POST "/api/Users/Token" @{ UserName = "admin"; Password = "Admin123!" }
}
$adminToken = Get-Prop $admin @("token", "Token")

Assert-Ok "TC-API-AUTH-002" "Login with invalid password" {
    Invoke-Api POST "/api/Users/Token" @{ UserName = "buyer"; Password = "wrongpass" }
} -ExpectedStatus @(401) | Out-Null

if (-not $buyerToken) {
    Write-Host "  STOP: buyer token missing — API nije dostupan ili seed nalog ne radi." -ForegroundColor Red
    Write-Host "  Pokreni: cd CSBWebshopSeminarski; docker compose up --build" -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
Write-Step "Catalog — Bags"
$bags = Assert-Ok "TC-API-BAG-001" "GET /api/Bags" {
    Invoke-Api GET "/api/Bags?page=1&pageSize=10"
}
$bagItems = @(Get-Prop $bags @("items", "Items") | Where-Object { $_ })
$firstBag = $null
if ($bagItems.Count -gt 0) { $firstBag = $bagItems[0] }
$bagId = Get-Prop $firstBag @("bagID", "BagID", "id", "Id")

if ($bagId) {
    Assert-Ok "TC-API-BAG-008" "GET /api/Bags/$bagId" {
        Invoke-Api GET "/api/Bags/$bagId"
    } | Out-Null
    Assert-Ok "TC-API-BAG-AVG" "GET /api/Bags/$bagId/GetAverage" {
        Invoke-Api GET "/api/Bags/$bagId/GetAverage"
    } | Out-Null
}
else {
    $script:Skip++
    Write-Host "  SKIP TC-API-BAG-008  nema torbi u katalogu" -ForegroundColor Yellow
}

Assert-Ok "TC-API-BAG-009" "GET /api/Bags/99999" {
    Invoke-Api GET "/api/Bags/99999"
} -ExpectedStatus @(404) | Out-Null

Assert-Ok "TC-API-BAG-012" "POST /api/Bags without admin" {
    Invoke-Api POST "/api/Bags" @{ BagName = "X"; Code = "X"; Price = 1; BagTypeID = 1; UserID = 1 } $buyerToken
} -ExpectedStatus @(401, 403) | Out-Null

# ---------------------------------------------------------------------------
Write-Step "Catalog — Belts"
$belts = Assert-Ok "TC-API-BELT-001" "GET /api/Belts" {
    Invoke-Api GET "/api/Belts?page=1&pageSize=10"
}
$beltItems = @(Get-Prop $belts @("items", "Items") | Where-Object { $_ })
$firstBelt = $null
if ($beltItems.Count -gt 0) { $firstBelt = $beltItems[0] }
$beltId = Get-Prop $firstBelt @("beltID", "BeltID", "id", "Id")

if ($beltId) {
    Assert-Ok "TC-API-BELT-004" "GET /api/Belts/$beltId" {
        Invoke-Api GET "/api/Belts/$beltId"
    } | Out-Null
}

# ---------------------------------------------------------------------------
Write-Step "Lookbook"
Assert-Ok "TC-API-LOOK-001" "GET /api/Lookbook" {
    Invoke-Api GET "/api/Lookbook?page=1&pageSize=10"
} | Out-Null

# ---------------------------------------------------------------------------
Write-Step "Giveaways"
$giveaways = Assert-Ok "TC-API-GIVE-001" "GET /api/Giveaways" {
    Invoke-Api GET "/api/Giveaways?page=1&pageSize=10"
}
$giveItems = @(Get-Prop $giveaways @("items", "Items") | Where-Object { $_ })
if ($giveItems.Count -eq 0 -and $giveaways -is [System.Array]) { $giveItems = @($giveaways) }
$giveawayId = $null
if ($giveItems.Count -gt 0) {
    $giveawayId = Get-Prop $giveItems[0] @("id", "Id", "giveawayId", "GiveawayId")
}
if ($giveawayId) {
    Assert-Ok "TC-API-GIVE-002" "GET /api/Giveaways/$giveawayId" {
        Invoke-Api GET "/api/Giveaways/$giveawayId"
    } | Out-Null
}

# ---------------------------------------------------------------------------
Write-Step "Cart / Orders (RabbitMQ trigger on Create)"
$order = Assert-Ok "TC-API-ORD-001" "POST /api/Orders/Create" {
    Invoke-Api POST "/api/Orders/Create" @{ OrderNumber = ""; Date = [DateTime]::UtcNow.ToString("o") } $buyerToken
}
$orderId = Get-Prop $order @("orderID", "OrderID", "id", "Id")
$orderNumber = Get-Prop $order @("orderNumber", "OrderNumber")

if ($orderId -and $bagId) {
    Assert-Ok "TC-API-ORD-002" "POST /api/OrderItems/AddToCart" {
        Invoke-Api POST "/api/OrderItems/AddToCart" @{
            BagID    = [int]$bagId
            OrderID  = [int]$orderId
            Quantity = 1
        } $buyerToken
    } | Out-Null
}
elseif (-not $bagId) {
    $script:Skip++
    Write-Host "  SKIP TC-API-ORD-002  nema torbe za AddToCart" -ForegroundColor Yellow
}

Assert-Ok "TC-API-ORD-003" "GET /api/Orders/Active" {
    Invoke-Api GET "/api/Orders/Active" -Token $buyerToken
} -ExpectedStatus @(200, 204) | Out-Null

Assert-Ok "TC-API-ORD-004" "GET /api/Orders/My" {
    Invoke-Api GET "/api/Orders/My?page=1&pageSize=10" -Token $buyerToken
} | Out-Null

if ($orderId) {
    Assert-Ok "TC-API-ORD-005" "GET /api/Orders/$orderId (own order)" {
        Invoke-Api GET "/api/Orders/$orderId" -Token $buyerToken
    } | Out-Null
}

# ---------------------------------------------------------------------------
Write-Step "Favorites"
if ($bagId) {
    Assert-Ok "TC-API-FAV-001" "POST /api/Users/me/LikedBags/{id}" {
        Invoke-Api POST "/api/Users/me/LikedBags/$bagId" -Token $buyerToken
    } | Out-Null
    Assert-Ok "TC-API-FAV-002" "GET /api/Users/me/LikedBags" {
        Invoke-Api GET "/api/Users/me/LikedBags?page=1&pageSize=10" -Token $buyerToken
    } | Out-Null
}

# ---------------------------------------------------------------------------
Write-Step "Recommendations"
Assert-Ok "TC-API-REC-001" "GET /api/Recommendation/GetRecommendedBags" {
    Invoke-Api GET "/api/Recommendation/GetRecommendedBags?take=3" -Token $buyerToken
} | Out-Null
Assert-Ok "TC-API-REC-002" "GET /api/Recommendation/GetRecommendedBelts" {
    Invoke-Api GET "/api/Recommendation/GetRecommendedBelts?take=3" -Token $buyerToken
} | Out-Null

# ---------------------------------------------------------------------------
Write-Step "Profile / Newsletter / Notifications"
if ($buyerId) {
    Assert-Ok "TC-API-PROF-001" "GET /api/Users/$buyerId" {
        Invoke-Api GET "/api/Users/$buyerId" -Token $buyerToken
    } | Out-Null
}
Assert-Ok "TC-API-NEWS-001" "POST /api/Newsletter/subscribe" {
    Invoke-Api POST "/api/Newsletter/subscribe" @{
        Email                        = "flow-test@example.com"
        IsSubscribedToGiveaway       = $true
        IsSubscribedToNewCollections = $true
    }
} | Out-Null
Assert-Ok "TC-API-NOTIF-001" "GET /api/Notifications" {
    Invoke-Api GET "/api/Notifications?page=1&pageSize=10" -Token $buyerToken
} | Out-Null

# ---------------------------------------------------------------------------
Write-Step "Admin reports"
if ($adminToken) {
    Assert-Ok "TC-API-REP-001" "GET /api/Reports/SalesSummary" {
        Invoke-Api GET "/api/Reports/SalesSummary" -Token $adminToken
    } | Out-Null
    Assert-Ok "TC-API-REP-002" "GET /api/Reports/TopSellingBags" {
        Invoke-Api GET "/api/Reports/TopSellingBags" -Token $adminToken
    } | Out-Null
    Assert-Ok "TC-API-HEALTH-002" "GET /api/Health/detailed" {
        Invoke-Api GET "/api/Health/detailed" -Token $adminToken
    } | Out-Null
}
else {
    $script:Skip++
    Write-Host "  SKIP admin reports — admin token missing" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Rezultat ===" -ForegroundColor Cyan
Write-Host ("  Pass: {0}" -f $script:Pass) -ForegroundColor Green
Write-Host ("  Fail: {0}" -f $script:Fail) -ForegroundColor $(if ($script:Fail -gt 0) { "Red" } else { "Gray" })
Write-Host ("  Skip: {0}" -f $script:Skip) -ForegroundColor Yellow
if ($orderNumber) {
    Write-Host ""
    Write-Host "RabbitMQ: ako Notifications worker radi, trebao bi logovati OrderCreatedEvent: $orderNumber" -ForegroundColor Gray
    Write-Host "Management UI: http://localhost:15672" -ForegroundColor Gray
}
if ($script:Fail -gt 0) { exit 1 }
exit 0
