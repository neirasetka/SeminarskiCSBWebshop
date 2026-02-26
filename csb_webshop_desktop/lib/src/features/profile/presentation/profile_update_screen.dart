import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/user_profile_provider.dart';
import '../domain/user_profile.dart';

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  const ProfileUpdateScreen({super.key, required this.initial});

  final UserProfile initial;

  @override
  ConsumerState<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _submitting = false;
  Uint8List? _imageBytes;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initial.firstName);
    _lastNameController = TextEditingController(text: widget.initial.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
        _imageBytes = Uint8List.fromList(result.files.single.bytes!);
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: widget.initial.email,
            userName: widget.initial.username,
            imageBase64: _imageBase64,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri spremanju: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: const Text('Uredi profil'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Ime'),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ime je obavezno';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Prezime'),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prezime je obavezno';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Profilna slika', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _AvatarPreview(
              imageBytes: _imageBytes,
              initial: widget.initial,
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _onSubmit,
              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Spremi'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.imageBytes, required this.initial});

  final Uint8List? imageBytes;
  final UserProfile initial;

  @override
  Widget build(BuildContext context) {
    const double size = 120;
    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Icon(Icons.person, size: 48, color: Colors.grey.shade600),
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

    if (initial.avatarUrl != null && initial.avatarUrl!.isNotEmpty) {
      if (initial.avatarUrl!.startsWith('data:')) {
        try {
          final String base64 = initial.avatarUrl!.split(',').last;
          final bytes = base64Decode(base64);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          );
        } catch (_) {
          return placeholder;
        }
      }
      return ClipOval(
        child: Image.network(
          initial.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    return placeholder;
  }
}

