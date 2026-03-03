import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/cart_provider.dart';
import 'package:go_router/go_router.dart';
import '../domain/order_models.dart';
// import 'order_success_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OrderModel?> cartAsync = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Korpa'),
      ),
      body: cartAsync.when(
        data: (OrderModel? order) {
          if (order == null || order.items.isEmpty) {
            return const Center(child: Text('Korpa je prazna.'));
          }
          final double totalAmount = order.items.fold<double>(
            0,
            (double sum, OrderItemModel it) =>
                sum + ((it.price * it.quantity) - (it.discount ?? 0)),
          );
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.separated(
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final OrderItemModel item = order.items[index];
                    final double line = (item.price * item.quantity) - (item.discount ?? 0);
                    return ListTile(
                      title: Text(item.name ?? 'Stavka #${item.id}'),
                      subtitle: Text('Količina: ${item.quantity}  ·  Cijena: ${item.price.toStringAsFixed(2)} KM'),
                      trailing: Text('${line.toStringAsFixed(2)} KM'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const Text('Ukupno:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${totalAmount.toStringAsFixed(2)} KM', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(cartProvider.notifier).clearCart();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Korpa je ispražnjena')),
                            );
                          }
                        },
                        icon: const Icon(Icons.remove_shopping_cart),
                        label: const Text('Poništi'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('/checkout'),
                        icon: const Icon(Icons.payment),
                        label: const Text('Plati'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Greška pri učitavanju korpe'),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.read(cartProvider.notifier).refresh(),
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

