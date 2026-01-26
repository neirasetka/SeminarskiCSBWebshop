import 'package:flutter/material.dart';
import '../../../core/back_confirmation_dialog.dart';
import '../domain/order_models.dart';
import 'shipping_status_timeline.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: Text('Narudžba ${order.orderNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _sectionHeader('Pregled'),
          _kv('Broj narudžbe', order.orderNumber),
          _kv('Datum', order.date.toLocal().toString()),
          _kv('Status plaćanja', order.paymentStatus ?? 'N/A'),
          _kv('Status isporuke', order.shippingStatus ?? 'N/A'),
          const SizedBox(height: 8),
          const Divider(),
          _sectionHeader('Praćenje dostave'),
          ShippingStatusTimeline(status: order.shippingStatus),
          const SizedBox(height: 16),
          _sectionHeader('Stavke'),
          ...order.items.map((OrderItemModel item) => _itemTile(item)).toList(),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ukupno: ${order.amount.toStringAsFixed(2)} KM',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }

  Widget _kv(String k, String v) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(k, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(v),
    );
  }

  Widget _itemTile(OrderItemModel item) {
    final String name = item.name ?? (item.code ?? 'Proizvod');
    final double lineTotal = (item.price - (item.discount ?? 0)) * item.quantity;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text('Količina: ${item.quantity} · Cijena: ${item.price.toStringAsFixed(2)} KM'
          '${item.discount != null && item.discount! > 0 ? ' · Popust: ${item.discount!.toStringAsFixed(2)} KM' : ''}'),
      trailing: Text(lineTotal.toStringAsFixed(2) + ' KM'),
    );
  }
}

