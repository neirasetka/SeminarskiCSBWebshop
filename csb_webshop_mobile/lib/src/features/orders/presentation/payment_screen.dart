import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/form_validators.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/cart_provider.dart';
import '../application/checkout_stripe_error_formatter.dart';
import '../domain/order_models.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile != null && mounted) {
        setState(() => _emailController.text = profile.email);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(cartProvider.notifier).startCheckout(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      ref.read(cartProvider.notifier).resetCartAfterPayment();
      context.go('/checkout/success');
    } catch (e, st) {
      logCheckoutFailure(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formatCheckoutErrorForUi(e)),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderModel?> cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plaćanje')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Greška: $e')),
        data: (OrderModel? order) {
          if (order == null || order.items.isEmpty) {
            return const Center(child: Text('Korpa je prazna.'));
          }

          final double total = order.items.fold<double>(
            0,
            (double sum, OrderItemModel it) =>
                sum + ((it.price * it.quantity) - (it.discount ?? 0)),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Ukupno: ${total.toStringAsFixed(2)} KM',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${order.items.length} stavki u korpi'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email za potvrdu',
                      border: OutlineInputBorder(),
                      errorMaxLines: 3,
                    ),
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processPayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                    label: Text(_isProcessing ? 'Obrada...' : 'Plati karticom'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
