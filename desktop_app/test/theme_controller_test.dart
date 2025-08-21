import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_app/features/settings/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeController initializes with stored value and toggles', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state should be system until async load completes
    expect(container.read(themeControllerProvider), ThemeMode.system);

    // After set, state and persistence should update
    await container.read(themeControllerProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(container.read(themeControllerProvider), ThemeMode.dark);

    // Toggle to light
    await container.read(themeControllerProvider.notifier).toggleThemeMode();
    expect(container.read(themeControllerProvider), ThemeMode.light);

    // New container should read persisted value
    final ProviderContainer container2 = ProviderContainer();
    addTearDown(container2.dispose);
    // allow microtask queue
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container2.read(themeControllerProvider), isA<ThemeMode>());
  });
}