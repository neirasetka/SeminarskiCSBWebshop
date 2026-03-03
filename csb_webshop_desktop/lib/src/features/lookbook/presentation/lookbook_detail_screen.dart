import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/back_confirmation_dialog.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/presentation/bag_form_screen.dart';
import '../../outfit_ideas/application/outfit_ideas_provider.dart';
import '../../outfit_ideas/domain/outfit_idea.dart';

class LookbookDetailScreen extends ConsumerStatefulWidget {
  const LookbookDetailScreen({super.key, required this.bagId});

  final int bagId;

  @override
  ConsumerState<LookbookDetailScreen> createState() => _LookbookDetailScreenState();
}

class _LookbookDetailScreenState extends ConsumerState<LookbookDetailScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    ref.invalidate(bagDetailProvider(widget.bagId));
    await ref.read(outfitIdeasForBagProvider.notifier).loadForBag(widget.bagId);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _openEditBag(Bag bag) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BagFormScreen(existing: bag),
      ),
    );
    if (saved == true && mounted) {
      await _loadData();
    }
  }

  void _showImagePreview(OutfitIdeaImage image) {
    if (image.imageBytes == null || image.imageBytes!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    Uint8List.fromList(image.imageBytes!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider(widget.bagId));
    final OutfitIdeasListState outfitState = ref.watch(outfitIdeasForBagProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).value ?? false;

    return Scaffold(
        body: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : bagAsync.when(
                data: (Bag bag) => _LookbookDetailContent(
                  bag: bag,
                  outfitState: outfitState,
                  onImageTap: _showImagePreview,
                  onRefresh: _loadData,
                  isAdmin: isAdmin,
                  onEditBag: () => _openEditBag(bag),
                  onOpenOutfitIdea: () => context.push('/bags/${bag.id}/outfit-idea'),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Greška pri učitavanju',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(error.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _LookbookDetailContent extends StatelessWidget {
  const _LookbookDetailContent({
    required this.bag,
    required this.outfitState,
    required this.onImageTap,
    required this.onRefresh,
    this.isAdmin = false,
    this.onEditBag,
    this.onOpenOutfitIdea,
  });

  final Bag bag;
  final OutfitIdeasListState outfitState;
  final void Function(OutfitIdeaImage) onImageTap;
  final VoidCallback onRefresh;
  final bool isAdmin;
  final VoidCallback? onEditBag;
  final VoidCallback? onOpenOutfitIdea;

  static Widget _buildBagImage(String imageUrl, ColorScheme colorScheme) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Part = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Part);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image, size: 64)),
        );
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image, size: 64)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = bag.displayImageUrl;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<OutfitIdeaImage> images = outfitState.allImages;

    return CustomScrollView(
      slivers: <Widget>[
        // Hero image with app bar
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          leading: Builder(
            builder: (BuildContext context) => buildBackButtonWithConfirmation(context),
          ),
          actions: <Widget>[
            if (isAdmin && onEditBag != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: onEditBag,
                tooltip: 'Uredi torbu (slika, podaci)',
              ),
            if (isAdmin && onOpenOutfitIdea != null)
              IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                onPressed: onOpenOutfitIdea,
                tooltip: 'Outfit ideja – dodaj slike',
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              bag.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: <Shadow>[
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                imageUrl != null && imageUrl.isNotEmpty
                    ? _buildBagImage(imageUrl, colorScheme)
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.image, size: 64)),
                      ),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Title section - "Outfit ideja"
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Outfit ideja',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inspiracija kako stilizovati ${bag.name}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Outfit inspiration images section
                _OutfitImagesSection(
                  bagId: bag.id,
                  images: images,
                  isLoading: outfitState.isLoading,
                  error: outfitState.error,
                  onImageTap: onImageTap,
                  onRefresh: onRefresh,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutfitImagesSection extends StatelessWidget {
  const _OutfitImagesSection({
    required this.bagId,
    required this.images,
    required this.isLoading,
    required this.error,
    required this.onImageTap,
    required this.onRefresh,
  });

  final int bagId;
  final List<OutfitIdeaImage> images;
  final bool isLoading;
  final String? error;
  final void Function(OutfitIdeaImage) onImageTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Loading state
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Greška pri učitavanju slika',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (images.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.image_outlined,
                size: 80,
                color: colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Nema outfit inspiracija',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspiracije za stilizovanje ove torbice još nisu dodane.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/bags/$bagId/outfit-idea'),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Dodaj inspiracije'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Images grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.style, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Inspiracije za stilizovanje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${images.length} ${images.length == 1 ? 'slika' : 'slika'}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Responsive grid: 2 columns on smaller screens, 3 on larger
            final int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: images.length,
              itemBuilder: (BuildContext context, int index) {
                final OutfitIdeaImage image = images[index];
                return _OutfitImageCard(
                  image: image,
                  onTap: () => onImageTap(image),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _OutfitImageCard extends StatefulWidget {
  const _OutfitImageCard({
    required this.image,
    required this.onTap,
  });

  final OutfitIdeaImage image;
  final VoidCallback onTap;

  @override
  State<_OutfitImageCard> createState() => _OutfitImageCardState();
}

class _OutfitImageCardState extends State<_OutfitImageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.image.imageBytes != null && widget.image.imageBytes!.isNotEmpty;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _isHovered ? 8 : 2,
          shadowColor: colorScheme.shadow.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                hasImage
                    ? Image.memory(
                        Uint8List.fromList(widget.image.imageBytes!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                      )
                    : _buildPlaceholder(colorScheme),
                // Hover overlay
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.zoom_in,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // Caption at bottom
                if (widget.image.caption != null && widget.image.caption!.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.image.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.image,
              size: 40,
              color: colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Slika nije dostupna',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
