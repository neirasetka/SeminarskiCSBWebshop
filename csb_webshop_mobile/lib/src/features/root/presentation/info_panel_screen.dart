import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../announcements/application/announcements_provider.dart';
import '../../announcements/domain/announcement.dart';
import '../../announcements/presentation/announcement_detail_screen.dart';

class InfoPanelScreen extends ConsumerWidget {
  const InfoPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Announcement>> announcementsAsync = ref.watch(announcementsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Info panel')),
      body: announcementsAsync.when(
        data: (List<Announcement> items) {
          return RefreshIndicator(
            onRefresh: () => ref.read(announcementsListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                const _InfoHeader(),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const _EmptyStateCard()
                else
                  ...items.map((Announcement announcement) => _AnnouncementCard(announcement: announcement)),
                const SizedBox(height: 16),
                const _GiveawayReminderCard(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => _ErrorCard(
          message: error.toString(),
          onRetry: () => ref.read(announcementsListProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Info panel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Centralno mjesto za sve obavijesti, najave torbica i brze podsjetnike.'),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  IconData _iconForType() {
    switch (announcement.type) {
      case AnnouncementType.announcement:
        return Icons.campaign_outlined;
      case AnnouncementType.update:
        return Icons.system_update_alt_outlined;
      case AnnouncementType.info:
      default:
        return Icons.info_outline;
    }
  }

  Color _badgeColor(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    switch (announcement.type) {
      case AnnouncementType.announcement:
        return colors.primary;
      case AnnouncementType.update:
        return colors.tertiary;
      case AnnouncementType.info:
      default:
        return colors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _badgeColor(context).withOpacity(0.15),
          foregroundColor: _badgeColor(context),
          child: Icon(_iconForType()),
        ),
        title: Text(announcement.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(_formatDate(announcement.publishedAt)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AnnouncementDetailScreen(id: announcement.id),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _GiveawayReminderCard extends StatelessWidget {
  const _GiveawayReminderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: const <Widget>[
                Icon(Icons.celebration_outlined),
                SizedBox(width: 8),
                Text('Giveaway podsjetnik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Prijave se zatvaraju u petak u 18:00h. Provjeri nagrade i uključi se!'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.go('/giveaways'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Otvori giveaway listu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Još nema novih obavijesti. Provjeri giveaway sekciju za uzbudljive nagrade!'),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Neuspješno učitavanje obavijesti', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Pokušaj ponovo')),
        ],
      ),
    );
  }
}
