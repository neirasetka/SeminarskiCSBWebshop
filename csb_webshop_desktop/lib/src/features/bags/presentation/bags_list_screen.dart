import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:csb_webshop_shared/form_validators.dart';
import '../../../core/api_exception.dart';
import '../../../core/paged_list_state.dart';
import '../application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag_type.dart';
import '../domain/bag.dart';
import 'bag_form_screen.dart';
import 'bags_detail_screen.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';

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
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(bagsListProvider.notifier).loadMore();
    }
  }

  Future<void> _openBagForm(BuildContext context, {Bag? existing}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BagFormScreen(existing: existing),
      ),
    );
    if (saved == true && mounted) {
      final String message = existing == null ? 'Torba dodana' : 'Torba ažurirana';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onRefresh() async {
    await ref
        .read(bagsListProvider.notifier)
        .refresh(bagTypeId: _selectedBagTypeId, query: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PagedListState<Bag>> bagsAsync = ref.watch(bagsListProvider);
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    final bool isAdmin = isAdminAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog torbi'),
        actions: <Widget>[
          if (isAdmin)
            IconButton(
              onPressed: () => _showManageBagTypesDialog(context, ref),
              icon: const Icon(Icons.category),
              tooltip: 'Upravljanje tipovima',
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openBagForm(context),
              child: const Icon(Icons.add),
            )
          : null,
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
                data: (PagedListState<Bag> paged) {
                  final List<Bag> bags = paged.items;
                  if (bags.isEmpty) {
                    return const Center(child: Text('Nema rezultata.'));
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: bags.length + (paged.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= bags.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final Bag bag = bags[index];
                      final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
                      return ListTile(
                        leading: _BagThumbnail(imageUrl: bag.displayImageUrl),
                        title: Text(bag.name),
                        subtitle: Text(
                          bag.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                              tooltip: isFav ? 'Ukloni iz favorita' : 'Dodaj u favorite',
                              onPressed: () => ref.read(favoritesProvider.notifier).toggleBag(bag.id),
                            ),
                            if (!isAdmin)
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                tooltip: 'Dodaj u korpu',
                                onPressed: () async {
                                  try {
                                    await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id);
                                    if (context.mounted) {
                                      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                                      final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller = messenger.showSnackBar(
                                        SnackBar(
                                          content: const Text('Artikal uspješno dodan u korpu'),
                                          duration: const Duration(seconds: 5),
                                          action: SnackBarAction(
                                            label: 'NARUČI',
                                            onPressed: () => context.go('/cart'),
                                          ),
                                        ),
                                      );
                                      Future<void>.delayed(const Duration(seconds: 5), () {
                                        if (!context.mounted) return;
                                        controller.close();
                                      });
                                    }
                                  } catch (e, st) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Greška: ${ApiException.formatForDisplay(e)}'),
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    }
                                    debugPrint('Add to cart error: $e\n$st');
                                  }
                                },
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                            if (isAdmin)
                              PopupMenuButton<String>(
                                onSelected: (String value) async {
                                  if (value == 'edit') {
                                    await _openBagForm(context, existing: bag);
                                  } else if (value == 'delete') {
                                    final bool? ok = await _confirm(context, 'Obriši proizvod', 'Da li ste sigurni da želite obrisati "${bag.name}"?');
                                    if (ok == true) {
                                      try {
                                        await ref.read(bagsListProvider.notifier).remove(bag.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Proizvod obrisan')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Greška: ${ApiException.formatForDisplay(e)}'),
                                              backgroundColor: Theme.of(context).colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(value: 'edit', child: Text('Uredi')),
                                  const PopupMenuItem<String>(value: 'delete', child: Text('Obriši')),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => BagDetailScreen(id: bag.id),
                            ),
                          );
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

    // If the URL is a data URL (base64), render it with Image.memory.
    if (imageUrl!.startsWith('data:image')) {
      try {
        final String base64Part = imageUrl!.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return placeholder;
      }
    }

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

Future<bool?> _confirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Potvrdi')),
      ],
    ),
  );
}

Future<void> _showManageBagTypesDialog(BuildContext context, WidgetRef ref) async {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> typeFormKey = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);
        return AlertDialog(
          title: const Text('Tipovi torbi'),
          content: SizedBox(
            width: 400,
            child: typesAsync.when(
              data: (List<BagType> types) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Form(
                            key: typeFormKey,
                            autovalidateMode: AutovalidateMode.disabled,
                            child: TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Novi tip'),
                              validator: (String? v) => FormValidators.uniqueTypeName(
                                v,
                                existingNames: types.map((BagType t) => t.name),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (!(typeFormKey.currentState?.validate() ?? false)) return;
                            final String name = nameController.text.trim();
                            await ref.read(bagTypesProvider.notifier).create(name);
                            nameController.clear();
                            typeFormKey.currentState?.reset();
                          },
                          child: const Text('Dodaj'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    for (final BagType t in types)
                      ListTile(
                        title: Text(t.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final String? newName =
                                    await FormValidators.promptValidatedText(
                                  context,
                                  title: 'Uredi tip',
                                  label: 'Naziv',
                                  initial: t.name,
                                  validator: (String? v) =>
                                      FormValidators.uniqueTypeName(
                                    v,
                                    existingNames:
                                        types.map((BagType t) => t.name),
                                    currentName: t.name,
                                  ),
                                );
                                if (newName != null && newName.isNotEmpty) {
                                  await ref.read(bagTypesProvider.notifier).rename(t.id, newName);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final bool? ok = await _confirm(context, 'Obriši tip', 'Obrisati "${t.name}"?');
                                if (ok == true) {
                                  try {
                                    await ref.read(bagTypesProvider.notifier).remove(t.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Greška: ${ApiException.formatForDisplay(e)}'),
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (Object e, StackTrace st) => Text(e.toString()),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zatvori')),
          ],
        );
      });
    },
  );
}
