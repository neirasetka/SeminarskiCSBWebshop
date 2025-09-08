import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bags/application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/domain/bag_type.dart';
import '../../bags/presentation/bags_detail_screen.dart';

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
                    return DropdownButton<int?>
                      (
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

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = bag.displayImageUrl;
    final Widget image = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double imageWidth = constraints.maxWidth * 0.33;
        final Widget placeholder = Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image)),
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: imageWidth,
              height: constraints.maxHeight,
              child: imageUrl == null || imageUrl.isEmpty
                  ? placeholder
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
            ),
          ),
        );
      },
    );

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => BagDetailScreen(id: bag.id)),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: image),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    bag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('${bag.price.toStringAsFixed(2)} KM', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

