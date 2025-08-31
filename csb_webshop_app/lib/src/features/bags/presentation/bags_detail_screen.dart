import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/bags_provider.dart';
import '../domain/bag.dart';

class BagDetailScreen extends ConsumerStatefulWidget {
  const BagDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BagDetailScreen> createState() => _BagDetailScreenState();
}

class _BagDetailScreenState extends ConsumerState<BagDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bagDetailProvider.notifier).fetch(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji torbe')),
      body: bagAsync.when(
        data: (Bag bag) => _BagDetailBody(bag: bag),
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
                onPressed: () => ref.read(bagDetailProvider.notifier).fetch(widget.id),
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

class _BagDetailBody extends StatelessWidget {
  const _BagDetailBody({required this.bag});

  final Bag bag;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHeader(imageUrl: bag.displayImageUrl),
          const SizedBox(height: 16),
          Text(bag.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('${bag.price.toStringAsFixed(2)} KM', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 16),
              if (bag.averageRating != null)
                Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(bag.averageRating!.toStringAsFixed(1)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SpecRow(label: 'Šifra', value: bag.code ?? '/'),
          _SpecRow(label: 'Tip', value: bag.bagTypeId?.toString() ?? '/'),
          const Divider(height: 32),
          const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(bag.description),
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

