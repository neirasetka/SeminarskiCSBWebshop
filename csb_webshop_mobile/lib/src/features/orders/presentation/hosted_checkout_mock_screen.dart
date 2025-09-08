import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/cart_provider.dart';
import '../data/orders_api.dart';

class HostedCheckoutMockScreen extends ConsumerStatefulWidget {
  const HostedCheckoutMockScreen({super.key});

  @override
  ConsumerState<HostedCheckoutMockScreen> createState() => _HostedCheckoutMockScreenState();
}

class _HostedCheckoutMockScreenState extends ConsumerState<HostedCheckoutMockScreen> {
  InAppWebViewController? _controller;
  bool _confirming = false;

  Uri get _checkoutUrl {
    final int port = int.tryParse(Platform.environment['MOCK_CHECKOUT_PORT'] ?? '') ?? 4242;
    return Uri.parse('http://localhost:$port/checkout.html');
  }

  Future<void> _onPageLoaded(Uri? url) async {
    if (url == null) return;
    if (_confirming) return;
    final String path = url.path.toLowerCase();
    if (path.endsWith('/success.html')) {
      _confirming = true;
      try {
        final OrdersApi ordersApi = ref.read(ordersApiProvider);
        final confirmation = await ordersApi.confirmMockCheckout();
        if (mounted) {
          context.go('/checkout/success', extra: confirmation);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gre61ka pri potvrdi: $e')));
        }
      } finally {
        _confirming = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hosted Checkout (Mock)')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(_checkoutUrl)),
        onWebViewCreated: (InAppWebViewController controller) => _controller = controller,
        onLoadStop: (InAppWebViewController controller, Uri? url) => _onPageLoaded(url),
      ),
    );
  }
}

