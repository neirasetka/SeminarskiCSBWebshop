import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/belts_provider.dart';
import '../domain/belt.dart';
import '../application/belt_types_provider.dart';
import '../domain/belt_type.dart';
import 'belts_detail_screen.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../orders/application/cart_provider.dart';

class BeltsListScreen extends ConsumerStatefulWidget {
  const BeltsListScreen({super.key});

  @override
  ConsumerState<BeltsListScreen> createState() => _BeltsListScreenState();
}

class _BeltsListScreenState extends ConsumerState<BeltsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBeltTypeId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(beltsListProvider.notifier)
        .refresh(beltTypeId: _selectedBeltTypeId, query: _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Belt>> beltsAsync = ref.watch(beltsListProvider);
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    final bool isAdmin = isAdminAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog kaiševa'),
        actions: <Widget>[
          if (isAdmin)
            IconButton(
              onPressed: () => _showManageBeltTypesDialog(context, ref),
              icon: const Icon(Icons.category),
              tooltip: 'Upravljanje tipovima',
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showBeltFormDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                _BeltTypeFilter(
                  selectedId: _selectedBeltTypeId,
                  onChanged: (int? value) {
                    setState(() => _selectedBeltTypeId = value);
                    _onRefresh();
                  },
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              tooltip: 'Dodaj u korpu',
                              onPressed: () async {
                                await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
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
                            if (isAdmin)
                              PopupMenuButton<String>(
                                onSelected: (String value) async {
                                  if (value == 'edit') {
                                    await _showBeltFormDialog(context, ref, existing: belt);
                                  } else if (value == 'delete') {
                                    final bool? ok = await _confirm(context, 'Obriši proizvod', 'Da li ste sigurni da želite obrisati "${belt.name}"?');
                                    if (ok == true) {
                                      await ref.read(beltsListProvider.notifier).remove(belt.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proizvod obrisan')));
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(value: 'edit', child: Text('Uredi')),
                                  PopupMenuItem<String>(value: 'delete', child: Text('Obriši')),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => BeltDetailScreen(id: belt.id),
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

class _BeltTypeFilter extends ConsumerWidget {
  const _BeltTypeFilter({required this.onChanged, required this.selectedId});

  final ValueChanged<int?> onChanged;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BeltType>> typesAsync = ref.watch(beltTypesProvider);
    return typesAsync.when(
      data: (List<BeltType> types) {
        final List<DropdownMenuItem<int?>> items = <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(value: null, child: Text('Sve vrste')),
          ...types.map((BeltType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
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

Future<void> _showBeltFormDialog(BuildContext context, WidgetRef ref, {Belt? existing}) async {
  final TextEditingController nameController = TextEditingController(text: existing?.name ?? '');
  final TextEditingController codeController = TextEditingController(text: existing?.code ?? '');
  final TextEditingController priceController = TextEditingController(text: existing?.price.toStringAsFixed(2) ?? '');
  final TextEditingController descController = TextEditingController(text: existing?.description ?? '');
  int? selectedTypeId = existing?.beltTypeId;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<List<BeltType>> typesAsync = ref.watch(beltTypesProvider);
        return AlertDialog(
          title: Text(existing == null ? 'Novi proizvod' : 'Uredi proizvod'),
          content: SingleChildScrollView(
            child: Form(
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
                typesAsync.when(
                  data: (List<BeltType> types) {
                    return DropdownButtonFormField<int?>(
                      value: selectedTypeId,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(value: null, child: Text('Bez tipa')),
                        ...types.map((BeltType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
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
                  await ref.read(beltsListProvider.notifier).create(
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        beltTypeId: selectedTypeId,
                      );
                } else {
                  await ref.read(beltsListProvider.notifier).edit(
                        id: existing.id,
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        beltTypeId: selectedTypeId,
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

Future<void> _showManageBeltTypesDialog(BuildContext context, WidgetRef ref) async {
  final TextEditingController nameController = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<List<BeltType>> typesAsync = ref.watch(beltTypesProvider);
        return AlertDialog(
          title: const Text('Tipovi kaiševa'),
          content: SizedBox(
            width: 400,
            child: typesAsync.when(
              data: (List<BeltType> types) {
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
                                final bool exists = types.any((BeltType t) => t.name.toLowerCase().trim() == v.toLowerCase().trim());
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
                            if (types.any((BeltType t) => t.name.toLowerCase().trim() == name.toLowerCase())) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip već postoji')));
                              return;
                            }
                            await ref.read(beltTypesProvider.notifier).create(name);
                            nameController.clear();
                          },
                          child: const Text('Dodaj'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    for (final BeltType t in types)
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
                                  await ref.read(beltTypesProvider.notifier).rename(t.id, newName.trim());
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final bool? ok = await _confirm(context, 'Obriši tip', 'Obrisati "${t.name}"?');
                                if (ok == true) {
                                  await ref.read(beltTypesProvider.notifier).remove(t.id);
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

