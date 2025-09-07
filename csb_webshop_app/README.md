# csb_webshop_app

Flutter klijent za CSB Webshop.

## Flutter SDK setup

Instalacija: pogledati zvaničnu dokumentaciju: https://docs.flutter.dev/get-started/install

## Install dependencies and run (this project)

```bash
cd csb_webshop_app
flutter pub get
flutter run
```

## Flavors and Environment Config

Android product flavors are configured: `dev`, `prod`.

Runtime configuration is passed via `--dart-define` and consumed by `lib/environment.dart`.

### Run examples

- Dev:
  - Android: `flutter run --flavor dev -t lib/main.dart --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=https://dev.api.example.com --dart-define=ENABLE_LOGGING=true`
- Prod:
  - Android: `flutter run --flavor prod -t lib/main.dart --dart-define=FLAVOR=prod --dart-define=API_BASE_URL=https://api.example.com --dart-define=ENABLE_LOGGING=false`

Napomena: Za Android je potrebna instalacija Android SDK-a i prihvatanje licenci.

## Windows build

Prerequisites:
- Flutter SDK installed and on PATH
- Visual Studio with Desktop development with C++ workload

Quick build (PowerShell):

```
cd scripts
./build-windows.ps1 -Flavor prod -Main lib/main.dart -ApiBaseUrl https://api.example.com -EnableLogging false -StripeKey "pk_test_xxx"
```

Manual build:

```
flutter pub get
flutter build windows --release --flavor prod -t lib/main.dart \
  --dart-define=FLAVOR=prod \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=ENABLE_LOGGING=false \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

Output: `build/windows/x64/runner/Release`
