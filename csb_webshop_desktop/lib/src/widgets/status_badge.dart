import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static const Map<String, String> _labels = {
    'Pending': 'Na čekanju',
    'Paid': 'Plaćeno',
    'Failed': 'Neuspjelo',
    'Processing': 'U obradi',
    'InTransit': 'U transportu',
    'Shipped': 'Poslano',
    'Delivered': 'Isporučeno',
    'Cancelled': 'Otkazano',
    'Approved': 'Odobreno',
    'Rejected': 'Odbijeno',
  };

  static const Map<String, Color> _colors = {
    'Pending': Colors.orange,
    'Paid': Colors.green,
    'Failed': Colors.red,
    'Processing': Colors.blue,
    'InTransit': Colors.indigo,
    'Shipped': Colors.indigo,
    'Delivered': Colors.teal,
    'Cancelled': Colors.grey,
    'Approved': Colors.green,
    'Rejected': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? Colors.grey;

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
