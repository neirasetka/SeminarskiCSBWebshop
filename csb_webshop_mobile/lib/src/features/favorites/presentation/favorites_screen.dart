import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/domain/belt.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../orders/application/cart_provider.dart';
import '../application/favorites_provider.dart';
import '../domain/favorites_collections.dart';

/// Prikaz torbi i kaiševa koje je korisnik označio kao favorite (lokalno u aplikaciji).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FavoritesCollections> favoritesAsync = ref.watch(favoritesProvider);
    final AsyncValue<List<Bag>> bagsAsync = ref.watch(bagsListProvider);
    final AsyncValue<List<Belt>> beltsAsync = ref.watch(beltsListProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;

    Future<void> onRefresh() async {
      await ref.read(bagsListProvider.notifier).refresh(bagTypeId: null, query: null);
      await ref.read(beltsListProvider.notifier).refresh(beltTypeId: null, query: null);
      await ref.read(favoritesProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriti'),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Greška pri učitavanju favorita: $e'),
          ),
        ),
        data: (FavoritesCollections collections) {
          if (collections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.favorite_border, size: 72, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Nemaš još favorita',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'U katalogu torbi ili kaiševa dodaj srce pored artikla da ga vidiš ovdje.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return bagsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, _) => _CatalogError(message: 'Greška pri učitavanju kataloga torbi', error: e, onRetry: onRefresh),
            data: (List<Bag> allBags) {
              return beltsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => _CatalogError(message: 'Greška pri učitavanju kataloga kaiševa', error: e, onRetry: onRefresh),
                data: (List<Belt> allBelts) {
                  final Map<int, Bag> bagsById = <int, Bag>{for (final Bag b in allBags) b.id: b};
                  final Map<int, Belt> beltsById = <int, Belt>{for (final Belt b in allBelts) b.id: b};

                  final List<Bag> favoriteBags = <Bag>[];
                  for (final int id in collections.bagIds) {
                    final Bag? b = bagsById[id];
                    if (b != null) favoriteBags.add(b);
                  }
                  final List<Belt> favoriteBelts = <Belt>[];
                  for (final int id in collections.beltIds) {
                    final Belt? b = beltsById[id];
                    if (b != null) favoriteBelts.add(b);
                  }

                  if (favoriteBags.isEmpty && favoriteBelts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Favoriti više nisu u katalogu',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Osvježi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        if (favoriteBags.isNotEmpty) ...<Widget>[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Torbice',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                final Bag bag = favoriteBags[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (index > 0) const Divider(height: 1),
                                    ListTile(
                                      leading: _BagThumbnail(imageUrl: bag.imageUrl),
                                      title: Text(bag.name),
                                      subtitle: Text(
                                        bag.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: _BagRowTrailing(
                                        bag: bag,
                                        isAdmin: isAdmin,
                                        onRemoveFavorite: () => ref.read(favoritesProvider.notifier).toggleBag(bag.id),
                                        onAddToCart: () async {
                                          await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Artikal uspješno dodan u korpu'),
                                                duration: Duration(seconds: 5),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (BuildContext context) => BagDetailScreen(id: bag.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                              childCount: favoriteBags.length,
                            ),
                          ),
                        ],
                        if (favoriteBelts.isNotEmpty) ...<Widget>[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, favoriteBags.isNotEmpty ? 8 : 16, 16, 8),
                              child: Text(
                                'Kaiševi',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                final Belt belt = favoriteBelts[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (index > 0) const Divider(height: 1),
                                    ListTile(
                                      leading: _BeltThumbnail(displayUrl: belt.displayImageUrl),
                                      title: Text(belt.name),
                                      subtitle: Text(
                                        belt.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: _BeltRowTrailing(
                                        belt: belt,
                                        isAdmin: isAdmin,
                                        onRemoveFavorite: () => ref.read(favoritesProvider.notifier).toggleBelt(belt.id),
                                        onAddToCart: () async {
                                          await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Artikal uspješno dodan u korpu'),
                                                duration: Duration(seconds: 5),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (BuildContext context) => BeltDetailScreen(id: belt.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                              childCount: favoriteBelts.length,
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.error, required this.onRetry});

  final String message;
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 8),
          Text(error.toString(), style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovno'),
          ),
        ],
      ),
    );
  }
}

class _BagRowTrailing extends StatelessWidget {
  const _BagRowTrailing({
    required this.bag,
    required this.isAdmin,
    required this.onRemoveFavorite,
    required this.onAddToCart,
  });

  final Bag bag;
  final bool isAdmin;
  final VoidCallback onRemoveFavorite;
  final Future<void> Function() onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          tooltip: 'Ukloni iz favorita',
          onPressed: onRemoveFavorite,
        ),
        if (!isAdmin)
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Dodaj u korpu',
            onPressed: onAddToCart,
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text('${bag.price.toStringAsFixed(2)} KM'),
            if (bag.averageRating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(bag.averageRating!.toStringAsFixed(1)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _BeltRowTrailing extends StatelessWidget {
  const _BeltRowTrailing({
    required this.belt,
    required this.isAdmin,
    required this.onRemoveFavorite,
    required this.onAddToCart,
  });

  final Belt belt;
  final bool isAdmin;
  final VoidCallback onRemoveFavorite;
  final Future<void> Function() onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          tooltip: 'Ukloni iz favorita',
          onPressed: onRemoveFavorite,
        ),
        if (!isAdmin)
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Dodaj u korpu',
            onPressed: onAddToCart,
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text('${belt.price.toStringAsFixed(2)} KM'),
            if (belt.averageRating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(belt.averageRating!.toStringAsFixed(1)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _BagThumbnail extends StatelessWidget {
  const _BagThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder,
      ),
    );
  }
}

class _BeltThumbnail extends StatelessWidget {
  const _BeltThumbnail({this.displayUrl});

  final String? displayUrl;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.checkroom_outlined),
    );
    if (displayUrl == null || displayUrl!.isEmpty) return placeholder;
    if (displayUrl!.startsWith('data:image')) {
      try {
        final String base64Part = displayUrl!.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
        );
      } catch (_) {
        return placeholder;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        displayUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder,
      ),
    );
  }
}
