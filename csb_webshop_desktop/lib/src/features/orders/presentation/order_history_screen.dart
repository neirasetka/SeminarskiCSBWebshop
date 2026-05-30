import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/date_formatter.dart';
import '../../../widgets/status_badge.dart';
import '../application/order_history_provider.dart';
import '../domain/order_models.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Nazad',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Moje narudžbe'),
      ),
      body: ordersAsync.when(
        data: (List<OrderModel> orders) {
          if (orders.isEmpty) return const Center(child: Text('Još uvijek nemate narudžbi.'));
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final o = orders[index];
              return ListTile(
                title: Text(o.orderNumber),
                subtitle: Row(
                  children: <Widget>[
                    Text('${DateFormatter.formatDateTime(o.date)} · '),
                    if (o.paymentStatus != null)
                      StatusBadge(status: o.paymentStatus!)
                    else
                      const Text('N/A'),
                  ],
                ),
                trailing: Text('${o.amount.toStringAsFixed(2)} KM'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderDetailScreen(order: o),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Greška pri dohvaćanju narudžbi'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.read(orderHistoryProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovno'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

