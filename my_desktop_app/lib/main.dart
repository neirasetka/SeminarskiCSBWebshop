import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/router.dart';
import 'app/theme_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1100, 720),
    minimumSize: Size(900, 600),
    title: 'My Desktop App',
    titleBarStyle: TitleBarStyle.normal,
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'My Desktop App',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
