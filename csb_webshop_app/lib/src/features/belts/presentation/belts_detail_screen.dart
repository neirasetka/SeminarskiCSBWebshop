import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/belts_provider.dart';
import '../domain/belt.dart';
import '../../orders/application/cart_provider.dart';

class BeltDetailScreen extends ConsumerStatefulWidget {
  const BeltDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BeltDetailScreen> createState() => _BeltDetailScreenState();
}

class _BeltDetailScreenState extends ConsumerState<BeltDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beltDetailProvider.notifier).fetch(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Belt> beltAsync = ref.watch(beltDetailProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji kaiša')),
      body: beltAsync.when(
        data: (Belt belt) => _BeltDetailBody(belt: belt),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Greška pri učitavanju detalja.'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(beltDetailProvider.notifier).fetch(widget.id),
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

class _BeltDetailBody extends ConsumerWidget {
  const _BeltDetailBody({required this.belt});

  final Belt belt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHeader(imageUrl: belt.displayImageUrl),
          const SizedBox(height: 16),
          Text(belt.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('${belt.price.toStringAsFixed(2)} KM', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 16),
              if (belt.averageRating != null)
                Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(belt.averageRating!.toStringAsFixed(1)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SpecRow(label: 'Šifra', value: belt.code ?? '/'),
          _SpecRow(label: 'Tip', value: belt.beltTypeId?.toString() ?? '/'),
          const Divider(height: 32),
          const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(belt.description),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(cartProvider.notifier).addBagToCart(bagId: belt.id, price: belt.price);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dodano u korpu')));
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Dodaj u korpu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      height: 240,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Icon(Icons.image, size: 48)),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

