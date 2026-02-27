import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/belts_provider.dart';
import '../domain/belt.dart';
import '../application/belt_types_provider.dart';
import '../domain/belt_type.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../orders/application/cart_provider.dart';

class BeltDetailScreen extends ConsumerStatefulWidget {
  const BeltDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BeltDetailScreen> createState() => _BeltDetailScreenState();
}

class _BeltDetailScreenState extends ConsumerState<BeltDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beltDetailProvider.notifier).fetch(widget.id);
    });
  }

  Future<void> _openEditBelt(Belt belt) async {
    final bool? saved = await _showBeltEditDialog(context, ref, existing: belt);
    if (saved == true && mounted) {
      await ref.read(beltDetailProvider.notifier).fetch(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Belt> beltAsync = ref.watch(beltDetailProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji kaiša')),
      body: beltAsync.when(
        data: (Belt belt) => _BeltDetailBody(
          belt: belt,
          isAdmin: isAdmin,
          onEdit: isAdmin ? () => _openEditBelt(belt) : null,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Greška pri učitavanju detalja.'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(beltDetailProvider.notifier).fetch(widget.id),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovno'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeltDetailBody extends ConsumerWidget {
  const _BeltDetailBody({
    required this.belt,
    this.isAdmin = false,
    this.onEdit,
  });

  final Belt belt;
  final bool isAdmin;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHeader(
            imageUrl: belt.displayImageUrl,
            onEdit: isAdmin ? onEdit : null,
          ),
          const SizedBox(height: 16),
          Text(belt.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('${belt.price.toStringAsFixed(2)} KM', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 16),
              if (belt.averageRating != null)
                Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(belt.averageRating!.toStringAsFixed(1)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SpecRow(label: 'Šifra', value: belt.code ?? '/'),
          _SpecRow(label: 'Tip', value: belt.beltTypeId?.toString() ?? '/'),
          const Divider(height: 32),
          const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(belt.description),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(cartProvider.notifier).addBeltToCart(beltId: belt.id, price: belt.price);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dodano u korpu')));
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Dodaj u korpu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({this.imageUrl, this.onEdit});

  final String? imageUrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final Widget placeholderBox = Container(
      height: 240,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Icon(Icons.image, size: 48)),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double imageWidth = constraints.maxWidth * 0.33;
        Widget imageContent;
        if (imageUrl == null || imageUrl!.isEmpty) {
          imageContent = placeholderBox;
        } else if (imageUrl!.startsWith('data:image')) {
          try {
            final String base64Part = imageUrl!.split(',').last;
            final Uint8List bytes = base64Decode(base64Part);
            imageContent = Image.memory(
              bytes,
              fit: BoxFit.cover,
            );
          } catch (_) {
            imageContent = placeholderBox;
          }
        } else {
          imageContent = Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholderBox,
          );
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: imageWidth,
            height: 240,
            child: Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageContent,
                ),
                if (onEdit != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Uredi',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Future<bool?> _showBeltEditDialog(BuildContext context, WidgetRef ref,
    {required Belt existing}) async {
  final TextEditingController nameController =
      TextEditingController(text: existing.name);
  final TextEditingController codeController =
      TextEditingController(text: existing.code ?? '');
  final TextEditingController priceController =
      TextEditingController(text: existing.price.toStringAsFixed(2));
  final TextEditingController descController =
      TextEditingController(text: existing.description);
  int? selectedTypeId = existing.beltTypeId;
  Uint8List? selectedImageBytes;
  String? selectedImageBase64;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<List<BeltType>> typesAsync =
              ref.watch(beltTypesProvider);
          return AlertDialog(
            title: const Text('Uredi kaiš'),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder:
                    (BuildContext context, void Function(void Function()) setState) {
                  Future<void> pickImage() async {
                    final FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: true,
                    );
                    if (result != null &&
                        result.files.isNotEmpty &&
                        result.files.single.bytes != null) {
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
                            if (v == null || v.trim().isEmpty) {
                              return 'Naziv je obavezan';
                            }
                            if (v.trim().length < 2) {
                              return 'Naziv mora imati bar 2 znaka';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(labelText: 'Šifra'),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Šifra je obavezna';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Cijena'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Cijena je obavezna';
                            }
                            final double? price =
                                double.tryParse(v.replaceAll(',', '.'));
                            if (price == null) {
                              return 'Unesite ispravan broj';
                            }
                            if (price <= 0) {
                              return 'Cijena mora biti veća od 0';
                            }
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
                          child: Text(
                            'Slika',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder:
                              (BuildContext context, BoxConstraints constraints) {
                            final double previewWidth = constraints.maxWidth * 0.45;
                            Widget preview;
                            if (selectedImageBytes != null) {
                              preview = ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: previewWidth,
                                  height: 160,
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            } else if (existing.displayImageUrl != null &&
                                existing.displayImageUrl!.isNotEmpty) {
                              final String url = existing.displayImageUrl!;
                              Widget imageWidget;
                              if (url.startsWith('data:image')) {
                                try {
                                  final String base64Part = url.split(',').last;
                                  final Uint8List bytes = base64Decode(base64Part);
                                  imageWidget =
                                      Image.memory(bytes, fit: BoxFit.cover);
                                } catch (_) {
                                  imageWidget =
                                      const Icon(Icons.image, size: 40);
                                }
                              } else {
                                imageWidget = Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image, size: 40),
                                );
                              }
                              preview = ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: previewWidth,
                                  height: 160,
                                  child: imageWidget,
                                ),
                              );
                            } else {
                              preview = Container(
                                width: previewWidth,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child:
                                    const Center(child: Icon(Icons.image, size: 40)),
                              );
                            }
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: preview,
                            );
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
                                label: const Text('Ukloni'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        typesAsync.when(
                          data: (List<BeltType> types) {
                            return DropdownButtonFormField<int?>(
                              value: selectedTypeId,
                              items: <DropdownMenuItem<int?>>[
                                const DropdownMenuItem<int?>(
                                    value: null, child: Text('Bez tipa')),
                                ...types.map(
                                  (BeltType t) => DropdownMenuItem<int?>(
                                    value: t.id,
                                    child: Text(t.name),
                                  ),
                                ),
                              ],
                              onChanged: (int? v) => selectedTypeId = v,
                              decoration:
                                  const InputDecoration(labelText: 'Tip'),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 48,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (Object e, StackTrace st) => const SizedBox(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final String name = nameController.text.trim();
                  final String code = codeController.text.trim();
                  final double price =
                      double.parse(priceController.text.replaceAll(',', '.'));
                  final String desc = descController.text.trim();

                  await ref.read(beltsListProvider.notifier).edit(
                        id: existing.id,
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        beltTypeId: selectedTypeId,
                        imageBase64: selectedImageBase64,
                      );
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Sačuvaj'),
              ),
            ],
          );
        },
      );
    },
  );
}

