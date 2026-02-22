import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/announcements_provider.dart';
import '../domain/announcement.dart';

/// Screen for admins to edit an existing announcement (title, body, type).
class AnnouncementEditScreen extends ConsumerStatefulWidget {
  const AnnouncementEditScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<AnnouncementEditScreen> createState() => _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState extends ConsumerState<AnnouncementEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  AnnouncementType _type = AnnouncementType.announcement;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _fillFromAnnouncement(Announcement a) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = a.title;
    _bodyController.text = a.body;
    _type = a.type;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final Announcement? updated = await ref.read(announcementsListProvider.notifier).updateAnnouncement(
        widget.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _type,
      );

      if (!mounted) return;

      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obavijest je spremljena.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri spremanju. Pokušajte ponovo.'),
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

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Announcement> announcementAsync = ref.watch(announcementDetailProvider);

    // Ensure we have data for this id (e.g. when opening edit directly)
    announcementAsync.whenOrNull(
      data: (Announcement a) {
        if (a.id != widget.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(announcementDetailProvider.notifier).fetch(widget.id);
          });
        }
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(announcementDetailProvider.notifier).fetch(widget.id);
        });
      },
    );

    return announcementAsync.when(
      data: (Announcement a) {
        _fillFromAnnouncement(a);
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return BackConfirmationWrapper(
          child: Scaffold(
            appBar: AppBar(
              leading: buildBackButtonWithConfirmation(context),
              title: const Text('Uredi obavijest'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Naslov',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Naslov je obavezan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: 'Sadržaj',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      maxLines: 6,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Sadržaj je obavezan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<AnnouncementType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: 'Tip',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      items: AnnouncementType.values
                          .map((AnnouncementType t) => DropdownMenuItem<AnnouncementType>(
                                value: t,
                                child: Text(t.displayLabel),
                              ))
                          .toList(),
                      onChanged: (AnnouncementType? value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _close,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Odustani'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Spremi'),
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
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Uredi obavijest')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace st) => Scaffold(
        appBar: AppBar(title: const Text('Uredi obavijest')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Greška pri učitavanju obavijesti'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(announcementDetailProvider.notifier).fetch(widget.id),
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
