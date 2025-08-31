import 'package:flutter/material.dart';
import 'package:csb_shared/csb_shared.dart';

void main() {
  runApp(const MyApp());
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
      routerConfig: router,
    );
  }
}
