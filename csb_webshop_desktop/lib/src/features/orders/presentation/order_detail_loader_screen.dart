import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order_models.dart';
import '../application/cart_provider.dart';
import 'order_detail_screen.dart';

/// Učitava narudžbu s API-ja po ID-u (npr. iz notifikacije ili dubokog linka).
class OrderDetailLoaderScreen extends ConsumerStatefulWidget {
  const OrderDetailLoaderScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailLoaderScreen> createState() => _OrderDetailLoaderScreenState();
}

class _OrderDetailLoaderScreenState extends ConsumerState<OrderDetailLoaderScreen> {
  late final Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(ordersApiProvider).getOrder(orderId: widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
              ),
            ),
          );
        }
        final Map<String, dynamic>? data = snapshot.data;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
            body: const Center(child: Text('Narudžba nije pronađena ili nemate pristup.')),
          );
        }
        final OrderModel order = OrderModel.fromJson(data);
        return OrderDetailScreen(order: order);
      },
    );
  }
}
