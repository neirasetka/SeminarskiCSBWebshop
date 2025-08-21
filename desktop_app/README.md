# Desktop App (Flutter)

A Flutter desktop scaffold using Riverpod for state management, GoRouter for navigation, and SharedPreferences for simple persistence.

## Prerequisites
- Flutter SDK installed (stable channel)
- Dart SDK (bundled with Flutter)

## Setup
```bash
cd desktop_app
flutter --version
flutter pub get
# If platform folders are missing (since this was scaffolded manually):
flutter create .
```

## Run (desktop)
```bash
# Linux
flutter run -d linux
# macOS
flutter run -d macos
# Windows
flutter run -d windows
```

## Test
```bash
flutter test
```

## Project structure
```
lib/
  app.dart                  # Root widget (themes + router)
  main.dart                 # Entrypoint with ProviderScope
  routes/app_router.dart    # GoRouter configuration
  features/
    home/
      home_page.dart
      home_controller.dart
    settings/
      settings_page.dart
      theme_controller.dart
    about/
      about_page.dart
  shared/
    widgets/
      custom_button.dart
    utils/
      constants.dart
  services/
    file_service.dart       # Optional file picker/save helper
```

## Notes
- `ThemeController` persists the selected theme using `SharedPreferences`.
- `file_selector` is optional and used in `FileService` for open/save dialogs.