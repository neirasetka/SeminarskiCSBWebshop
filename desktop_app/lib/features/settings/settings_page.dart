import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/constants.dart';
import 'theme_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode selected = ref.watch(themeControllerProvider);

    Future<void> onChanged(ThemeMode? mode) async {
      if (mode != null) {
        await ref.read(themeControllerProvider.notifier).setThemeMode(mode);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text('Theme'),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: selected,
            onChanged: onChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: selected,
            onChanged: onChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}