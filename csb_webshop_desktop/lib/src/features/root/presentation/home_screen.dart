import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../bags/domain/bag.dart';
import '../../belts/domain/belt.dart';
import '../../recommendations/application/recommendations_provider.dart';
import 'info_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Check if user is admin
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    final bool isAdmin = isAdminAsync.value ?? false;

    // Base shortcuts for all users
    final List<_NavShortcut> shortcuts = <_NavShortcut>[
      const _NavShortcut(icon: Icons.shopping_bag, label: 'Torbice', route: '/torbice'),
      const _NavShortcut(icon: Icons.straighten, label: 'Kaisevi', route: '/kaisevi'),
      const _NavShortcut(icon: Icons.grid_view_outlined, label: 'Lookbook', route: '/lookbook'),
      const _NavShortcut(icon: Icons.card_giftcard, label: 'Giveaway', route: '/giveaways'),
      // Korpa samo za buyere, ne za admine
      if (!isAdmin) const _NavShortcut(icon: Icons.shopping_cart, label: 'Korpa', route: '/checkout'),
      // Admin-only shortcuts
      if (isAdmin) const _NavShortcut(icon: Icons.campaign, label: 'Announcement', route: '/announcement/new'),
      if (isAdmin) const _NavShortcut(icon: Icons.insights_outlined, label: 'Reports', route: '/reports'),
    ];

    final authState = ref.watch(authControllerProvider);
    final bool isLoggedIn = authState.value?.userId != null && authState.value!.userId! > 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Meni kružići na vrhu
                _HomeHeader(shortcuts: shortcuts),
                const SizedBox(height: 20),
                // Natpis Dobrodošli – manja veličina slova
                Text(
                  'Dobrodošli na CocoSunBags Webshop',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Torbica na sredini ispod natpisa
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const AspectRatio(
                      aspectRatio: 400 / 260,
                      child: _HeroBagImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // For You – ispod torbice, samo za prijavljene
                if (isLoggedIn) ...<Widget>[
                  const SizedBox(height: 280, child: _ForYouSection()),
                  const SizedBox(height: 24),
                ],
                // Info panel ispod For You
                const InfoPanel(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// For You recommendations section showing personalized product suggestions.
class _ForYouSection extends ConsumerWidget {
  const _ForYouSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<Recommendations> recommendationsAsync = ref.watch(recommendationsProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.recommend, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'For You',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh recommendations',
                  onPressed: () {
                    ref.read(recommendationsProvider.notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Products recommended just for you based on your favorites',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: recommendationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load recommendations',
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(recommendationsProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
                data: (Recommendations recommendations) {
                  if (recommendations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recommendations yet',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some bags or belts to your favorites\nto get personalized recommendations!',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () => context.go('/torbice'),
                                icon: const Icon(Icons.shopping_bag),
                                label: const Text('Browse Bags'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => context.go('/kaisevi'),
                                icon: const Icon(Icons.straighten),
                                label: const Text('Browse Belts'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return _RecommendationsGrid(recommendations: recommendations);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid displaying recommended products.
class _RecommendationsGrid extends StatelessWidget {
  const _RecommendationsGrid({required this.recommendations});

  final Recommendations recommendations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Recommended Bags Section
          if (recommendations.bags.isNotEmpty) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.shopping_bag, size: 20, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Recommended Bags',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.bags.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Bag bag = recommendations.bags[index];
                  return _ProductCard(
                    name: bag.name,
                    price: bag.price,
                    imageUrl: bag.displayImageUrl,
                    onTap: () => context.go('/torbice/${bag.id}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Recommended Belts Section
          if (recommendations.belts.isNotEmpty) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.straighten, size: 20, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Recommended Belts',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.belts.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Belt belt = recommendations.belts[index];
                  return _ProductCard(
                    name: belt.name,
                    price: belt.price,
                    imageUrl: belt.displayImageUrl,
                    onTap: () => context.go('/kaisevi/${belt.id}'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual product card in the recommendations grid.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.price,
    this.imageUrl,
    required this.onTap,
  });

  final String name;
  final double price;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: colorScheme.surfaceContainerLow,
                child: _buildImage(colorScheme),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toStringAsFixed(2)} KM',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: colorScheme.outline,
        ),
      );
    }

    // Handle base64 images
    if (imageUrl!.startsWith('data:image')) {
      try {
        final String base64Data = imageUrl!.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
              Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: colorScheme.outline,
                ),
              ),
        );
      } catch (_) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: colorScheme.outline,
          ),
        );
      }
    }

    // Handle network images
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: colorScheme.outline,
            ),
          ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.shortcuts});

  final List<_NavShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceEvenly,
      runAlignment: WrapAlignment.center,
      children: shortcuts
          .map((shortcut) => _NavShortcutButton(shortcut: shortcut))
          .toList(),
    );
  }
}

/// Hero slika torbice iste visine kao info panel, lijevo u redu.
class _HeroBagImage extends StatelessWidget {
  const _HeroBagImage();

  static const String _bagImageUrl =
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=800&q=80';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        _bagImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Center(
          child: Icon(
            Icons.shopping_bag,
            color: colorScheme.primary,
            size: 120,
          ),
        ),
      ),
    );
  }
}

class _NavShortcutButton extends StatelessWidget {
  const _NavShortcutButton({required this.shortcut});

  final _NavShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Material(
          color: colorScheme.primary.withOpacity(0.08),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: shortcut.label,
            iconSize: 36,
            icon: Icon(shortcut.icon, color: colorScheme.primary),
            onPressed: () => context.go(shortcut.route),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(20),
              minimumSize: const Size(64, 64),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          shortcut.label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _NavShortcut {
  const _NavShortcut({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}
