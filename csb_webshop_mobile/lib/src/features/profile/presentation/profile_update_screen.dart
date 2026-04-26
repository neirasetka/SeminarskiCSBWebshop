import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
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

  void _onNameFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initial.firstName,
    );
    _lastNameController = TextEditingController(text: widget.initial.lastName);
    _phoneController = TextEditingController(text: widget.initial.phone ?? '');
    _firstNameController.addListener(_onNameFieldChanged);
    _lastNameController.addListener(_onNameFieldChanged);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameFieldChanged);
    _lastNameController.removeListener(_onNameFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text(
                        _previewInitials(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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

  String _previewDisplaySource() {
    final String a = _firstNameController.text.trim();
    final String b = _lastNameController.text.trim();
    if (a.isNotEmpty || b.isNotEmpty) {
      return '$a $b'.trim();
    }
    String source = widget.initial.fullName.trim();
    if (source.isEmpty) source = widget.initial.username.trim();
    if (source.isEmpty) source = widget.initial.email.trim();
    if (source.isEmpty) {
      source =
          (ref.read(authControllerProvider).value?.username ?? '').trim();
    }
    return source;
  }

  String _previewInitials() {
    return _initialsFromDisplay(_previewDisplaySource());
  }

  /// Usklađeno s prikazom na ekranu profila (uključuje jednu riječ / email).
  String _initialsFromDisplay(String raw) {
    String source =
        raw.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final String p = parts.first;
      if (p.isEmpty) return '?';
      return p.length >= 2
          ? p.substring(0, 2).toUpperCase()
          : p[0].toUpperCase();
    }
    final String first = parts.first.isNotEmpty ? parts.first[0] : '';
    final String last = parts.last.isNotEmpty ? parts.last[0] : '';
    final String two = (first + last).toUpperCase();
    return two.isNotEmpty ? two : '?';
  }
}
