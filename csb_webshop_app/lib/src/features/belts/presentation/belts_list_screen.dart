import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/belts_provider.dart';
import '../domain/belt.dart';

class BeltsListScreen extends ConsumerStatefulWidget {
  const BeltsListScreen({super.key});

  @override
  ConsumerState<BeltsListScreen> createState() => _BeltsListScreenState();
}

class _BeltsListScreenState extends ConsumerState<BeltsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(beltsListProvider.notifier).refresh(query: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Belt>> beltsAsync = ref.watch(beltsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog kaiševa'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
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
              child: beltsAsync.when(
                data: (List<Belt> belts) {
                  if (belts.isEmpty) {
                    return const Center(child: Text('Nema rezultata.'));
                  }
                  return ListView.separated(
                    itemCount: belts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Belt belt = belts[index];
                      return ListTile(
                        leading: _BeltThumbnail(imageUrl: belt.imageUrl),
                        title: Text(belt.name),
                        subtitle: Text(
                          belt.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('${belt.price.toStringAsFixed(2)} KM'),
                            if (belt.averageRating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(belt.averageRating!.toStringAsFixed(1)),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          // Future: navigate to belt details
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

class _BeltThumbnail extends StatelessWidget {
  const _BeltThumbnail({this.imageUrl});

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

