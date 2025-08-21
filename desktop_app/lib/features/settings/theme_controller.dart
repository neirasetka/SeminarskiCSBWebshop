import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exposes the current ThemeMode and allows updating it.
final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

/// Manages ThemeMode state and persists it to SharedPreferences.
class ThemeController extends Notifier<ThemeMode> {
  static const String _prefsKey = 'themeMode';
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    _initialize();
    return ThemeMode.system;
  }

  /// Loads ThemeMode from SharedPreferences asynchronously.
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final int? index = _prefs!.getInt(_prefsKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
    }
  }

  /// Sets theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, mode.index);
  }

  /// Cycles between light and dark (system -> dark).
  Future<void> toggleThemeMode() async {
    final ThemeMode next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    await setThemeMode(next);
  }
}