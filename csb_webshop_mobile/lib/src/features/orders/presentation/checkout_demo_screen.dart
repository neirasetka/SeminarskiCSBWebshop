import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/cart_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class CheckoutDemoScreen extends ConsumerStatefulWidget {
  const CheckoutDemoScreen({super.key});

  @override
  ConsumerState<CheckoutDemoScreen> createState() => _CheckoutDemoScreenState();
}

class _CheckoutDemoScreenState extends ConsumerState<CheckoutDemoScreen> {
  bool _isProcessing = false;

  Future<void> _startPayment(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final OrdersApi ordersApi = ref.read(ordersApiProvider);
    final ProfileApi profileApi = ref.read(profileApiProvider);

    try {
      final int userId = (await profileApi.getMe()).id;
      const double priceBAM = 120.0;
      final Map<String, dynamic> created = await ordersApi.createOrder(
        userId: userId,
        orderNumber: 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        price: priceBAM,
      );
      final OrderModel order = OrderModel.fromJson(created);

      // Create PaymentIntent for this order (use EUR for broad Stripe test compatibility)
      final Map<String, dynamic> paymentIntent = await ordersApi.createPaymentIntent(
        orderId: order.id,
        amountInCents: (priceBAM * 100).round(),
        currency: 'eur',
      );
      final String clientSecret = (paymentIntent['ClientSecret'] ?? paymentIntent['clientSecret'] ?? '').toString();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CSB Webshop',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      await ordersApi.updatePaymentStatus(orderId: order.id, status: 'Paid');

      if (mounted) {
        ref.read(cartProvider.notifier).resetCartAfterPayment();
        context.go('/checkout/success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plaćanje nije uspjelo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Plaćanje primjer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Iznos: 120.00 KM (test)')
                  ,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _startPayment(context),
                  child: _isProcessing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Plati'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

