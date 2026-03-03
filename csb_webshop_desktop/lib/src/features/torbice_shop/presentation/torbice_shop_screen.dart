import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/domain/bag_type.dart';
import '../../bags/presentation/bag_form_screen.dart';
import '../../bags/presentation/bags_detail_screen.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';

class TorbiceShopScreen extends ConsumerStatefulWidget {
  const TorbiceShopScreen({super.key});

  @override
  ConsumerState<TorbiceShopScreen> createState() => _TorbiceShopScreenState();
}

class _TorbiceShopScreenState extends ConsumerState<TorbiceShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBagTypeId;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(bagsListProvider.notifier)
        .refresh(bagTypeId: _selectedBagTypeId, query: _searchController.text.trim());
  }

  Future<void> _openBagForm(BuildContext context) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BagFormScreen(),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Torba dodana')),
      );
      _onRefresh();
    }
  }

  List<Bag> _sortBags(List<Bag> bags) {
    final List<Bag> sorted = List<Bag>.from(bags);
    sorted.sort((Bag a, Bag b) {
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
    final AsyncValue<List<Bag>> bagsAsync = ref.watch(bagsListProvider);
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).value ?? false;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openBagForm(context),
              tooltip: 'Dodaj torbicu',
              child: const Icon(Icons.add),
            )
          : null,
      body: CustomScrollView(
        slivers: <Widget>[
          // Hero header
          SliverToBoxAdapter(
            child: _ShopHeader(
              searchController: _searchController,
              onSearch: _onRefresh,
              selectedBagTypeId: _selectedBagTypeId,
              onBagTypeChanged: (int? value) {
                setState(() => _selectedBagTypeId = value);
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
            ),
          ),
          // Products grid
          bagsAsync.when(
            data: (List<Bag> bags) {
              if (bags.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nema dostupnih torbica',
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
              final List<Bag> sortedBags = _sortBags(bags);
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
                      final Bag bag = sortedBags[index];
                      final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
                      return _ProductCard(
                        bag: bag,
                        isFavorite: isFav,
                        showFavorite: !isAdmin,
                        showAddToCart: !isAdmin,
                        showDelete: isAdmin,
                        onTap: () => _navigateToDetail(bag),
                        onToggleFavorite: () =>
                            ref.read(favoritesProvider.notifier).toggleBag(bag.id),
                        onAddToCart: () => _addToCart(bag),
                        onDelete: isAdmin ? () => _deleteBag(context, ref, bag) : null,
                      );
                    },
                    childCount: sortedBags.length,
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

  void _navigateToDetail(Bag bag) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BagDetailScreen(id: bag.id),
      ),
    );
  }

  Future<void> _deleteBag(BuildContext context, WidgetRef ref, Bag bag) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Obriši torbicu'),
        content: Text(
          'Da li ste sigurni da želite obrisati "${bag.name}"?',
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
      await ref.read(bagsListProvider.notifier).remove(bag.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bag.name} je obrisana')),
        );
      }
    }
  }

  Future<void> _addToCart(Bag bag) async {
    try {
      await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Artikal uspješno dodan u korpu')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'NARUČI',
            textColor: Colors.white,
            onPressed: () {
              context.go('/cart');
            },
          ),
        ),
      );
      }
    } catch (e, st) {
      final String displayMsg = ApiException.formatForDisplay(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $displayMsg'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (e is ApiException && e.rawBody != null) {
        debugPrint('Add to cart API error [${e.statusCode}]: ${e.rawBody}\n$st');
      } else {
        debugPrint('Add to cart error: $e\n$st');
      }
    }
  }
}

class _ShopHeader extends ConsumerWidget {
  const _ShopHeader({
    required this.searchController,
    required this.onSearch,
    required this.selectedBagTypeId,
    required this.onBagTypeChanged,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final int? selectedBagTypeId;
  final ValueChanged<int?> onBagTypeChanged;
  final String sortBy;
  final bool sortAscending;
  final void Function(String, bool) onSortChanged;

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
            // Title section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Nazad',
                    onPressed: () => context.go('/'),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      Icons.shopping_bag,
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
                          'Torbice',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pronađite savršenu torbicu za sebe',
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
                        hintText: 'Pretraži torbice...',
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
                      Expanded(child: _BagTypeChips(
                        selectedId: selectedBagTypeId,
                        onChanged: onBagTypeChanged,
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

class _BagTypeChips extends ConsumerWidget {
  const _BagTypeChips({
    required this.selectedId,
    required this.onChanged,
  });

  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return typesAsync.when(
      data: (List<BagType> types) {
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
              ...types.map((BagType t) => Padding(
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
    required this.bag,
    required this.isFavorite,
    required this.showFavorite,
    required this.showAddToCart,
    required this.showDelete,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToCart,
    this.onDelete,
  });

  final Bag bag;
  final bool isFavorite;
  final bool showFavorite;
  final bool showAddToCart;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
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
                        child: _ProductImage(imageUrl: widget.bag.displayImageUrl),
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
                      if (widget.bag.averageRating != null)
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
                                  widget.bag.averageRating!.toStringAsFixed(1),
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
                          widget.bag.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bag.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                '${widget.bag.price.toStringAsFixed(2)} KM',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.showAddToCart) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: FilledButton.icon(
                                  onPressed: widget.onAddToCart,
                                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                                  label: const Text('Dodaj u korpu'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                ),
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
          Icons.shopping_bag_outlined,
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
