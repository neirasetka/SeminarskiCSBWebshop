import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/date_formatter.dart';
import '../../../widgets/status_badge.dart';
import '../application/admin_orders_provider.dart';
import '../domain/order_models.dart';

/// Pregled svih narudžbi za admina; otvaranje detalja i označavanje kao poslano.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OrderModel>> async = ref.watch(adminOrdersListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Narudžbe'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Osvježi',
            onPressed: () => ref.invalidate(adminOrdersListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(adminOrdersListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
        data: (List<OrderModel> orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Nema narudžbi.'));
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final OrderModel o = orders[index];
              final String buyer = (o.userUserName != null && o.userUserName!.trim().isNotEmpty)
                  ? o.userUserName!.trim()
                  : 'Korisnik #${o.userId}';
              return ListTile(
                title: Text(o.orderNumber),
                subtitle: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: <Widget>[
                    Text('$buyer · ${DateFormatter.formatDateTime(o.date)} ·'),
                    if (o.paymentStatus != null) StatusBadge(status: o.paymentStatus!) else const Text('—'),
                    const Text('·'),
                    if (o.shippingStatus != null) StatusBadge(status: o.shippingStatus!) else const Text('—'),
                  ],
                ),
                trailing: Text('${o.amount.toStringAsFixed(2)} KM'),
                onTap: () => context.push('/admin/narudzbe/${o.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
