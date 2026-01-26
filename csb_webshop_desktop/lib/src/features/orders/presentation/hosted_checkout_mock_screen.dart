import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/cart_provider.dart';
import '../data/orders_api.dart';

class HostedCheckoutMockScreen extends ConsumerStatefulWidget {
  const HostedCheckoutMockScreen({super.key});

  @override
  ConsumerState<HostedCheckoutMockScreen> createState() => _HostedCheckoutMockScreenState();
}

class _HostedCheckoutMockScreenState extends ConsumerState<HostedCheckoutMockScreen> {
  bool _confirming = false;

  Uri get _checkoutUrl {
    final int port = int.tryParse(Platform.environment['MOCK_CHECKOUT_PORT'] ?? '') ?? 4242;
    return Uri.parse('http://localhost:$port/checkout.html');
  }

  Future<void> _openInBrowser() async {
    if (_confirming) return;
    final Uri url = _checkoutUrl;
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ne mogu otvoriti preglednik.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: const Text('Hosted Checkout (Mock)'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Checkout će se otvoriti u vašem pregledniku.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _openInBrowser,
              child: const Text('Otvori checkout'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

