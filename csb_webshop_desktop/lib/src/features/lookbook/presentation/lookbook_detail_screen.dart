import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';

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
    Future.microtask(() {
      ref.read(bagDetailProvider.notifier).fetch(widget.bagId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider);

    return BackConfirmationWrapper(
      child: Scaffold(
      body: bagAsync.when(
        data: (Bag bag) => _LookbookDetailContent(bag: bag),
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
                  onPressed: () => ref.read(bagDetailProvider.notifier).fetch(widget.bagId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _LookbookDetailContent extends StatelessWidget {
  const _LookbookDetailContent({required this.bag});

  final Bag bag;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = bag.displayImageUrl;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: <Widget>[
        // Hero image with app bar
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          leading: Builder(
            builder: (BuildContext context) => buildBackButtonWithConfirmation(context),
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
            background: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.image, size: 64)),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.image, size: 64)),
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
                // Title section
                Text(
                  'How to style',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  bag.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Price tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${bag.price.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                if (bag.description.isNotEmpty) ...<Widget>[
                  Text(
                    'Opis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bag.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],

                // Styling tips section
                _StylingTipsSection(bag: bag),

                const SizedBox(height: 24),

                // Occasions section
                _OccasionsSection(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StylingTipsSection extends StatelessWidget {
  const _StylingTipsSection({required this.bag});

  final Bag bag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<_StylingTip> tips = <_StylingTip>[
      _StylingTip(
        icon: Icons.checkroom,
        title: 'Casual look',
        description: 'Kombinirajte ${bag.name} sa trapericama i bijelom majicom za opušten dnevni izgled.',
      ),
      _StylingTip(
        icon: Icons.business_center,
        title: 'Poslovni stil',
        description: 'Savršena za ured - nosite uz blazer i elegantne hlače.',
      ),
      _StylingTip(
        icon: Icons.nightlife,
        title: 'Večernji izlazak',
        description: 'Dodajte malo glamura svojoj večernjoj odjeći sa ovom torbicom.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.auto_awesome, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Savjeti za stiliziranje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tips.map((_StylingTip tip) => _StylingTipCard(tip: tip)),
      ],
    );
  }
}

class _StylingTip {
  const _StylingTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _StylingTipCard extends StatelessWidget {
  const _StylingTipCard({required this.tip});

  final _StylingTip tip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tip.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    tip.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.description,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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

class _OccasionsSection extends StatelessWidget {
  const _OccasionsSection();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<String> occasions = <String>[
      'Dnevni izlasci',
      'Posao',
      'Shopping',
      'Putovanja',
      'Večernji eventi',
      'Vikend',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.event, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Prilike za nošenje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: occasions.map((String occasion) {
            return Chip(
              label: Text(occasion),
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
            );
          }).toList(),
        ),
      ],
    );
  }
}
