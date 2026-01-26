import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/belt_types_provider.dart';
import '../application/belts_provider.dart';
import '../domain/belt.dart';
import '../domain/belt_type.dart';

class BeltFormScreen extends ConsumerStatefulWidget {
  const BeltFormScreen({super.key, this.existing});

  final Belt? existing;

  @override
  ConsumerState<BeltFormScreen> createState() => _BeltFormScreenState();
}

class _BeltFormScreenState extends ConsumerState<BeltFormScreen> {
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
    final Belt? belt = widget.existing;
    _nameController = TextEditingController(text: belt?.name ?? '');
    _codeController = TextEditingController(text: belt?.code ?? '');
    _priceController = TextEditingController(text: belt != null ? belt.price.toStringAsFixed(2) : '');
    _descriptionController = TextEditingController(text: belt?.description ?? '');
    _selectedTypeId = belt?.beltTypeId;
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
    final String name = _nameController.text.trim();
    final String code = _codeController.text.trim();
    final double? price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) return;
    final String description = _descriptionController.text.trim();

    setState(() => _isSaving = true);
    try {
      if (widget.existing == null) {
        await ref.read(beltsListProvider.notifier).create(
              name: name,
              code: code,
              price: price,
              description: description,
              beltTypeId: _selectedTypeId,
              imageBase64: _imageBase64,
            );
      } else {
        await ref.read(beltsListProvider.notifier).edit(
              id: widget.existing!.id,
              name: name,
              code: code,
              price: price,
              description: description,
              beltTypeId: _selectedTypeId,
              imageBase64: _imageBase64,
            );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (Object e) {
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
    final AsyncValue<List<BeltType>> typesAsync = ref.watch(beltTypesProvider);
    final Belt? existing = widget.existing;

    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: Text(existing == null ? 'Novi kaiš' : 'Uredi kaiš'),
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
                data: (List<BeltType> types) {
                  return DropdownButtonFormField<int?>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Tip'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(value: null, child: Text('Bez tipa')),
                      ...types.map(
                        (BeltType t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
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
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 4,
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
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
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
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageBytes, required this.existing});

  final Uint8List? imageBytes;
  final Belt? existing;

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

