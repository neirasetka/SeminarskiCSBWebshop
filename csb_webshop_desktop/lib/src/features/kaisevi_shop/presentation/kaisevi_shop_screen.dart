import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/application/belt_types_provider.dart';
import '../../belts/domain/belt.dart';
import '../../belts/domain/belt_type.dart';
import '../../belts/presentation/belts_detail_screen.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';

class KaiseviShopScreen extends ConsumerStatefulWidget {
  const KaiseviShopScreen({super.key});

  @override
  ConsumerState<KaiseviShopScreen> createState() => _KaiseviShopScreenState();
}

class _KaiseviShopScreenState extends ConsumerState<KaiseviShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBeltTypeId;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(beltsListProvider.notifier)
        .refresh(beltTypeId: _selectedBeltTypeId, query: _searchController.text.trim());
  }

  List<Belt> _sortBelts(List<Belt> belts) {
    final List<Belt> sorted = List<Belt>.from(belts);
    sorted.sort((Belt a, Belt b) {
      int result;
      switch (_sortBy) {
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'rating':
          final double ratingA = a.averageRating ?? 0;
          final double ratingB = b.averageRating ?? 0;
          result = ratingA.compareTo(ratingB);
          break;
        case 'name':
        default:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Belt>> beltsAsync = ref.watch(beltsListProvider);
    final AsyncValue<Set<int>> beltFavoritesAsync = ref.watch(beltFavoritesProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).value ?? false;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: <Widget>[
          // Hero header
          SliverToBoxAdapter(
            child: _ShopHeader(
              searchController: _searchController,
              onSearch: _onRefresh,
              selectedBeltTypeId: _selectedBeltTypeId,
              onBeltTypeChanged: (int? value) {
                setState(() => _selectedBeltTypeId = value);
                _onRefresh();
              },
              sortBy: _sortBy,
              sortAscending: _sortAscending,
              onSortChanged: (String sort, bool ascending) {
                setState(() {
                  _sortBy = sort;
                  _sortAscending = ascending;
                });
              },
              onBackPressed: () => context.go('/'),
            ),
          ),
          // Products grid
          beltsAsync.when(
            data: (List<Belt> belts) {
              if (belts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.straighten,
                          size: 80,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nema dostupnih kaiseva',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pokušajte promijeniti filter ili pretražiti',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final List<Belt> sortedBelts = _sortBelts(belts);
              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final Belt belt = sortedBelts[index];
                      final bool isFav = beltFavoritesAsync.value?.contains(belt.id) ?? false;
                      return _ProductCard(
                        belt: belt,
                        isFavorite: isFav,
                        showFavorite: !isAdmin,
                        showAddToCart: !isAdmin,
                        showDelete: isAdmin,
                        onTap: () => _navigateToDetail(belt),
                        onToggleFavorite: () =>
                            ref.read(beltFavoritesProvider.notifier).toggleBelt(belt.id),
                        onAddToCart: () => _addToCart(belt),
                        onBuyNow: () => _buyNow(belt),
                        onDelete: isAdmin ? () => _deleteBelt(this.context, ref, belt) : null,
                      );
                    },
                    childCount: sortedBelts.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace st) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                    const SizedBox(height: 16),
                    const Text('Greška pri učitavanju'),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: TextStyle(color: colorScheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovno'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Belt belt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BeltDetailScreen(id: belt.id),
      ),
    );
  }

  Future<void> _deleteBelt(BuildContext context, WidgetRef ref, Belt belt) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Obriši kaiš'),
        content: Text(
          'Da li ste sigurni da želite obrisati "${belt.name}"?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(beltsListProvider.notifier).remove(belt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${belt.name} je obrisan')),
        );
      }
    }
  }

  Future<void> _addToCart(Belt belt) async {
    await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${belt.name} dodano u korpu')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'NARUČI',
            textColor: Colors.white,
            onPressed: () {
              context.go('/checkout');
            },
          ),
        ),
      );
    }
  }

  Future<void> _buyNow(Belt belt) async {
    await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
    if (mounted) {
      context.go('/checkout');
    }
  }
}

class _ShopHeader extends ConsumerWidget {
  const _ShopHeader({
    required this.searchController,
    required this.onSearch,
    required this.selectedBeltTypeId,
    required this.onBeltTypeChanged,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onBackPressed,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final int? selectedBeltTypeId;
  final ValueChanged<int?> onBeltTypeChanged;
  final String sortBy;
  final bool sortAscending;
  final void Function(String, bool) onSortChanged;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Back button row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onBackPressed,
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Nazad na početnu',
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Title section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.straighten,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kaiševi',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pronađite savršen kaiš za sebe',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search and filters
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: <Widget>[
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži kaiševe...',
                        prefixIcon: Icon(Icons.search, color: colorScheme.outline),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.tune, color: colorScheme.primary),
                          onPressed: onSearch,
                          tooltip: 'Pretraži',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => onSearch(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filters row
                  Row(
                    children: <Widget>[
                      Expanded(child: _BeltTypeChips(
                        selectedId: selectedBeltTypeId,
                        onChanged: onBeltTypeChanged,
                      )),
                      const SizedBox(width: 12),
                      _SortButton(
                        sortBy: sortBy,
                        sortAscending: sortAscending,
                        onSortChanged: onSortChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeltTypeChips extends ConsumerWidget {
  const _BeltTypeChips({
    required this.selectedId,
    required this.onChanged,
  });

  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BeltType>> typesAsync = ref.watch(beltTypesProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return typesAsync.when(
      data: (List<BeltType> types) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              FilterChip(
                selected: selectedId == null,
                label: const Text('Sve'),
                onSelected: (_) => onChanged(null),
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              ...types.map((BeltType t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selectedId == t.id,
                      label: Text(t.name),
                      onSelected: (_) => onChanged(selectedId == t.id ? null : t.id),
                      backgroundColor: colorScheme.surface,
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.primary,
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (Object e, StackTrace st) => const SizedBox.shrink(),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
  });

  final String sortBy;
  final bool sortAscending;
  final void Function(String, bool) onSortChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Sortiraj',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.sort, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _sortLabel,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
      onSelected: (String value) {
        if (value == sortBy) {
          onSortChanged(sortBy, !sortAscending);
        } else {
          onSortChanged(value, true);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'name',
          child: Row(
            children: <Widget>[
              Icon(sortBy == 'name' ? Icons.check : Icons.abc, size: 20),
              const SizedBox(width: 8),
              const Text('Po nazivu'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'price',
          child: Row(
            children: <Widget>[
              Icon(sortBy == 'price' ? Icons.check : Icons.attach_money, size: 20),
              const SizedBox(width: 8),
              const Text('Po cijeni'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rating',
          child: Row(
            children: <Widget>[
              Icon(sortBy == 'rating' ? Icons.check : Icons.star_outline, size: 20),
              const SizedBox(width: 8),
              const Text('Po ocjeni'),
            ],
          ),
        ),
      ],
    );
  }

  String get _sortLabel {
    switch (sortBy) {
      case 'price':
        return 'Cijena';
      case 'rating':
        return 'Ocjena';
      case 'name':
      default:
        return 'Naziv';
    }
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.belt,
    required this.isFavorite,
    required this.showFavorite,
    required this.showAddToCart,
    required this.showDelete,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onBuyNow,
    this.onDelete,
  });

  final Belt belt;
  final bool isFavorite;
  final bool showFavorite;
  final bool showAddToCart;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback? onDelete;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
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
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          elevation: _isHovered ? 12 : 4,
          shadowColor: colorScheme.primary.withValues(alpha: 0.2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Image section
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: _ProductImage(imageUrl: widget.belt.displayImageUrl),
                      ),
                      // Favorite button (samo za buyere, ne za admine)
                      if (widget.showFavorite)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _FavoriteButton(
                            isFavorite: widget.isFavorite,
                            onPressed: widget.onToggleFavorite,
                          ),
                        ),
                      // Delete button (samo za admine) - ikonica kante u gornjem desnom uglu
                      if (widget.showDelete && widget.onDelete != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _DeleteButton(onPressed: widget.onDelete!),
                        ),
                      // Rating badge
                      if (widget.belt.averageRating != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  widget.belt.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.belt.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.belt.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Text(
                              '${widget.belt.price.toStringAsFixed(2)} KM',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (widget.showAddToCart) ...[
                              const Spacer(),
                              // Add to cart icon button (sakriveno za admine)
                              IconButton(
                                onPressed: widget.onAddToCart,
                                icon: const Icon(Icons.add_shopping_cart, size: 20),
                                tooltip: 'Dodaj u korpu',
                                style: IconButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Buy now button (sakriveno za admine)
                              FilledButton(
                                onPressed: widget.onBuyNow,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  minimumSize: const Size(0, 36),
                                  backgroundColor: Colors.green.shade600,
                                ),
                                child: const Text('Kupi'),
                              ),
                            ],
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.straighten,
          size: 64,
          color: colorScheme.outline,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    // Support data URLs (base64 image) in addition to regular network URLs.
    if (imageUrl!.startsWith('data:image')) {
      try {
        final String base64Part = imageUrl!.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return placeholder;
      }
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
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
            size: 20,
          ),
        ),
      ),
    );
  }
}
