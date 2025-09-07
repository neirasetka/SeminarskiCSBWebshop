import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import '../application/bags_provider.dart';
import '../../bags/application/bag_types_provider.dart';
import '../../bags/domain/bag_type.dart';
import '../domain/bag.dart';
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
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    final bool isAdmin = isAdminAsync.value ?? false;
    // no pagination

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
              onPressed: () => _showBagFormDialog(context, ref),
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
                      final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
                      return ListTile(
                        leading: _BagThumbnail(imageUrl: bag.imageUrl),
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
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              tooltip: 'Dodaj u korpu',
                              onPressed: () async {
                                await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Dodano u korpu')),
                                  );
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
                                    await _showBagFormDialog(context, ref, existing: bag);
                                  } else if (value == 'delete') {
                                    final bool? ok = await _confirm(context, 'Obriši proizvod', 'Da li ste sigurni da želite obrisati "${bag.name}"?');
                                    if (ok == true) {
                                      await ref.read(bagsListProvider.notifier).remove(bag.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proizvod obrisan')));
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

Future<void> _showBagFormDialog(BuildContext context, WidgetRef ref, {Bag? existing}) async {
  final TextEditingController nameController = TextEditingController(text: existing?.name ?? '');
  final TextEditingController codeController = TextEditingController(text: existing?.code ?? '');
  final TextEditingController priceController = TextEditingController(text: existing?.price.toStringAsFixed(2) ?? '');
  final TextEditingController descController = TextEditingController(text: existing?.description ?? '');
  int? selectedTypeId = existing?.bagTypeId;
  Uint8List? selectedImageBytes;
  String? selectedImageBase64;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);
        return AlertDialog(
          title: Text(existing == null ? 'Novi proizvod' : 'Uredi proizvod'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setState) {
                Future<void> pickImage() async {
                  final FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty && result.files.single.bytes != null) {
                    final Uint8List bytes = result.files.single.bytes!;
                    setState(() {
                      selectedImageBytes = bytes;
                      selectedImageBase64 = base64Encode(bytes);
                    });
                  }
                }

                return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Naziv'),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return 'Naziv je obavezan';
                      if (v.trim().length < 2) return 'Naziv mora imati bar 2 znaka';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Šifra'),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return 'Šifra je obavezna';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Cijena'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return 'Cijena je obavezna';
                      final double? price = double.tryParse(v.replaceAll(',', '.'));
                      if (price == null) return 'Unesite ispravan broj';
                      if (price <= 0) return 'Cijena mora biti veća od 0';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Opis'),
                    maxLines: 3,
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Slika', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double previewWidth = constraints.maxWidth * 0.33;
                    if (selectedImageBytes != null) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: previewWidth,
                            height: 160,
                            child: Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: previewWidth,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(child: Icon(Icons.image, size: 40)),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Odaberi sliku'),
                    ),
                    const SizedBox(width: 8),
                    if (selectedImageBytes != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedImageBytes = null;
                            selectedImageBase64 = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        child: const Text('Ukloni'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                typesAsync.when(
                  data: (List<BagType> types) {
                    return DropdownButtonFormField<int?>(
                      value: selectedTypeId,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(value: null, child: Text('Bez tipa')),
                        ...types.map((BagType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (int? v) => selectedTypeId = v,
                      decoration: const InputDecoration(labelText: 'Tip'),
                    );
                  },
                  loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (Object e, StackTrace st) => const SizedBox(),
                ),
                ],
              ),
            );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final String name = nameController.text.trim();
                final String code = codeController.text.trim();
                final double? price = double.tryParse(priceController.text.replaceAll(',', '.'));
                final String desc = descController.text.trim();
                if (existing == null) {
                  await ref.read(bagsListProvider.notifier).create(
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        bagTypeId: selectedTypeId,
                        imageBase64: selectedImageBase64,
                      );
                } else {
                  await ref.read(bagsListProvider.notifier).edit(
                        id: existing.id,
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        bagTypeId: selectedTypeId,
                        imageBase64: selectedImageBase64,
                      );
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        );
      });
    },
  );
}

Future<void> _showManageBagTypesDialog(BuildContext context, WidgetRef ref) async {
  final TextEditingController nameController = TextEditingController();
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
                            autovalidateMode: AutovalidateMode.disabled,
                            child: TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Novi tip'),
                              validator: (String? v) {
                                if (v == null || v.trim().isEmpty) return 'Naziv je obavezan';
                                final bool exists = types.any((BagType t) => t.name.toLowerCase().trim() == v.toLowerCase().trim());
                                if (exists) return 'Tip sa ovim nazivom već postoji';
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final String name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unesite naziv tipa')));
                              return;
                            }
                            if (types.any((BagType t) => t.name.toLowerCase().trim() == name.toLowerCase())) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip već postoji')));
                              return;
                            }
                            await ref.read(bagTypesProvider.notifier).create(name);
                            nameController.clear();
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
                                final String? newName = await _promptText(context, 'Uredi tip', 'Naziv', t.name);
                                if (newName != null && newName.trim().isNotEmpty) {
                                  await ref.read(bagTypesProvider.notifier).rename(t.id, newName.trim());
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final bool? ok = await _confirm(context, 'Obriši tip', 'Obrisati "${t.name}"?');
                                if (ok == true) {
                                  await ref.read(bagTypesProvider.notifier).remove(t.id);
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

Future<String?> _promptText(BuildContext context, String title, String label, String initial) async {
  final TextEditingController ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: label)),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text), child: const Text('Sačuvaj')),
      ],
    ),
  );
}

