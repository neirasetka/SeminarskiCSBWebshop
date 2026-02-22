import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/giveaways_provider.dart';
import '../domain/participant.dart';

/// Screen that shows the list of registered buyers (participants) who signed up for a giveaway.
/// Used by admin only.
class GiveawayParticipantsScreen extends ConsumerStatefulWidget {
  const GiveawayParticipantsScreen({
    super.key,
    required this.giveawayId,
    required this.giveawayTitle,
  });

  final int giveawayId;
  final String giveawayTitle;

  @override
  ConsumerState<GiveawayParticipantsScreen> createState() => _GiveawayParticipantsScreenState();
}

class _GiveawayParticipantsScreenState extends ConsumerState<GiveawayParticipantsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(participantsProvider.notifier).load(widget.giveawayId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<GiveawayParticipant>> participantsAsync = ref.watch(participantsProvider);

    return BackConfirmationWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: buildBackButtonWithConfirmation(context),
          title: const Text('Lista učesnika giveawaya'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.giveawayTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registrovani kupci koji su se prijavili na giveaway',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: participantsAsync.when(
                data: (List<GiveawayParticipant> list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nema prijavljenih učesnika',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final GiveawayParticipant p = list[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          p.name?.isNotEmpty == true ? p.name! : '(bez imena)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(p.emailOrMasked),
                        trailing: Text(
                          _formatDate(p.entryDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Greška pri učitavanju: $e', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}.';
  }
}
