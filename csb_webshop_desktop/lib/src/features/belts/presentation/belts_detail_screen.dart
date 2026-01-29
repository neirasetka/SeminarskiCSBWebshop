import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/belts_provider.dart';
import '../application/belt_types_provider.dart';
import '../domain/belt.dart';
import '../domain/belt_type.dart';
import '../../orders/application/cart_provider.dart';
import '../../favorites/application/favorites_provider.dart';

class BeltDetailScreen extends ConsumerStatefulWidget {
  const BeltDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BeltDetailScreen> createState() => _BeltDetailScreenState();
}

class _BeltDetailScreenState extends ConsumerState<BeltDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beltDetailProvider.notifier).fetch(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Belt> beltAsync = ref.watch(beltDetailProvider);
    final AsyncValue<List<BeltType>> beltTypesAsync = ref.watch(beltTypesProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return BackConfirmationWrapper(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: beltAsync.when(
          data: (Belt belt) {
            final String? beltTypeName = beltTypesAsync.value
                ?.where((BeltType t) => t.id == belt.beltTypeId)
                .map((BeltType t) => t.name)
                .firstOrNull;

            return _CustomerBeltDetailBody(
              belt: belt,
              beltTypeName: beltTypeName,
              quantity: _quantity,
              onQuantityChanged: (int qty) => setState(() => _quantity = qty),
              onAddToCart: () async {
                for (int i = 0; i < _quantity; i++) {
                  await ref
                      .read(cartProvider.notifier)
                      .addBeltToCart(beltId: belt.id, price: belt.price);
                }
                if (context.mounted) {
                  _showAddedToCartDialog(context, belt);
                }
              },
              onBack: () => Navigator.of(context).pop(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.error_outline,
                      size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Greška pri učitavanju detalja',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(e.toString(),
                      style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(beltDetailProvider.notifier).fetch(widget.id),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovno'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddedToCartDialog(BuildContext context, Belt belt) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  size: 48, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Dodano u korpu!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_quantity x ${belt.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(belt.price * _quantity).toStringAsFixed(2)} KM',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nastavi kupovinu'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/checkout');
            },
            child: const Text('Idi na plaćanje'),
          ),
        ],
      ),
    );
  }
}

class _CustomerBeltDetailBody extends StatelessWidget {
  const _CustomerBeltDetailBody({
    required this.belt,
    required this.beltTypeName,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onBack,
  });

  final Belt belt;
  final String? beltTypeName;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

    return CustomScrollView(
      slivers: <Widget>[
        // Custom App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: onBack,
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 24,
              vertical: 16,
            ),
            child: isWide
                ? _WideLayout(
                    belt: belt,
                    beltTypeName: beltTypeName,
                    quantity: quantity,
                    onQuantityChanged: onQuantityChanged,
                    onAddToCart: onAddToCart,
                  )
                : _NarrowLayout(
                    belt: belt,
                    beltTypeName: beltTypeName,
                    quantity: quantity,
                    onQuantityChanged: onQuantityChanged,
                    onAddToCart: onAddToCart,
                  ),
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.belt,
    required this.beltTypeName,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final Belt belt;
  final String? beltTypeName;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left side - Image
        Expanded(
          flex: 5,
          child: _ProductImageGallery(imageUrl: belt.displayImageUrl),
        ),
        const SizedBox(width: 48),
        // Right side - Details
        Expanded(
          flex: 4,
          child: _ProductDetails(
            belt: belt,
            beltTypeName: beltTypeName,
            quantity: quantity,
            onQuantityChanged: onQuantityChanged,
            onAddToCart: onAddToCart,
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.belt,
    required this.beltTypeName,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final Belt belt;
  final String? beltTypeName;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProductImageGallery(imageUrl: belt.displayImageUrl),
        const SizedBox(height: 24),
        _ProductDetails(
          belt: belt,
          beltTypeName: beltTypeName,
          quantity: quantity,
          onQuantityChanged: onQuantityChanged,
          onAddToCart: onAddToCart,
        ),
      ],
    );
  }
}

class _ProductImageGallery extends StatelessWidget {
  const _ProductImageGallery({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget placeholder = Container(
      height: 450,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.straighten, size: 80, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Slika nije dostupna',
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl!,
          height: 450,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return Container(
              height: 450,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.belt,
    required this.beltTypeName,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final Belt belt;
  final String? beltTypeName;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Category badge
        if (beltTypeName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              beltTypeName!,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Product name
        Text(
          belt.name,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Rating
        if (belt.averageRating != null) ...<Widget>[
          Row(
            children: <Widget>[
              ...List<Widget>.generate(5, (int index) {
                final double rating = belt.averageRating!;
                if (index < rating.floor()) {
                  return const Icon(Icons.star, color: Colors.amber, size: 24);
                } else if (index < rating) {
                  return const Icon(Icons.star_half,
                      color: Colors.amber, size: 24);
                }
                return Icon(Icons.star_border,
                    color: Colors.amber.shade200, size: 24);
              }),
              const SizedBox(width: 8),
              Text(
                belt.averageRating!.toStringAsFixed(1),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${belt.price.toStringAsFixed(2)} KM',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Divider
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 24),

        // Product details
        Text(
          'Detalji proizvoda',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          icon: Icons.qr_code,
          label: 'Šifra',
          value: belt.code ?? 'N/A',
        ),
        if (beltTypeName != null)
          _DetailRow(
            icon: Icons.category,
            label: 'Kategorija',
            value: beltTypeName!,
          ),
        const SizedBox(height: 24),

        // Description
        Text(
          'Opis',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          belt.description.isNotEmpty ? belt.description : 'Nema opisa.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Quantity selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              Text(
                'Količina:',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _QuantitySelector(
                quantity: quantity,
                onChanged: onQuantityChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Add to cart button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onAddToCart,
            icon: const Icon(Icons.add_shopping_cart, size: 24),
            label: Text(
              'Dodaj u korpu  -  ${(belt.price * quantity).toStringAsFixed(2)} KM',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: colorScheme.outline),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colorScheme.outline),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            color: colorScheme.primary,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: quantity < 99 ? () => onChanged(quantity + 1) : null,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

