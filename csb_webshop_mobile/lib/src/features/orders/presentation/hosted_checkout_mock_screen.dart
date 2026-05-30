import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../environment.dart';
import '../application/cart_provider.dart';
import '../application/checkout_stripe_error_formatter.dart';
import '../domain/order_models.dart';

class HostedCheckoutMockScreen extends ConsumerStatefulWidget {
  const HostedCheckoutMockScreen({super.key});

  @override
  ConsumerState<HostedCheckoutMockScreen> createState() => _HostedCheckoutMockScreenState();
}

class _HostedCheckoutMockScreenState extends ConsumerState<HostedCheckoutMockScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final CartNotifier cartNotifier = ref.read(cartProvider.notifier);
    final bool stripeConfigured =
        EnvironmentConfig.stripePublishableKey.isNotEmpty &&
        EnvironmentConfig.stripePublishableKey.startsWith('pk_');

    if (stripeConfigured) {
      try {
        await cartNotifier.startCheckout();
        if (mounted) {
          setState(() => _isProcessing = false);
          cartNotifier.resetCartAfterPayment();
          context.go('/checkout/success');
        }
        return;
      } catch (e, st) {
        logCheckoutFailure(e, st);
        if (mounted) {
          setState(() => _isProcessing = false);
          final String uiMsg = formatCheckoutErrorForUi(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uiMsg),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Detalji',
                textColor: Colors.white,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext ctx) => AlertDialog(
                      title: const Text('Stripe / checkout'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          '${formatCheckoutErrorForLog(e)}\n\n'
                          'Provjeri: isti Stripe nalog (pk_ + sk_ na API), API URL '
                          '(${EnvironmentConfig.apiBaseUrl}), Android rebuild nakon '
                          'FlutterFragmentActivity + AppCompat teme.',
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Zatvori'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
        return;
      }
    }

    if (!kDebugMode) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plaćanje nije dostupno — Stripe nije konfiguriran.'),
          ),
        );
      }
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);
      cartNotifier.resetCartAfterPayment();
      context.go('/checkout/success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderModel?> cartAsync = ref.watch(cartProvider);
    final double totalAmount = cartAsync.value?.amount ?? 0.0;
    final bool stripeConfigured =
        EnvironmentConfig.stripePublishableKey.isNotEmpty &&
            EnvironmentConfig.stripePublishableKey.startsWith('pk_');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plaćanje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 120),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!stripeConfigured && kDebugMode) ...<Widget>[
                  Text(
                    'Nema valjanog Stripe pk_ ključa — ovo je demo tok bez stvarne naplate (samo debug).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ] else if (!stripeConfigured) ...<Widget>[
                  Text(
                    'Plaćanje nije dostupno — Stripe publishable key nije konfiguriran.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Ukupno za plaćanje:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${totalAmount.toStringAsFixed(2)} KM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isProcessing || (!stripeConfigured && !kDebugMode)
                        ? null
                        : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.payment),
                              SizedBox(width: 8),
                              Text(
                                'Plati',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
