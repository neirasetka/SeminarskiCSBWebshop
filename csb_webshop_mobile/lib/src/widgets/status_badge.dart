import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static const Map<String, String> _labels = {
    'Pending': 'Na čekanju',
    'Paid': 'Plaćeno',
    'Failed': 'Neuspjelo',
    'Refunded': 'Refundirano',
    'Processing': 'U obradi',
    'InTransit': 'U transportu',
    'Shipped': 'Poslano',
    'AtCustoms': 'Na carini',
    'OutForDelivery': 'U dostavi',
    'Delivered': 'Isporučeno',
    'Returned': 'Vraćeno',
    'Cancelled': 'Otkazano',
    'Approved': 'Odobreno',
    'Rejected': 'Odbijeno',
  };

  static const Map<String, Color> _colors = {
    'Pending': Colors.orange,
    'Paid': Colors.green,
    'Failed': Colors.red,
    'Refunded': Colors.blueGrey,
    'Processing': Colors.blue,
    'InTransit': Colors.indigo,
    'Shipped': Colors.indigo,
    'AtCustoms': Colors.amber,
    'OutForDelivery': Colors.purple,
    'Delivered': Colors.teal,
    'Returned': Colors.deepOrange,
    'Cancelled': Colors.grey,
    'Approved': Colors.green,
    'Rejected': Colors.red,
  };

  static const Map<String, String> _aliases = {
    'pending': 'Pending',
    'created': 'Pending',
    'new': 'Pending',
    'zaprimljena': 'Pending',
    'primljena': 'Pending',
    'paid': 'Paid',
    'succeeded': 'Paid',
    'success': 'Paid',
    'completed': 'Paid',
    'complete': 'Paid',
    'settled': 'Paid',
    'failed': 'Failed',
    'refunded': 'Refunded',
    'processing': 'Processing',
    'processed': 'Processing',
    'inprogress': 'Processing',
    'preparing': 'Processing',
    'intransit': 'InTransit',
    'shipped': 'Shipped',
    'sent': 'Shipped',
    'atcustoms': 'AtCustoms',
    'outfordelivery': 'OutForDelivery',
    'delivered': 'Delivered',
    'isporuceno': 'Delivered',
    'returned': 'Returned',
    'cancelled': 'Cancelled',
    'canceled': 'Cancelled',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  static String _resolveKey(String rawStatus) {
    final String trimmed = rawStatus.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_labels.containsKey(trimmed)) return trimmed;

    final String normalized = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _aliases[normalized] ?? trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final String key = _resolveKey(status);
    final String label = _labels[key] ?? 'Nepoznato';
    final Color color = _colors[key] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
