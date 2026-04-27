import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/cart_provider.dart';
import '../domain/order_models.dart';
import 'order_detail_screen.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  bool _updating = false;

  OrderModel? _order;
  bool _loading = true;
  String? _error;

  static String _normShipping(String? status) {
    if (status == null || status.trim().isEmpty) return '';
    return status.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  /// Korak prije kurira: Pending / Kreirano.
  bool _canSetProcessing(OrderModel o) {
    final String k = _normShipping(o.shippingStatus);
    if (k == 'cancelled' || k == 'canceled' || k == 'delivered' || k == 'returned') return false;
    if (k == 'processing') return false;
    if (k == 'shipped' || k == 'intransit' || k == 'atcustoms' || k == 'outfordelivery') return false;
    return k == 'pending' || k == 'created' || k == 'new' || k == 'zaprimljena' || k == 'primljena' || k.isEmpty;
  }

  /// Predaja kuriru: samo nakon „obrade”.
  bool _canSetShipped(OrderModel o) => _normShipping(o.shippingStatus) == 'processing';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic>? json =
          await ref.read(ordersApiProvider).getOrder(orderId: widget.orderId);
      if (!mounted) return;
      if (json == null) {
        setState(() {
          _order = null;
          _loading = false;
          _error = 'Narudžba nije pronađena.';
        });
        return;
      }
      setState(() {
        _order = OrderModel.fromJson(json);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmAndPatch({
    required String title,
    required String body,
    required String confirmLabel,
    required String status,
    required String message,
    required String successSnack,
  }) async {
    final OrderModel? o = _order;
    if (o == null || _updating) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _updating = true);
    try {
      await ref.read(ordersApiProvider).updateShippingStatus(
            orderId: o.id,
            status: status,
            message: message,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successSnack)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _onSetProcessing() => _confirmAndPatch(
        title: 'Obrada narudžbe',
        body: 'Postaviti status na „Obrada narudžbe”? Kupac će to vidjeti u pregledu narudžbe.',
        confirmLabel: 'U obradu',
        status: 'Processing',
        message: 'Narudžba u obradi',
        successSnack: 'Status ažuriran: obrada narudžbe.',
      );

  Future<void> _onSetShipped() => _confirmAndPatch(
        title: 'Predaja kuriru',
        body: 'Označiti da je paket predan kuriru (poslano)?',
        confirmLabel: 'Predaj kuriru',
        status: 'Shipped',
        message: 'Predano kuriru — narudžba poslana',
        successSnack: 'Status ažuriran: poslano.',
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
              ],
            ),
          ),
        ),
      );
    }
    final OrderModel? o = _order;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Narudžba #${widget.orderId}')),
        body: const Center(child: Text('Narudžba nije pronađena.')),
      );
    }

    final bool showProcessing = _canSetProcessing(o) && !_updating;
    final bool showShipped = _canSetShipped(o) && !_updating;
    final bool showBusy = _updating;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Narudžba ${o.orderNumber}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: OrderDetailScreen(order: o, embedded: true)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (showBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...<Widget>[
                    FilledButton.tonalIcon(
                      onPressed: showProcessing ? _onSetProcessing : null,
                      icon: const Icon(Icons.autorenew),
                      label: const Text('U obradu narudžbe'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: showShipped ? _onSetShipped : null,
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Predaj kuriru (poslano)'),
                    ),
                    if (!showBusy && (showProcessing || showShipped || _canSetProcessing(o)))
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                        child: Text(
                          'Kliknite kad kurir preuzme paket.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    if (!showProcessing && !showShipped && !showBusy)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Nema dostupnih akcija za trenutni status isporuke.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
