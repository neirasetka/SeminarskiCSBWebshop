import 'package:flutter/material.dart';
import 'package:csb_shared/csb_shared.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env.dart';
import 'auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await SharedBootstrap.runWithSentryIfConfigured(
    dsn: Env.sentryDsn,
    app: ProviderScope(observers: [AppProviderObserver()], child: const MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger auth state initialization on startup
    ref.watch(authProvider);
    final router = AppRouter.createRouter();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CSB Webshop',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        // Defaults to Material, Widgets, and Cupertino localizations
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('bs'),
      ],
      routerConfig: router,
    );
  }
}
