import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/paged_list_state.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag.dart';
import '../../bags/domain/bag_type.dart';
import '../../belts/application/belt_types_provider.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/domain/belt.dart';
import '../../belts/domain/belt_type.dart';

class LookbookScreen extends ConsumerStatefulWidget {
  const LookbookScreen({super.key});

  @override
  ConsumerState<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends ConsumerState<LookbookScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedBagTypeId;
  int? _selectedBeltTypeId;
  _LookbookCategory _selectedCategory = _LookbookCategory.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_selectedCategory != _LookbookCategory.belts) {
        ref.read(bagsListProvider.notifier).loadMore();
      }
      if (_selectedCategory != _LookbookCategory.bags) {
        ref.read(beltsListProvider.notifier).loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait(<Future<void>>[
      ref.read(bagsListProvider.notifier).refresh(
            bagTypeId: _selectedCategory == _LookbookCategory.bags
                ? _selectedBagTypeId
                : null,
            query: ref.read(bagsListProvider.notifier).query,
          ),
      ref.read(beltsListProvider.notifier).refresh(
            beltTypeId: _selectedCategory == _LookbookCategory.belts
                ? _selectedBeltTypeId
                : null,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PagedListState<Bag>> bagsAsync = ref.watch(bagsListProvider);
    final AsyncValue<PagedListState<Belt>> beltsAsync = ref.watch(beltsListProvider);
    final AsyncValue<List<BagType>> bagTypesAsync = ref.watch(bagTypesProvider);
    final AsyncValue<List<BeltType>> beltTypesAsync =
        ref.watch(beltTypesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Nazad',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Lookbook'),
      ),
      body: Column(
        children: <Widget>[
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Kako stilizirati naše torbice i kaiševe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Otkrijte inspiraciju za stiliziranje naših torbica i kaiševa',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                SegmentedButton<_LookbookCategory>(
                  segments: const <ButtonSegment<_LookbookCategory>>[
                    ButtonSegment<_LookbookCategory>(
                      value: _LookbookCategory.all,
                      label: Text('Sve'),
                      icon: Icon(Icons.grid_view),
                    ),
                    ButtonSegment<_LookbookCategory>(
                      value: _LookbookCategory.bags,
                      label: Text('Torbice'),
                      icon: Icon(Icons.shopping_bag_outlined),
                    ),
                    ButtonSegment<_LookbookCategory>(
                      value: _LookbookCategory.belts,
                      label: Text('Kaiševi'),
                      icon: Icon(Icons.straighten),
                    ),
                  ],
                  selected: <_LookbookCategory>{_selectedCategory},
                  onSelectionChanged: (Set<_LookbookCategory> value) {
                    final _LookbookCategory selected = value.first;
                    setState(() {
                      _selectedCategory = selected;
                      if (selected != _LookbookCategory.bags) {
                        _selectedBagTypeId = null;
                      }
                      if (selected != _LookbookCategory.belts) {
                        _selectedBeltTypeId = null;
                      }
                    });
                    _onRefresh();
                  },
                ),
                const SizedBox(width: 16),
                if (_selectedCategory == _LookbookCategory.bags)
                  bagTypesAsync.when(
                    data: (List<BagType> types) {
                      final List<DropdownMenuItem<int?>> items =
                          <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sve vrste torbica'),
                        ),
                        ...types.map(
                          (BagType t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        ),
                      ];
                      return DropdownButton<int?>(
                        value: _selectedBagTypeId,
                        items: items,
                        onChanged: (int? value) {
                          setState(() => _selectedBagTypeId = value);
                          _onRefresh();
                        },
                        hint: const Text('Vrsta torbice'),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (Object e, StackTrace st) => const SizedBox(),
                  ),
                if (_selectedCategory == _LookbookCategory.belts)
                  beltTypesAsync.when(
                    data: (List<BeltType> types) {
                      final List<DropdownMenuItem<int?>> items =
                          <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sve vrste kaiševa'),
                        ),
                        ...types.map(
                          (BeltType t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        ),
                      ];
                      return DropdownButton<int?>(
                        value: _selectedBeltTypeId,
                        items: items,
                        onChanged: (int? value) {
                          setState(() => _selectedBeltTypeId = value);
                          _onRefresh();
                        },
                        hint: const Text('Vrsta kaiša'),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (Object e, StackTrace st) => const SizedBox(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildGridContent(
                context: context,
                bagsAsync: bagsAsync,
                beltsAsync: beltsAsync,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent({
    required BuildContext context,
    required AsyncValue<PagedListState<Bag>> bagsAsync,
    required AsyncValue<PagedListState<Belt>> beltsAsync,
  }) {
    if (bagsAsync.isLoading || beltsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bagsAsync.hasError || beltsAsync.hasError) {
      final Object error = bagsAsync.error ?? beltsAsync.error ?? 'Nepoznata greška';
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Greška pri učitavanju lookbooka'),
            const SizedBox(height: 8),
            Text(error.toString(), style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovno'),
            ),
          ],
        ),
      );
    }

    final List<Bag> bags = bagsAsync.value?.items ?? <Bag>[];
    final List<Belt> belts = beltsAsync.value?.items ?? <Belt>[];
    final bool isLoadingMore =
        (bagsAsync.value?.isLoadingMore ?? false) || (beltsAsync.value?.isLoadingMore ?? false);
    final List<_LookbookItem> items = <_LookbookItem>[
      if (_selectedCategory != _LookbookCategory.belts)
        ...bags.map(_LookbookItem.fromBag),
      if (_selectedCategory != _LookbookCategory.bags)
        ...belts.map(_LookbookItem.fromBelt),
    ];

    if (items.isEmpty) {
      return const Center(child: Text('Nema rezultata.'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final _LookbookItem item = items[index];
        return _LookbookTile(item: item);
      },
    );
  }
}

class _LookbookTile extends StatelessWidget {
  const _LookbookTile({required this.item});

  final _LookbookItem item;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = item.imageUrl;
    final Widget placeholder = Container(
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image)),
    );
    Widget imageWidget = placeholder;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final String base64Part = imageUrl.split(',').last;
          final imageBytes = base64Decode(base64Part);
          imageWidget = Image.memory(
            imageBytes,
            fit: BoxFit.cover,
          );
        } catch (_) {
          imageWidget = placeholder;
        }
      } else {
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        );
      }
    }
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );

    return InkWell(
      onTap: () {
        context.go(item.detailRoute);
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
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Text(
                        '${item.price.toStringAsFixed(2)} KM',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      Icon(
                        item.kind == _LookbookItemKind.bag
                            ? Icons.shopping_bag_outlined
                            : Icons.straighten,
                        size: 16,
                        color: Colors.grey.shade700,
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

enum _LookbookCategory { all, bags, belts }

enum _LookbookItemKind { bag, belt }

class _LookbookItem {
  const _LookbookItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.kind,
  });

  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final _LookbookItemKind kind;

  String get detailRoute {
    return kind == _LookbookItemKind.bag
        ? '/lookbook/bags/$id'
        : '/lookbook/belts/$id';
  }

  factory _LookbookItem.fromBag(Bag bag) {
    return _LookbookItem(
      id: bag.id,
      name: bag.name,
      price: bag.price,
      imageUrl: bag.displayImageUrl,
      kind: _LookbookItemKind.bag,
    );
  }

  factory _LookbookItem.fromBelt(Belt belt) {
    return _LookbookItem(
      id: belt.id,
      name: belt.name,
      price: belt.price,
      imageUrl: belt.displayImageUrl,
      kind: _LookbookItemKind.belt,
    );
  }
}

