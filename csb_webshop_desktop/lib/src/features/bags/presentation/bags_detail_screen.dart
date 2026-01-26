import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/bags_provider.dart';
import '../domain/bag.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';
import '../../collections/application/collections_provider.dart';

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
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji torbe'),
      ),
      body: bagAsync.when(
        data: (Bag bag) {
          final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
          return _BagDetailBody(
            bag: bag,
            isFavorite: isFav,
            onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggleBag(bag.id),
            onAddToCart: () async {
              await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dodano u korpu')));
              }
            },
            onAddToCollection: () async {
              final String? name = await _promptText(context, 'Dodaj u kolekciju', 'Naziv kolekcije');
              if (name != null && name.trim().isNotEmpty) {
                await ref.read(collectionsProvider.notifier).addToCollection(collectionName: name.trim(), bagId: bag.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dodano u kolekciju')));
                }
              }
            },
            onOutfitIdea: () {
              context.pushNamed(
                'outfitIdea',
                pathParameters: <String, String>{'id': bag.id.toString()},
              );
            },
          );
        },
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
  const _BagDetailBody({required this.bag, required this.isFavorite, required this.onToggleFavorite, required this.onAddToCart, required this.onAddToCollection, required this.onOutfitIdea});

  final Bag bag;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToCollection;
  final VoidCallback onOutfitIdea;

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
              const Spacer(),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : null),
                tooltip: isFavorite ? 'Ukloni iz favorita' : 'Dodaj u favorite',
                onPressed: onToggleFavorite,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Dodaj u korpu'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToCollection,
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: const Text('Dodaj u kolekciju'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOutfitIdea,
              icon: const Icon(Icons.style_outlined),
              label: const Text('Outfit Idea'),
            ),
          ),
        ],
      ),
    );
  }
}
Future<String?> _promptText(BuildContext context, String title, String label, [String initial = '']) async {
  final TextEditingController ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Form(
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        ElevatedButton(
          onPressed: () {
            final String val = ctrl.text.trim();
            if (val.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naziv je obavezan')));
              return;
            }
            Navigator.of(context).pop(val);
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    ),
  );
}


class _ImageHeader extends StatelessWidget {
  const _ImageHeader({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget placeholderBox = Container(
      height: 240,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Icon(Icons.image, size: 48)),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double imageWidth = constraints.maxWidth * 0.33;
        if (imageUrl == null || imageUrl!.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: imageWidth, child: placeholderBox),
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: imageWidth,
              height: 240,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholderBox,
              ),
            ),
          ),
        );
      },
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

