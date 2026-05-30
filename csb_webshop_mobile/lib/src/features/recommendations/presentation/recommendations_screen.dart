import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../orders/application/cart_provider.dart';
import '../application/recommendations_provider.dart';
import '../domain/recommended_product.dart';

/// Preporučeni proizvodi s backenda (content-based + popular fallback).
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Recommendations> async = ref.watch(recommendationsProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;

    Future<void> onRefresh() async {
      await ref.read(recommendationsProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Za vas'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Nije moguće učitati preporuke.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovno'),
                ),
              ],
            ),
          ),
        ),
        data: (Recommendations data) {
          if (data.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: <Widget>[
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                  Icon(
                    Icons.recommend_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trenutno nema preporuka',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Katalog je prazan ili su svi proizvodi već u vašim favoritima ili kupljeni.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final bool showPopularHint = !data.isFullyPersonalized;

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: <Widget>[
                if (showPopularHint)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Prikazujemo popularne proizvode. Dodajte favorite ili ocijenite proizvode za personalizirane preporuke.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (data.bags.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Preporučene torbice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...data.bags.map(
                    (RecommendedProduct product) => _RecommendationTile(
                      product: product,
                      isAdmin: isAdmin,
                    ),
                  ),
                ],
                if (data.belts.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, data.bags.isNotEmpty ? 16 : 16, 16, 8),
                    child: Text(
                      'Preporučeni kaiševi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...data.belts.map(
                    (RecommendedProduct product) => _RecommendationTile(
                      product: product,
                      isAdmin: isAdmin,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecommendationTile extends ConsumerWidget {
  const _RecommendationTile({required this.product, required this.isAdmin});

  final RecommendedProduct product;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _Thumb(displayUrl: product.displayImageUrl),
        title: Text(product.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (product.description.isNotEmpty)
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    product.isPersonalized ? 'Personalizirano' : 'Popularno',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: product.isPersonalized
                      ? colors.primaryContainer
                      : colors.secondaryContainer,
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.star, size: 14, color: colors.primary),
                  label: Text(
                    product.score.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            if (product.reason.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                product.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: isAdmin
            ? null
            : IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: 'Dodaj u korpu',
                onPressed: () async {
                  if (product.isBag) {
                    await ref.read(cartProvider.notifier).addBagToCart(
                          bagId: product.productId,
                        );
                  } else {
                    await ref.read(cartProvider.notifier).addBeltToCart(
                          beltId: product.productId,
                        );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Artikal dodan u korpu'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
        onTap: () {
          if (product.isBag) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BagDetailScreen(id: product.productId),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BeltDetailScreen(id: product.productId),
              ),
            );
          }
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.displayUrl});

  final String? displayUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = displayUrl;
    if (url == null || url.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.image_not_supported_outlined));
    }
    if (url.startsWith('data:image')) {
      try {
        final String base64Part = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return CircleAvatar(backgroundImage: MemoryImage(bytes));
      } catch (_) {
        return const CircleAvatar(child: Icon(Icons.broken_image_outlined));
      }
    }
    return CircleAvatar(backgroundImage: NetworkImage(url));
  }
}
