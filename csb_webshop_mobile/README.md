# csb_webshop_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flutter SDK setup

Follow the official guide: [Install Flutter](https://docs.flutter.dev/get-started/install).

- Linux/macOS (quick CLI example):

```bash
# Linux example (adjust versions/paths as needed)
mkdir -p "$HOME/tools"
cd "$HOME/tools"
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
echo 'export PATH="$HOME/tools/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
# Android only: accept licenses
flutter doctor --android-licenses
```

- Windows (high-level):
  - Download Flutter SDK zip from the official site
  - Extract to e.g. `C:\tools\flutter`
  - Add `C:\tools\flutter\bin` to PATH
  - Open a new terminal and run `flutter doctor`

## Install dependencies and run (this project)

```bash
cd csb_webshop_mobile
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

Note: Building/running Android requires the Android SDK and accepting licenses.

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
