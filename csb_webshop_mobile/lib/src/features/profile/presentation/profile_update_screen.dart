import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/user_profile_provider.dart';
import '../domain/user_profile.dart';

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  const ProfileUpdateScreen({super.key, required this.initial});

  final UserProfile initial;

  @override
  ConsumerState<ProfileUpdateScreen> createState() =>
      _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  bool _submitting = false;
  Uint8List? _imageBytes;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initial.firstName,
    );
    _lastNameController = TextEditingController(text: widget.initial.lastName);
    _phoneController = TextEditingController(text: widget.initial.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.single.bytes != null) {
      final Uint8List bytes = Uint8List.fromList(result.files.single.bytes!);
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: widget.initial.email,
            userName: widget.initial.username,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            imageBase64: _imageBase64,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podaci uspješno ažurirani!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Greška pri spremanju: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Profile preview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.initial.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.initial.email,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Osobni podaci',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Ime',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ime je obavezno';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Prezime',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prezime je obavezno';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon (opcionalno)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: '+387 61 234 567',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text(
              'Profilna slika',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _AvatarPreview(imageBytes: _imageBytes, initial: widget.initial),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Odaberi sliku'),
                ),
                if (_imageBytes != null)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Ukloni'),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submitting ? null : _onSubmit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Spremi promjene'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final String first = _firstNameController.text.trim();
    final String last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    final String f = first.isNotEmpty ? first[0] : '';
    final String l = last.isNotEmpty ? last[0] : '';
    return (f + l).toUpperCase();
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.imageBytes, required this.initial});

  final Uint8List? imageBytes;
  final UserProfile initial;

  @override
  Widget build(BuildContext context) {
    const double size = 96;
    final Widget placeholder = CircleAvatar(
      radius: size / 2,
      child: Text(
        _initials(initial.fullName),
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );

    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          imageBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final String? avatar = initial.avatarUrl;
    if (avatar == null || avatar.isEmpty) return placeholder;

    if (avatar.startsWith('data:image')) {
      try {
        final String base64Part = avatar.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => placeholder,
          ),
        );
      } catch (_) {
        return placeholder;
      }
    }

    return ClipOval(
      child: Image.network(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => placeholder,
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    final String first = parts.isNotEmpty ? parts.first : '';
    final String last = parts.length > 1 ? parts.last : '';
    final String raw =
        (first.isNotEmpty ? first[0] : '') + (last.isNotEmpty ? last[0] : '');
    return raw.isEmpty ? '?' : raw.toUpperCase();
  }
}
