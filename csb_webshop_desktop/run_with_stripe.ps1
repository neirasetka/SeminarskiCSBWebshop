# Pokretanje Flutter desktop app sa Stripe publishable kljucem.
# Koristenje:
#   .\run_with_stripe.ps1
#   .\run_with_stripe.ps1 -StripeKey "pk_test_vas_kljuc"
#
param(
    [string]$StripeKey = $env:STRIPE_PUBLISHABLE_KEY
)

if ([string]::IsNullOrWhiteSpace($StripeKey)) {
    Write-Host "Greska: STRIPE_PUBLISHABLE_KEY nije postavljen." -ForegroundColor Red
    Write-Host "Postavite ga kao varijablu okruzenja ili proslijedite parametrom:" -ForegroundColor Yellow
    Write-Host "  `$env:STRIPE_PUBLISHABLE_KEY='pk_test_...'; .\run_with_stripe.ps1" -ForegroundColor Cyan
    Write-Host "  .\run_with_stripe.ps1 -StripeKey 'pk_test_...'" -ForegroundColor Cyan
    exit 1
}

Write-Host "Pokretanje sa Stripe kljucem..." -ForegroundColor Green
flutter run -d windows --dart-define=STRIPE_PUBLISHABLE_KEY=$StripeKey
