import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../belts/application/belts_provider.dart';
import '../../belts/application/belt_types_provider.dart';
import '../../belts/domain/belt.dart';
import '../../belts/domain/belt_type.dart';
import '../../belts/presentation/belts_detail_screen.dart';
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
                      return _ProductCard(
                        belt: belt,
                        onTap: () => _navigateToDetail(belt),
                        onAddToCart: () => _addToCart(belt),
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
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final int? selectedBeltTypeId;
  final ValueChanged<int?> onBeltTypeChanged;
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
                          'Kaisevi Shop',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pronađite savršen kais za sebe',
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
                        hintText: 'Pretraži kaiseve...',
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
    required this.onTap,
    required this.onAddToCart,
  });

  final Belt belt;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

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
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: widget.onAddToCart,
                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('Kupi'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 36),
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
