import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../../profile/application/user_profile_provider.dart';
import '../../profile/domain/user_profile.dart';
import '../application/events_provider.dart';
import '../domain/event.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    // kick off fetch
    Future<void>.microtask(() => ref.read(eventDetailProvider.notifier).fetch(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EventModel> eventAsync = ref.watch(eventDetailProvider);
    return BackConfirmationWrapper(
      child: Scaffold(
      appBar: AppBar(
        leading: buildBackButtonWithConfirmation(context),
        title: const Text('Event detalji'),
      ),
      body: eventAsync.when(
        data: (EventModel event) => _EventBody(event: event),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Greška pri učitavanju eventa'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(eventDetailProvider.notifier).fetch(widget.eventId),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovno'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> userAsync = ref.watch(userProfileProvider);
    final AsyncValue<Duration> countdown = ref.watch(countdownProvider(event.startDateTime));

    final String countdownText = countdown.when(
      data: (Duration d) {
        final int total = d.inSeconds;
        if (total <= 0) return 'Počinje sada';
        final int h = d.inHours;
        final int m = d.inMinutes % 60;
        final int s = d.inSeconds % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      },
      loading: () => '...',
      error: (_, __) => '—',
    );

    final bool participating = event.isParticipating;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(event.description),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Icon(Icons.schedule),
            const SizedBox(width: 8),
            Text('Početak: ${event.startDateTime.toLocal()}'),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Vrijeme do početka', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(countdownText, style: const TextStyle(fontFeatures: <FontFeature>[], fontSize: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        userAsync.when(
          data: (UserProfile? user) {
            return ElevatedButton.icon(
                  onPressed: participating || user == null
                  ? null
                  : () async {
                      await ref.read(eventDetailProvider.notifier).participate(
                        name: user.fullName,
                        email: user.email,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Prijava uspješna')),
                        );
                      }
                    },
              icon: Icon(participating ? Icons.check : Icons.how_to_vote),
              label: Text(participating ? 'Prijavljeni ste' : 'Prijavi se'),
            );
          },
          loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: 8),
        if ((event.participants?.isNotEmpty ?? false))
          Text('Broj učesnika: ${event.participants!.length}'),
      ],
    );
  }
}

