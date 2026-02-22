import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/announcements_provider.dart';
import '../domain/announcement.dart';

/// Screen for admins to create a new bag announcement.
/// Form includes: bag name, bag price, bag color.
/// Buttons: Close (returns to homepage), Add (creates announcement).
class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends ConsumerState<AnnouncementFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submitAnnouncement() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final Announcement? created = await ref.read(announcementsListProvider.notifier).createBagAnnouncement(
        bagName: _nameController.text.trim(),
        bagPrice: double.parse(_priceController.text.replaceAll(',', '.').trim()),
        bagColor: _colorController.text.trim(),
      );

      if (!mounted) return;

      if (created != null) {
        // Clear form to prepare for adding a new record
        _nameController.clear();
        _priceController.clear();
        _colorController.clear();
        _formKey.currentState?.reset();
        
        // Show success dialog
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => _SuccessDialog(announcement: created),
        );
        
        // Stay on form for adding another announcement (form already cleared above)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri kreiranju najave. Pokušajte ponovo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _closeForm() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 900;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: isWideScreen ? 600 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header
                  _buildHeader(colorScheme, textTheme),
                  const SizedBox(height: 40),
                  
                  // Form Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Form Title
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Dodaj novu najavu',
                                        style: textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Najavite novu torbicu kupcima',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 24),

                            // Name of the bag field
                            _buildFieldLabel('Naziv torbice', Icons.shopping_bag_outlined, colorScheme, textTheme),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration(
                                'Unesite naziv torbice',
                                colorScheme,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Naziv torbice je obavezan';
                                }
                                if (value.trim().length < 2) {
                                  return 'Naziv mora imati najmanje 2 znaka';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Price of the bag field
                            _buildFieldLabel('Cijena torbice', Icons.attach_money, colorScheme, textTheme),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              decoration: _buildInputDecoration(
                                'Unesite cijenu (npr. 150.00)',
                                colorScheme,
                                suffixText: 'KM',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Cijena je obavezna';
                                }
                                final double? price = double.tryParse(value.replaceAll(',', '.').trim());
                                if (price == null) {
                                  return 'Unesite ispravnu cijenu';
                                }
                                if (price <= 0) {
                                  return 'Cijena mora biti veća od 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Color of the bag field
                            _buildFieldLabel('Boja torbice', Icons.palette_outlined, colorScheme, textTheme),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _colorController,
                              decoration: _buildInputDecoration(
                                'Unesite boju (npr. crna, smeđa)',
                                colorScheme,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitAnnouncement(),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Boja je obavezna';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),

                            // Preview card
                            _buildPreviewCard(colorScheme, textTheme),
                            const SizedBox(height: 32),

                            // Buttons
                            Row(
                              children: <Widget>[
                                // Close button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSubmitting ? null : _closeForm,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Zatvori'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Add button
                                Expanded(
                                  flex: 2,
                                  child: FilledButton.icon(
                                    onPressed: _isSubmitting ? null : _submitAnnouncement,
                                    icon: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.add),
                                    label: Text(_isSubmitting ? 'Kreiranje...' : 'Dodaj'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Nazad',
              onPressed: _isSubmitting ? null : _closeForm,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.campaign,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Nova Najava Torbice',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Kreirajte najavu za novu torbicu koja će biti vidljiva na Info Panelu',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, ColorScheme colorScheme, {String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixText: suffixText,
    );
  }

  Widget _buildPreviewCard(ColorScheme colorScheme, TextTheme textTheme) {
    final String name = _nameController.text.trim();
    final String price = _priceController.text.trim();
    final String color = _colorController.text.trim();

    if (name.isEmpty && price.isEmpty && color.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.preview, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Pregled najave',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.isNotEmpty ? 'Nova torbica: $name' : 'Nova torbica: [naziv]',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Predstavljamo vam novu torbicu "${name.isNotEmpty ? name : '[naziv]'}" '
            'u boji ${color.isNotEmpty ? color : '[boja]'} '
            'po cijeni od ${price.isNotEmpty ? price : '[cijena]'} KM. '
            'Pogledajte našu ponudu!',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Success dialog shown after announcement is created
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Uspješno dodana nova najava!',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Najava "${announcement.title}" je kreirana i vidljiva je na Info Panelu.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  announcement.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.body,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Početna'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Dodaj još'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
