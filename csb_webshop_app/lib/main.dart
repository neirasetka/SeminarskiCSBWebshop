import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment.dart';
import 'src/features/root/presentation/root_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (EnvironmentConfig.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = EnvironmentConfig.stripePublishableKey;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String flavor = EnvironmentConfig.flavor;
    return MaterialApp(
      title: 'CSB Webshop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RootScreen(title: 'CSB Webshop (${flavor.toUpperCase()})'),
    );
  }
}
