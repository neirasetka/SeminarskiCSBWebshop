import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/domain/bag_type.dart';
import 'lookbook_detail_screen.dart';

class LookbookScreen extends ConsumerStatefulWidget {
  const LookbookScreen({super.key});

  @override
  ConsumerState<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends ConsumerState<LookbookScreen> {
  int? _selectedBagTypeId;

  Future<void> _onRefresh() async {
    await ref.read(bagsListProvider.notifier).refresh(
          bagTypeId: _selectedBagTypeId,
          query: ref.read(bagsListProvider.notifier).query,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Bag>> bagsAsync = ref.watch(bagsListProvider);
    final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lookbook'),
      ),
      body: Column(
        children: <Widget>[
          // Header - "How to style our bags"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.style_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kako stilizirati naše torbice',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klikni na torbicu za outfit inspiraciju',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                typesAsync.when(
                  data: (List<BagType> types) {
                    final List<DropdownMenuItem<int?>> items = <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(value: null, child: Text('Sve vrste')),
                      ...types.map((BagType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
                    ];
                    return DropdownButton<int?>(
                      value: _selectedBagTypeId,
                      items: items,
                      onChanged: (int? value) {
                        setState(() => _selectedBagTypeId = value);
                        _onRefresh();
                      },
                      hint: const Text('Vrsta'),
                    );
                  },
                  loading: () => const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (Object e, StackTrace st) => const SizedBox(),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: bagsAsync.when(
                data: (List<Bag> bags) {
                  if (bags.isEmpty) {
                    return const Center(child: Text('Nema rezultata.'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: bags.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Bag bag = bags[index];
                      return _LookbookTile(bag: bag);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Greška pri učitavanju lookbooka'),
                      const SizedBox(height: 8),
                      Text(e.toString(), style: const TextStyle(color: Colors.red)),
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
          ),
        ],
      ),
    );
  }
}

class _LookbookTile extends StatelessWidget {
  const _LookbookTile({required this.bag});

  final Bag bag;

  static Widget _buildBagImage(String? imageUrl) {
    final Widget placeholder = Container(
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.shopping_bag, size: 48)),
    );
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Part = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Part);
        return Image.memory(imageBytes, fit: BoxFit.cover);
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
    final String? imageUrl = bag.displayImageUrl;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LookbookDetailScreen(bagId: bag.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: <Widget>[
            // Slika torbice
            Positioned.fill(
              child: _buildBagImage(imageUrl),
            ),
            // Overlay s informacijama
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
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      bag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.style_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Outfit ideja',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
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
    );
  }
}

