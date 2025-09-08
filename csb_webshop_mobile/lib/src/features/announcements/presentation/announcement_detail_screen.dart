import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/announcements_provider.dart';
import '../domain/announcement.dart';

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  const AnnouncementDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(() => ref.read(announcementDetailProvider.notifier).fetch(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Announcement> announcementAsync = ref.watch(announcementDetailProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji obavijesti')),
      body: announcementAsync.when(
        data: (Announcement a) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  _TypeBadge(type: a.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(a.publishedAt),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(a.body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Greška pri dohvaćanju detalja'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
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

  String _formatDate(DateTime dt) {
    final DateTime local = dt.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (type) {
      case AnnouncementType.announcement:
        bg = colors.primaryContainer;
        fg = colors.onPrimaryContainer;
        break;
      case AnnouncementType.update:
        bg = colors.tertiaryContainer;
        fg = colors.onTertiaryContainer;
        break;
      case AnnouncementType.info:
      default:
        bg = colors.secondaryContainer;
        fg = colors.onSecondaryContainer;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.displayLabel,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

