import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/announcements_provider.dart';
import '../domain/announcement.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsListScreen extends ConsumerWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Announcement>> announcementsAsync = ref.watch(announcementsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Najave i obavijesti')),
      body: announcementsAsync.when(
        data: (List<Announcement> items) {
          if (items.isEmpty) return const Center(child: Text('Nema obavijesti.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Announcement a = items[index];
              return ListTile(
                leading: _TypeBadge(type: a.type),
                title: Text(a.title),
                subtitle: Text(_formatDate(a.publishedAt)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AnnouncementDetailScreen(id: a.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Greška pri dohvaćanju obavijesti'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.read(announcementsListProvider.notifier).refresh(),
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

