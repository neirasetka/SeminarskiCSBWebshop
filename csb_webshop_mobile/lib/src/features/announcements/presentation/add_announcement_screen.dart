import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/announcements_provider.dart';

class AddAnnouncementScreen extends ConsumerStatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  ConsumerState<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends ConsumerState<AddAnnouncementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _bagNameController = TextEditingController();
  final TextEditingController _bagPriceController = TextEditingController();
  final TextEditingController _bagColorController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bagNameController.dispose();
    _bagPriceController.dispose();
    _bagColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new announcement'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Add new announcement',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Najavi novu torbicu unosom naziva, cijene i boje. Obavijest će se pojaviti na info panelu.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bagNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name of the bag',
                    hintText: 'Unesite naziv torbice',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Naziv torbice je obavezan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bagPriceController,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price of the bag',
                    hintText: 'Unesite cijenu (npr. 149.90)',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Cijena je obavezna';
                    }
                    final double? price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price <= 0) {
                      return 'Unesite ispravnu cijenu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bagColorController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Color of the bag',
                    hintText: 'Unesite boju torbice',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Boja je obavezna';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.campaign_outlined),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final double? price = double.tryParse(_bagPriceController.text.replaceAll(',', '.'));
    if (price == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(announcementsListProvider.notifier).addBagAnnouncement(
            bagName: _bagNameController.text.trim(),
            price: price,
            color: _bagColorController.text.trim(),
          );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _bagNameController.clear();
      _bagPriceController.clear();
      _bagColorController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uspješno dodana nova novost')),
      );
    } catch (Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
