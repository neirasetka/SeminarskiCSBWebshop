import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/bags_provider.dart';
import '../domain/bag.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../favorites/application/favorites_provider.dart';
import '../../orders/application/cart_provider.dart';

class BagDetailScreen extends ConsumerStatefulWidget {
  const BagDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<BagDetailScreen> createState() => _BagDetailScreenState();
}

class _BagDetailScreenState extends ConsumerState<BagDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bagDetailProvider.notifier).fetch(widget.id);
    });
  }

  Future<void> _openEditBag(Bag bag) async {
    final bool? saved = await _showBagEditDialog(context, ref, existing: bag);
    if (saved == true && mounted) {
      await ref.read(bagDetailProvider.notifier).fetch(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider);
    final AsyncValue<Set<int>> favoritesAsync = ref.watch(favoritesProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji torbe'),
      ),
      body: bagAsync.when(
        data: (Bag bag) {
          final bool isFav = favoritesAsync.value?.contains(bag.id) ?? false;
          return _BagDetailBody(
            bag: bag,
            isFavorite: isFav,
            onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggleBag(bag.id),
            onAddToCart: isAdmin
                ? null
                : () async {
                    await ref.read(cartProvider.notifier).addBagToCart(bagId: bag.id, price: bag.price);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artikal uspješno dodan u korpu')));
                    }
                  },
            onOutfitIdea: () {
              context.pushNamed(
                'outfitIdea',
                pathParameters: <String, String>{'id': bag.id.toString()},
                queryParameters: <String, String>{'name': bag.name},
              );
            },
            isAdmin: isAdmin,
            onEdit: isAdmin ? () => _openEditBag(bag) : null,
          );
        },
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
                onPressed: () => ref.read(bagDetailProvider.notifier).fetch(widget.id),
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

class _BagDetailBody extends StatelessWidget {
  const _BagDetailBody({
    required this.bag,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onOutfitIdea,
    this.isAdmin = false,
    this.onEdit,
  });

  final Bag bag;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onOutfitIdea;
  final bool isAdmin;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ImageHeader(
            imageUrl: bag.displayImageUrl,
            onEdit: isAdmin ? onEdit : null,
          ),
          const SizedBox(height: 16),
          Text(bag.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('${bag.price.toStringAsFixed(2)} KM', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 16),
              if (bag.averageRating != null)
                Row(
                  children: <Widget>[
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(bag.averageRating!.toStringAsFixed(1)),
                  ],
                ),
              const Spacer(),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : null),
                tooltip: isFavorite ? 'Ukloni iz favorita' : 'Dodaj u favorite',
                onPressed: onToggleFavorite,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SpecRow(label: 'Šifra', value: bag.code ?? '/'),
          _SpecRow(label: 'Tip', value: bag.bagTypeId?.toString() ?? '/'),
          const Divider(height: 32),
          const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(bag.description),
          const SizedBox(height: 24),
          if (onAddToCart != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Dodaj u korpu'),
              ),
            ),
          if (onAddToCart != null) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOutfitIdea,
              icon: const Icon(Icons.style_outlined),
              label: const Text('Outfit ideja'),
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
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
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

Future<bool?> _showBagEditDialog(BuildContext context, WidgetRef ref, {required Bag existing}) async {
  final TextEditingController nameController = TextEditingController(text: existing.name);
  final TextEditingController codeController = TextEditingController(text: existing.code ?? '');
  final TextEditingController priceController =
      TextEditingController(text: existing.price.toStringAsFixed(2));
  final TextEditingController descController =
      TextEditingController(text: existing.description);
  int? selectedTypeId = existing.bagTypeId;
  Uint8List? selectedImageBytes;
  String? selectedImageBase64;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          return AlertDialog(
            title: const Text('Uredi torbu'),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (BuildContext context, void Function(void Function()) setState) {
                  Future<void> pickImage() async {
                    final FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) return 'Cijena je obavezna';
                            final String normalized = v.replaceAll(',', '.').trim();
                            final double? price = double.tryParse(normalized);
                            if (price == null) return 'Unesite ispravan broj';
                            if (price <= 0) return 'Cijena mora biti veća od 0';
                            final List<String> parts = normalized.split('.');
                            if (parts.length > 2) return 'Cijena mora biti u formatu xx.yy (maks. 2 decimale)';
                            if (parts.length == 2 && parts[1].length > 2) return 'Cijena mora biti u formatu xx.yy (maks. 2 decimale)';
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
                                  imageWidget = Image.memory(bytes, fit: BoxFit.cover);
                                } catch (_) {
                                  imageWidget = const Icon(Icons.image, size: 40);
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

                  await ref.read(bagsListProvider.notifier).edit(
                        id: existing.id,
                        name: name,
                        code: code,
                        price: price,
                        description: desc,
                        bagTypeId: selectedTypeId,
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

