import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';
import '../../outfit_ideas/presentation/outfit_idea_screen.dart';

/// Lookbook detalj – prikaz torbe s mogućnošću otvaranja Outfit ideje i (za admine) uređivanja.
class LookbookDetailScreen extends ConsumerStatefulWidget {
  const LookbookDetailScreen({super.key, required this.bagId});

  final int bagId;

  @override
  ConsumerState<LookbookDetailScreen> createState() => _LookbookDetailScreenState();
}

class _LookbookDetailScreenState extends ConsumerState<LookbookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bagDetailProvider.notifier).fetch(widget.bagId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider);

    return Scaffold(
      body: bagAsync.when(
        data: (Bag bag) => _LookbookDetailContent(
          bag: bag,
          onOpenOutfitIdea: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OutfitIdeaScreen(
                  bagId: bag.id,
                  bagName: bag.name,
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(
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
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(bagDetailProvider.notifier).fetch(widget.bagId),
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
    required this.onOpenOutfitIdea,
  });

  final Bag bag;
  final VoidCallback onOpenOutfitIdea;

  static Widget _buildBagImage(String? imageUrl, ColorScheme colorScheme) {
    final Widget placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image, size: 64)),
    );
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Part = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Part);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return placeholder;
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String? imageUrl = bag.displayImageUrl;

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Nazad',
          ),
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
                _buildBagImage(imageUrl, colorScheme),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.style_outlined,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Outfit ideja',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inspiracija kako stilizovati ${bag.name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onOpenOutfitIdea,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Otvori outfit ideju'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
