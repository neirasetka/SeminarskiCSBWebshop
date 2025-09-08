$ErrorActionPreference = 'Stop'

function Ensure-Flutter {
  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host 'Flutter CLI not found in PATH. Please install Flutter and restart the shell.' -ForegroundColor Red
    exit 1
  }
}

function Build-WindowsRelease {
  param(
    [string]$Flavor = 'prod',
    [string]$Main = 'lib/main.dart',
    [string]$ApiBaseUrl = 'http://localhost:5265',
    [string]$EnableLogging = 'false',
    [string]$StripeKey = ''
  )

  Ensure-Flutter
  Push-Location (Split-Path -Parent $MyInvocation.MyCommand.Path) | Out-Null
  Set-Location ..

  $defines = @(
    "--dart-define=FLAVOR=$Flavor",
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=ENABLE_LOGGING=$EnableLogging",
    "--dart-define=STRIPE_PUBLISHABLE_KEY=$StripeKey"
  ) -join ' '

  Write-Host "Running: flutter build windows --release --flavor $Flavor -t $Main $defines"
  flutter pub get
  flutter build windows --release --flavor $Flavor -t $Main $defines

  Write-Host "Build completed. Output at: build\\windows\\x64\\runner\\Release" -ForegroundColor Green
}

Build-WindowsRelease @PSBoundParameters

