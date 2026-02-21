import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../announcements/application/announcements_provider.dart';
import '../../announcements/domain/announcement.dart';
import '../../giveaways/application/giveaways_provider.dart';
import '../../giveaways/domain/giveaway.dart';

/// A panel displaying important announcements and active giveaway reminders
/// on the homepage.
class InfoPanel extends ConsumerWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Obavijesti',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Active Giveaways Section
                  _GiveawayReminderSection(),
                  const SizedBox(height: 16),
                  // Recent Announcements Section
                  _AnnouncementsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section displaying active giveaway reminders
class _GiveawayReminderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<List<Giveaway>> giveawaysAsync = ref.watch(giveawaysListProvider);

    return giveawaysAsync.when(
      loading: () => const _LoadingTile(),
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (List<Giveaway> giveaways) {
        final List<Giveaway> activeGiveaways = giveaways.where((Giveaway g) => g.isActiveNow).toList();
        
        if (activeGiveaways.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.card_giftcard_rounded,
                  color: colorScheme.tertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktivni Giveaway',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...activeGiveaways.map((Giveaway giveaway) => _GiveawayReminderTile(giveaway: giveaway)),
          ],
        );
      },
    );
  }
}

/// Tile displaying a single giveaway reminder
class _GiveawayReminderTile extends StatelessWidget {
  const _GiveawayReminderTile({required this.giveaway});

  final Giveaway giveaway;

  String _formatTimeRemaining(DateTime endDate) {
    final Duration remaining = endDate.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Završeno';
    
    if (remaining.inDays > 0) {
      return 'Još ${remaining.inDays} ${remaining.inDays == 1 ? 'dan' : 'dana'}';
    } else if (remaining.inHours > 0) {
      return 'Još ${remaining.inHours} ${remaining.inHours == 1 ? 'sat' : 'sati'}';
    } else {
      return 'Završava uskoro!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String timeRemaining = _formatTimeRemaining(giveaway.endDate);
    final bool isEndingSoon = giveaway.endDate.difference(DateTime.now().toUtc()).inHours < 24;

    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEndingSoon ? colorScheme.error.withOpacity(0.5) : colorScheme.tertiaryContainer,
          width: isEndingSoon ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/giveaways'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                giveaway.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onTertiaryContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    isEndingSoon ? Icons.timer_outlined : Icons.schedule_outlined,
                    size: 14,
                    color: isEndingSoon ? colorScheme.error : colorScheme.onTertiaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeRemaining,
                    style: textTheme.bodySmall?.copyWith(
                      color: isEndingSoon ? colorScheme.error : colorScheme.onTertiaryContainer.withOpacity(0.7),
                      fontWeight: isEndingSoon ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Prijavi se →',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section displaying recent announcements
class _AnnouncementsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<List<Announcement>> announcementsAsync = ref.watch(announcementsListProvider);

    return announcementsAsync.when(
      loading: () => const _LoadingTile(),
      error: (Object error, StackTrace stack) => _ErrorTile(message: 'Greška pri učitavanju obavijesti'),
      data: (List<Announcement> announcements) {
        if (announcements.isEmpty) {
          return const _EmptyTile(message: 'Nema novih obavijesti');
        }

        // Sort by date and take the most recent 3
        final List<Announcement> recentAnnouncements = List<Announcement>.from(announcements)
          ..sort((Announcement a, Announcement b) => b.publishedAt.compareTo(a.publishedAt));
        final List<Announcement> displayAnnouncements = recentAnnouncements.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.campaign_outlined,
                  color: colorScheme.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Najave & Obavijesti',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...displayAnnouncements.map((Announcement announcement) => 
              _AnnouncementTile(announcement: announcement),
            ),
            if (announcements.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => context.go('/announcements'),
                  child: Text(
                    'Pogledaj sve obavijesti (${announcements.length})',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tile displaying a single announcement
class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});

  final Announcement announcement;

  IconData _getIconForType(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.announcement:
        return Icons.new_releases_outlined;
      case AnnouncementType.update:
        return Icons.system_update_outlined;
      case AnnouncementType.info:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(AnnouncementType type, ColorScheme colorScheme) {
    switch (type) {
      case AnnouncementType.announcement:
        return colorScheme.primary;
      case AnnouncementType.update:
        return colorScheme.secondary;
      case AnnouncementType.info:
        return colorScheme.tertiary;
    }
  }

  String _formatDate(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Upravo sada';
      }
      return 'Prije ${diff.inHours} ${diff.inHours == 1 ? 'sat' : 'sati'}';
    } else if (diff.inDays == 1) {
      return 'Jučer';
    } else if (diff.inDays < 7) {
      return 'Prije ${diff.inDays} dana';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color typeColor = _getColorForType(announcement.type, colorScheme);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/announcements/${announcement.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForType(announcement.type),
                  size: 18,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            announcement.type.displayLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(announcement.publishedAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      announcement.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder tile
class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Error tile
class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state tile
class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          message,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
