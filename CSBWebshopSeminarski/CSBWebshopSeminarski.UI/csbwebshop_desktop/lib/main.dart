import 'package:flutter/material.dart';
import 'package:csb_shared/csb_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CSB Webshop',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
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
