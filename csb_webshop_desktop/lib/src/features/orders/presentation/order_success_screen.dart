import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/cart_provider.dart';
import '../data/orders_api.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({
    super.key,
    this.isPending = false,
    this.orderId,
    this.sessionId,
  });

  final bool isPending;
  final int? orderId;
  final String? sessionId;

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  final OrdersApi _ordersApi = OrdersApi();
  bool _isPending = false;
  bool _isCheckingStatus = false;
  Timer? _slowRefreshTimer;

  @override
  void initState() {
    super.initState();
    _isPending = widget.isPending;
    if (_isPending && widget.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startStatusTracking(widget.orderId!);
      });
    }
  }

  @override
  void dispose() {
    _slowRefreshTimer?.cancel();
    super.dispose();
  }

  bool _isPaidStatus(String? status) {
    if (status == null) return false;
    final String normalized = status.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'paid' ||
        normalized == 'succeeded' ||
        normalized == 'success' ||
        normalized == 'completed' ||
        normalized == 'complete' ||
        normalized == 'settled';
  }

  String? _extractPaymentStatus(Map<String, dynamic> orderData) {
    final List<Object?> candidates = <Object?>[
      orderData['PaymentStatus'],
      orderData['paymentStatus'],
      orderData['PaymentStatusName'],
      orderData['paymentStatusName'],
      orderData['Status'],
      orderData['status'],
      orderData['PaymentStatusId'],
      orderData['paymentStatusId'],
    ];

    for (final Object? candidate in candidates) {
      if (candidate == null) continue;
      final String value = candidate.toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _startStatusTracking(int orderId) async {
    _slowRefreshTimer?.cancel();

    // Fast polling immediately after Stripe return.
    for (int i = 0; i < 10 && mounted && _isPending; i++) {
      final bool paid = await _checkIfPaid(orderId);
      if (paid) return;
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (!mounted || !_isPending) return;

    // Keep auto-refreshing if webhook confirmation arrives later.
    _slowRefreshTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      if (!mounted || !_isPending) {
        timer.cancel();
        return;
      }
      final bool paid = await _checkIfPaid(orderId);
      if (paid) {
        timer.cancel();
      }
    });
  }

  Future<bool> _checkIfPaid(int orderId) async {
    if (_isCheckingStatus || !_isPending) return false;
    _isCheckingStatus = true;
    try {
      final String sid = widget.sessionId?.trim() ?? '';
      if (sid.isNotEmpty) {
        try {
          await _ordersApi.confirmCheckoutSession(
            sessionId: sid,
            orderId: orderId,
          );
        } catch (_) {
          // Fallback: even if confirm endpoint fails, continue with GET order status check.
        }
      }
      final Map<String, dynamic>? orderData = await _ordersApi.getOrder(orderId: orderId);
      final String? status = _extractPaymentStatus(orderData ?? <String, dynamic>{});
      if (_isPaidStatus(status)) {
        if (!mounted) return true;
        ref.read(cartProvider.notifier).resetCartAfterPayment();
        setState(() => _isPending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plaćanje je uspješno potvrđeno.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        return true;
      }
    } catch (_) {
      // Keep screen stable; next refresh attempt can recover.
    } finally {
      _isCheckingStatus = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: Text(_isPending ? 'Plaćanje u obradi' : 'Uspješno plaćeno'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                _isPending ? Icons.hourglass_top : Icons.check_circle,
                color: _isPending ? Colors.orange : Colors.green,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                _isPending ? 'Plaćanje je pokrenuto' : 'Hvala na kupovini!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isPending
                    ? 'Provjeravamo status uplate. Čim uplata bude potvrđena, '
                        'ekran će se automatski ažurirati.'
                    : 'Potvrda je poslana na vašu e-mail adresu.',
                textAlign: TextAlign.center,
              ),
              if (!_isPending) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Uplata je uspješno potvrđena.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isPending) ...<Widget>[
                const SizedBox(height: 16),
                const CircularProgressIndicator(strokeWidth: 2),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
                child: const Text('Nazad na početnu'),
              )
            ],
          ),
        ),
      ),
    ),
    );
  }
}

