import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (ThemeMode? value) => value == null ? null : ref.read(themeModeProvider.notifier).setThemeMode(value),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (ThemeMode? value) => value == null ? null : ref.read(themeModeProvider.notifier).setThemeMode(value),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (ThemeMode? value) => value == null ? null : ref.read(themeModeProvider.notifier).setThemeMode(value),
          ),
        ],
      ),
    );
  }
}