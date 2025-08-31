import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag_type.dart';
import '../domain/bag.dart';

class BagsListScreen extends ConsumerStatefulWidget {
  const BagsListScreen({super.key});

  @override
  ConsumerState<BagsListScreen> createState() => _BagsListScreenState();
}

class _BagsListScreenState extends ConsumerState<BagsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBagTypeId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // pagination removed for simplicity; no-op
  }

  Future<void> _onRefresh() async {
    await ref
        .read(bagsListProvider.notifier)
        .refresh(bagTypeId: _selectedBagTypeId, query: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Bag>> bagsAsync = ref.watch(bagsListProvider);
    // no pagination

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog torbi'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                _BagTypeFilter(
                  onChanged: (int? value) {
                    setState(() => _selectedBagTypeId = value);
                    _onRefresh();
                  },
                  selectedId: _selectedBagTypeId,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pretraži po nazivu',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onRefresh(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.search),
                  label: const Text('Traži'),
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
                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: bags.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Bag bag = bags[index];
                      return ListTile(
                        leading: _BagThumbnail(imageUrl: bag.imageUrl),
                        title: Text(bag.name),
                        subtitle: Text(
                          bag.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('${bag.price.toStringAsFixed(2)} KM'),
                            if (bag.averageRating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(bag.averageRating!.toStringAsFixed(1)),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          // Future: navigate to bag details
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Greška pri učitavanju kataloga'),
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

class _BagTypeFilter extends ConsumerWidget {
  const _BagTypeFilter({required this.onChanged, required this.selectedId});

  final ValueChanged<int?> onChanged;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);
    return typesAsync.when(
      data: (List<BagType> types) {
        final List<DropdownMenuItem<int?>> items = <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(value: null, child: Text('Sve vrste')),
          ...types.map((BagType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
        ];
        return DropdownButton<int?>(
          value: selectedId,
          items: items,
          onChanged: onChanged,
          hint: const Text('Vrsta'),
        );
      },
      loading: () => const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (Object e, StackTrace st) => const SizedBox(),
    );
  }
}

class _BagThumbnail extends StatelessWidget {
  const _BagThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

