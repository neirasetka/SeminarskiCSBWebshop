import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment.dart';
import 'src/core/app_router.dart';
import 'src/core/notification_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (EnvironmentConfig.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = EnvironmentConfig.stripePublishableKey;
  }
  NotificationService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String flavor = EnvironmentConfig.flavor;
    return MaterialApp.router(
      title: 'CSB Webshop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: appRouter,
    );
  }
}
