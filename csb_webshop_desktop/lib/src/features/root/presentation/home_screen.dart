import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bags/domain/bag.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../belts/domain/belt.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';
import '../../recommendations/application/recommendations_provider.dart';
import 'info_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    const List<_NavShortcut> shortcuts = <_NavShortcut>[
      _NavShortcut(icon: Icons.shopping_bag_outlined, label: 'Bags', route: '/bags'),
      _NavShortcut(icon: Icons.shopping_bag, label: 'Torbice', route: '/torbice'),
      _NavShortcut(icon: Icons.checkroom_outlined, label: 'Belts', route: '/belts'),
      _NavShortcut(icon: Icons.straighten, label: 'Kaisevi', route: '/kaisevi'),
      _NavShortcut(icon: Icons.grid_view_outlined, label: 'Lookbook', route: '/lookbook'),
      _NavShortcut(icon: Icons.card_giftcard, label: 'Giveaway', route: '/giveaways'),
      _NavShortcut(icon: Icons.shopping_cart, label: 'Korpa', route: '/checkout'),
      _NavShortcut(icon: Icons.insights_outlined, label: 'Reports', route: '/reports'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HomeHeader(shortcuts: shortcuts),
                const SizedBox(height: 24),
                // Main content area
                SizedBox(
                  height: 300,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Welcome message on the left
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'Welcome',
                            style: textTheme.displayLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Info Panel on the right
                      const Expanded(
                        flex: 1,
                        child: InfoPanel(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // For You section - Personalized recommendations
                const _ForYouSection(),
              ],
            ),
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _LogoBadge(),
        const Spacer(),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              runAlignment: WrapAlignment.end,
              children: shortcuts.map((_) => _NavShortcutButton(shortcut: _)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  static const String _logoImageUrl =
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=240&q=80';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _logoImageUrl,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => SizedBox(
              width: 140,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  color: colorScheme.primary,
                  size: 64,
                ),
              ),
            ),
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
            icon: Icon(shortcut.icon, color: colorScheme.primary),
            onPressed: () => context.go(shortcut.route),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shortcut.label,
          style: textTheme.labelMedium?.copyWith(
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

/// "For You" recommendation section using Content-Based Filtering
/// Recommends products similar to user's favorites
class _ForYouSection extends ConsumerWidget {
  const _ForYouSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecommendationsState> recommendationsAsync = ref.watch(recommendationsProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return recommendationsAsync.when(
      data: (RecommendationsState state) {
        if (state.isEmpty) {
          return _ForYouEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Section header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'For You',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Preporuke na osnovu vaših favorita',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.read(recommendationsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Osvježi preporuke',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recommended bags section
            if (state.bags.isNotEmpty) ...<Widget>[
              _RecommendationSubsection(
                title: 'Preporučene torbice',
                icon: Icons.shopping_bag,
                child: _RecommendedBagsGrid(bags: state.bags),
              ),
              const SizedBox(height: 24),
            ],
            // Recommended belts section
            if (state.belts.isNotEmpty)
              _RecommendationSubsection(
                title: 'Preporučeni kaisevi',
                icon: Icons.straighten,
                child: _RecommendedBeltsGrid(belts: state.belts),
              ),
          ],
        );
      },
      loading: () => const _ForYouLoadingState(),
      error: (Object e, StackTrace st) => _ForYouErrorState(
        error: e.toString(),
        onRetry: () => ref.read(recommendationsProvider.notifier).refresh(),
      ),
    );
  }
}

class _RecommendationSubsection extends StatelessWidget {
  const _RecommendationSubsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _RecommendedBagsGrid extends ConsumerWidget {
  const _RecommendedBagsGrid({required this.bags});

  final List<Bag> bags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          final Bag bag = bags[index];
          final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
          return _RecommendedBagCard(
            bag: bag,
            isFavorite: isFav,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => BagDetailScreen(id: bag.id),
              ),
            ),
            onToggleFavorite: () =>
                ref.read(favoritesProvider.notifier).toggleBag(bag.id),
            onAddToCart: () async {
              await ref.read(cartProvider.notifier).addBagToCart(
                    bagId: bag.id,
                    price: bag.price,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('${bag.name} dodano u korpu'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'KORPA',
                      textColor: Colors.white,
                      onPressed: () => context.go('/checkout'),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _RecommendedBeltsGrid extends ConsumerWidget {
  const _RecommendedBeltsGrid({required this.belts});

  final List<Belt> belts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(beltFavoritesProvider);

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: belts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          final Belt belt = belts[index];
          final bool isFav = favoritesAsync.value?.contains(belt.id) ?? false;
          return _RecommendedBeltCard(
            belt: belt,
            isFavorite: isFav,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => BeltDetailScreen(id: belt.id),
              ),
            ),
            onToggleFavorite: () =>
                ref.read(beltFavoritesProvider.notifier).toggleBelt(belt.id),
            onAddToCart: () async {
              await ref.read(cartProvider.notifier).addBeltToCart(
                    beltId: belt.id,
                    price: belt.price,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('${belt.name} dodano u korpu'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'KORPA',
                      textColor: Colors.white,
                      onPressed: () => context.go('/checkout'),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _RecommendedBagCard extends StatefulWidget {
  const _RecommendedBagCard({
    required this.bag,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  final Bag bag;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;

  @override
  State<_RecommendedBagCard> createState() => _RecommendedBagCardState();
}

class _RecommendedBagCardState extends State<_RecommendedBagCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        width: 220,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: _isHovered ? 8 : 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Image
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: _RecommendedProductImage(
                          imageUrl: widget.bag.displayImageUrl,
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _FavoriteButton(
                          isFavorite: widget.isFavorite,
                          onPressed: widget.onToggleFavorite,
                        ),
                      ),
                      // Rating badge
                      if (widget.bag.averageRating != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star, color: Colors.white, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  widget.bag.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.bag.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bag.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Text(
                              '${widget.bag.price.toStringAsFixed(2)} KM',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: widget.onAddToCart,
                              icon: Icon(
                                Icons.add_shopping_cart,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Dodaj u korpu',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
        ),
      ),
    );
  }
}

class _RecommendedBeltCard extends StatefulWidget {
  const _RecommendedBeltCard({
    required this.belt,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  final Belt belt;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;

  @override
  State<_RecommendedBeltCard> createState() => _RecommendedBeltCardState();
}

class _RecommendedBeltCardState extends State<_RecommendedBeltCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        width: 220,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: _isHovered ? 8 : 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Image
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: _RecommendedProductImage(
                          imageUrl: widget.belt.displayImageUrl,
                          icon: Icons.straighten,
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _FavoriteButton(
                          isFavorite: widget.isFavorite,
                          onPressed: widget.onToggleFavorite,
                        ),
                      ),
                      // Rating badge
                      if (widget.belt.averageRating != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star, color: Colors.white, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  widget.belt.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.belt.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.belt.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Text(
                              '${widget.belt.price.toStringAsFixed(2)} KM',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: widget.onAddToCart,
                              icon: Icon(
                                Icons.add_shopping_cart,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Dodaj u korpu',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
        ),
      ),
    );
  }
}

class _RecommendedProductImage extends StatelessWidget {
  const _RecommendedProductImage({this.imageUrl, required this.icon});

  final String? imageUrl;
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

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _ForYouEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Označite omiljene proizvode',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte torbice i kaiseve u favorite da biste dobili personalizirane preporuke.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => context.go('/torbice'),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Torbice'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/kaisevi'),
                icon: const Icon(Icons.straighten),
                label: const Text('Kaisevi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForYouLoadingState extends StatelessWidget {
  const _ForYouLoadingState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Učitavanje preporuka...',
            style: TextStyle(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ForYouErrorState extends StatelessWidget {
  const _ForYouErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Greška pri učitavanju preporuka',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovno'),
          ),
        ],
      ),
    );
  }
}
