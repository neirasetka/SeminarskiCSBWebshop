import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/cart_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}

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

      if (!_isStripeSupportedPlatform) {
        final String? email = (await profileApi.getMe()).email;
        await _doHostedCheckout(
          context,
          ordersApi: ordersApi,
          order: order,
          receiptEmail: email,
        );
      } else {
        final Map<String, dynamic> paymentIntent = await ordersApi.createPaymentIntent(
          orderId: order.id,
          amountInCents: (priceBAM * 100).round(),
          currency: 'eur',
        );
        final String clientSecret =
            (paymentIntent['ClientSecret'] ?? paymentIntent['clientSecret'] ?? '').toString();

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'CSB Webshop',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
        await ordersApi.updatePaymentStatus(orderId: order.id, status: 'Paid');
      }

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

  Future<void> _doHostedCheckout(
    BuildContext context, {
    required OrdersApi ordersApi,
    required OrderModel order,
    String? receiptEmail,
  }) async {
    final Map<String, dynamic> resp = await ordersApi.createCheckoutSession(
      orderId: order.id,
      receiptEmail: receiptEmail,
    );
    final String url = (resp['Url'] ?? resp['url'] ?? '').toString();
    if (url.isEmpty) throw Exception('Nije moguće kreirati checkout sesiju');

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Nije moguće otvoriti preglednik');
    }

    const Duration pollInterval = Duration(seconds: 3);
    final DateTime deadline = DateTime.now().add(const Duration(minutes: 10));

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
      final Map<String, dynamic>? orderData = await ordersApi.getOrder(orderId: order.id);
      if (orderData == null) continue;
      final String? status =
          (orderData['PaymentStatus'] ?? orderData['paymentStatus'])?.toString();
      if (status != null &&
          (status.toLowerCase() == 'paid' || status == '1')) {
        return;
      }
    }
    throw Exception('Plaćanje nije dovršeno u predviđenom vremenu.');
  }

  @override
  Widget build(BuildContext context) {
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: const Text('Checkout demo'),
      ),
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
    ),
    );
  }
}

