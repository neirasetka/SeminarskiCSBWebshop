import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../belts/domain/belt.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../orders/application/cart_provider.dart';
import '../application/recommendations_provider.dart';

/// Preporučeni proizvodi s backenda (za prijavljenog korisnika).
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
                    'Preporuke još nisu dostupne',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preporuke dolaze s poslužitelja na temelju omiljenih tipova proizvoda i '
                    'vaših ocjena (≥3) na računu. Ako ste favorite dodali samo u ovoj aplikaciji '
                    '(lokalno), poslužitelj ih još ne vidi — ocijenite proizvode ili koristite '
                    'istu prijavu i na webu.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: <Widget>[
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
                    (Bag bag) => _RecommendationBagTile(
                      bag: bag,
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
                    (Belt belt) => _RecommendationBeltTile(
                      belt: belt,
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

class _RecommendationBagTile extends ConsumerWidget {
  const _RecommendationBagTile({required this.bag, required this.isAdmin});

  final Bag bag;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _Thumb(displayUrl: bag.displayImageUrl),
      title: Text(bag.name),
      subtitle: Text(
        bag.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isAdmin
          ? null
          : IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Dodaj u korpu',
              onPressed: () async {
                await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BagDetailScreen(id: bag.id),
          ),
        );
      },
    );
  }
}

class _RecommendationBeltTile extends ConsumerWidget {
  const _RecommendationBeltTile({required this.belt, required this.isAdmin});

  final Belt belt;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _Thumb(displayUrl: belt.displayImageUrl),
      title: Text(belt.name),
      subtitle: Text(
        belt.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isAdmin
          ? null
          : IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Dodaj u korpu',
              onPressed: () async {
                await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BeltDetailScreen(id: belt.id),
          ),
        );
      },
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
