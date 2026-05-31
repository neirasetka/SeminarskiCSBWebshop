import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/paged_list_state.dart';
import '../../../utils/date_formatter.dart';
import '../../../widgets/status_badge.dart';
import '../application/admin_orders_provider.dart';
import '../domain/order_models.dart';

/// Pregled svih narudžbi za admina; otvaranje detalja i označavanje kao poslano.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminOrdersListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(adminOrdersListProvider.notifier).refresh(
          orderNumberPrefix: _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PagedListState<OrderModel>> async = ref.watch(adminOrdersListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista narudžbi'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pretraži po broju narudžbe',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onRefresh(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.search),
                  label: const Text('Traži'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
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
                        onPressed: _onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (PagedListState<OrderModel> paged) {
                final List<OrderModel> orders = paged.items;
                if (orders.isEmpty) {
                  return const Center(child: Text('Nema narudžbi.'));
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: orders.length + (paged.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
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
                            if (o.paymentStatus != null)
                              StatusBadge(status: o.paymentStatus!)
                            else
                              const Text('—'),
                            const Text('·'),
                            if (o.shippingStatus != null)
                              StatusBadge(status: o.shippingStatus!)
                            else
                              const Text('—'),
                          ],
                        ),
                        trailing: Text('${o.amount.toStringAsFixed(2)} KM'),
                        onTap: () => context.push('/admin/narudzbe/${o.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
