import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/constants.dart';
import '../settings/theme_controller.dart';
import '../../shared/widgets/custom_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    final String themeLabel = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Current theme: $themeLabel', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Toggle Theme',
                  onPressed: () => ref.read(themeControllerProvider.notifier).toggleThemeMode(),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: <Widget>[
                    CustomButton(
                      label: 'Settings',
                      onPressed: () => context.goNamed(AppRouteNames.settings),
                    ),
                    CustomButton(
                      label: 'About',
                      onPressed: () => context.goNamed(AppRouteNames.about),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}