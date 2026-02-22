import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/domain/bag.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../belts/domain/belt.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../orders/application/cart_provider.dart';
import '../application/favorites_list_provider.dart';
import '../application/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FavoritesListResult> asyncResult =
        ref.watch(favoritesListProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Moji favoriti'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncResult.when(
        data: (FavoritesListResult result) {
          if (result.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nemate favorita',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dodajte torbice ili kaiševe u favorite\niz odjeljka Torbice ili Kaiševi.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (result.bags.isNotEmpty) ...<Widget>[
                  Text(
                    'Torbice',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: result.bags.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Bag bag = result.bags[index];
                      return _FavoriteBagCard(
                        bag: bag,
                        onTap: () => _openBagDetail(context, bag),
                        onRemoveFavorite: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleBag(bag.id),
                        onAddToCart: () => _addBagToCart(context, ref, bag),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                if (result.belts.isNotEmpty) ...<Widget>[
                  Text(
                    'Kaiševi',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: result.belts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Belt belt = result.belts[index];
                      return _FavoriteBeltCard(
                        belt: belt,
                        onTap: () => _openBeltDetail(context, belt),
                        onRemoveFavorite: () => ref
                            .read(beltFavoritesProvider.notifier)
                            .toggleBelt(belt.id),
                        onAddToCart: () => _addBeltToCart(context, ref, belt),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              const Text('Greška pri učitavanju favorita'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(favoritesListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovno'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openBagDetail(BuildContext context, Bag bag) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BagDetailScreen(id: bag.id),
      ),
    );
  }

  static void _openBeltDetail(BuildContext context, Belt belt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BeltDetailScreen(id: belt.id),
      ),
    );
  }

  static Future<void> _addBagToCart(
      BuildContext context, WidgetRef ref, Bag bag) async {
    await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bag.name} dodano u korpu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> _addBeltToCart(
      BuildContext context, WidgetRef ref, Belt belt) async {
    await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${belt.name} dodano u korpu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _FavoriteBagCard extends StatelessWidget {
  const _FavoriteBagCard({
    required this.bag,
    required this.onTap,
    required this.onRemoveFavorite,
    required this.onAddToCart,
  });

  final Bag bag;
  final VoidCallback onTap;
  final VoidCallback onRemoveFavorite;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _Image(url: bag.displayImageUrl, icon: Icons.shopping_bag_outlined),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemoveFavorite,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      bag.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Text(
                          '${bag.price.toStringAsFixed(2)} KM',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Kupi'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteBeltCard extends StatelessWidget {
  const _FavoriteBeltCard({
    required this.belt,
    required this.onTap,
    required this.onRemoveFavorite,
    required this.onAddToCart,
  });

  final Belt belt;
  final VoidCallback onTap;
  final VoidCallback onRemoveFavorite;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _Image(url: belt.displayImageUrl, icon: Icons.straighten),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemoveFavorite,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      belt.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Text(
                          '${belt.price.toStringAsFixed(2)} KM',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Kupi'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({this.url, required this.icon});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, size: 48, color: colorScheme.outline),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progress) {
        if (progress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
