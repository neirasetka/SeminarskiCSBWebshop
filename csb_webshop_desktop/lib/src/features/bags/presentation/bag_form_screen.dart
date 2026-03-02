import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/bag_types_provider.dart';
import '../application/bags_provider.dart';
import '../domain/bag.dart';
import '../domain/bag_type.dart';

class BagFormScreen extends ConsumerStatefulWidget {
  const BagFormScreen({super.key, this.existing});

  final Bag? existing;

  @override
  ConsumerState<BagFormScreen> createState() => _BagFormScreenState();
}

class _BagFormScreenState extends ConsumerState<BagFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  int? _selectedTypeId;
  Uint8List? _imageBytes;
  String? _imageBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final Bag? bag = widget.existing;
    _nameController = TextEditingController(text: bag?.name ?? '');
    _codeController = TextEditingController(text: bag?.code ?? '');
    _priceController = TextEditingController(text: bag != null ? bag.price.toStringAsFixed(2) : '');
    _descriptionController = TextEditingController(text: bag?.description ?? '');
    _selectedTypeId = bag?.bagTypeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageBase64 = base64Encode(_imageBytes!);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    
    // Show confirmation dialog before saving
    final bool confirmed = await showSaveConfirmationDialog(context);
    if (!confirmed || !mounted) return;
    
    final String name = _nameController.text.trim();
    final String code = _codeController.text.trim();
    final double? price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) return;
    final String description = _descriptionController.text.trim();

    setState(() => _isSaving = true);
    try {
      if (widget.existing == null) {
        await ref.read(bagsListProvider.notifier).create(
              name: name,
              code: code,
              price: price,
              description: description,
              bagTypeId: _selectedTypeId,
              imageBase64: _imageBase64,
            );
      } else {
        await ref.read(bagsListProvider.notifier).edit(
              id: widget.existing!.id,
              name: name,
              code: code,
              price: price,
              description: description,
              bagTypeId: _selectedTypeId,
              imageBase64: _imageBase64,
            );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri čuvanju: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancel() {
    if (_isSaving) return;
    handleBackWithConfirmation(context);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<BagType>> typesAsync = ref.watch(bagTypesProvider);
    final Bag? existing = widget.existing;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Nazad',
        ),
        title: Text(existing == null ? 'Nova torba' : 'Uredi torbu'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Naziv'),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) return 'Naziv je obavezan';
                  if (value.trim().length < 2) return 'Naziv mora imati bar 2 znaka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Šifra'),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) return 'Šifra je obavezna';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Cijena'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) return 'Cijena je obavezna';
                  final double? parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) return 'Unesite ispravan broj';
                  if (parsed <= 0) return 'Cijena mora biti veća od 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              typesAsync.when(
                data: (List<BagType> types) {
                  return DropdownButtonFormField<int?>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Tip'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(value: null, child: Text('Bez tipa')),
                      ...types.map(
                        (BagType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
                      ),
                    ],
                    onChanged: (int? value) => setState(() => _selectedTypeId = value),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (Object e, StackTrace st) => Text('Greška pri učitavanju tipova: $e'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  hintText: 'Unesite opis torbe...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                maxLines: 4,
                minLines: 3,
                textAlignVertical: TextAlignVertical.top,
              ),
              const SizedBox(height: 16),
              Text('Slika', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ImagePreview(
                imageBytes: _imageBytes,
                existing: existing,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Odaberi sliku'),
                  ),
                  if (_imageBytes != null)
                    OutlinedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Ukloni'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isSaving ? null : _cancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageBytes, required this.existing});

  final Uint8List? imageBytes;
  final Bag? existing;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(child: Icon(Icons.image, size: 48)),
    );

    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (existing?.imageBase64 != null && existing!.imageBase64!.isNotEmpty) {
      try {
        final Uint8List decoded = base64Decode(existing!.imageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: Image.memory(decoded, fit: BoxFit.cover),
          ),
        );
      } catch (_) {
        // ignore and show placeholder
      }
    }

    if (existing?.imageUrl != null && existing!.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Image.network(
            existing!.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      );
    }

    return placeholder;
  }
}

