import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../giveaways/application/giveaways_provider.dart';
import '../../giveaways/domain/giveaway.dart';
import '../../giveaways/domain/participant.dart';
import '../../giveaways/data/giveaways_api.dart';
import 'giveaway_participants_screen.dart';

class GiveawaysListScreen extends ConsumerWidget {
  const GiveawaysListScreen({super.key, this.forAdmin = false});

  final bool forAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Giveaway>> listAsync = ref.watch(giveawaysListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(forAdmin ? 'Giveaway administracija' : 'Giveawayi')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                FilterChip(
                  label: const Text('Aktivni'),
                  selected: false,
                  onSelected: (_) => ref.read(giveawaysListProvider.notifier).filter('active'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Završeni'),
                  selected: false,
                  onSelected: (_) => ref.read(giveawaysListProvider.notifier).filter('closed'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref.read(giveawaysListProvider.notifier).filter('all'),
                  child: const Text('Svi'),
                ),
                const Spacer(),
                if (forAdmin)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _CreateGiveawaySheet(),
                      );
                      await ref.read(giveawaysListProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Kreiraj'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              data: (List<Giveaway> items) => ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Giveaway g = items[index];
                  return ListTile(
                    title: Text(g.title),
                    subtitle: Text('${g.startDate.toLocal()} — ${g.endDate.toLocal()}'),
                    trailing: Chip(
                      label: Text(g.isClosed ? 'Zatvoren' : (g.isActiveNow ? 'Aktivan' : 'Planiran')),
                      backgroundColor: g.isClosed
                          ? Colors.grey.shade300
                          : g.isActiveNow
                              ? Colors.green.shade100
                              : Colors.amber.shade100,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GiveawayDetailScreen(giveawayId: g.id, forAdmin: forAdmin),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace st) => Center(child: Text('Greška: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class GiveawayDetailScreen extends ConsumerStatefulWidget {
  const GiveawayDetailScreen({super.key, required this.giveawayId, this.forAdmin = false});

  final int giveawayId;
  final bool forAdmin;

  @override
  ConsumerState<GiveawayDetailScreen> createState() => _GiveawayDetailScreenState();
}

class _GiveawayDetailScreenState extends ConsumerState<GiveawayDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(giveawayDetailProvider.notifier).fetch(widget.giveawayId);
      ref.read(participantsProvider.notifier).load(widget.giveawayId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Giveaway> giveawayAsync = ref.watch(giveawayDetailProvider);
    final AsyncValue<List<GiveawayParticipant>> participantsAsync = ref.watch(participantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giveaway detalji')),
      body: giveawayAsync.when(
        data: (Giveaway g) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(g.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Od: ${g.startDate.toLocal()} — Do: ${g.endDate.toLocal()}'),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              const Text('Status: '),
              Chip(
                label: Text(g.isClosed ? 'Zatvoren' : (g.isActiveNow ? 'Aktivan' : 'Planiran')),
              ),
            ]),
            const SizedBox(height: 16),
            if (!widget.forAdmin)
              _RegisterCard(giveawayId: widget.giveawayId, isActive: g.isActiveNow && !g.isClosed),
            if (widget.forAdmin) _AdminActions(giveawayId: widget.giveawayId, isClosed: g.isClosed),
            if (widget.forAdmin) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GiveawayParticipantsScreen(
                      giveawayId: widget.giveawayId,
                      giveawayTitle: g.title,
                    ),
                  ),
                ),
                icon: const Icon(Icons.people),
                label: const Text('Lista učesnika giveawaya'),
              ),
            ],
            const SizedBox(height: 16),
            if (widget.forAdmin) ...[
              const Text('Prijavljeni (pregled):'),
              const SizedBox(height: 8),
              participantsAsync.when(
                data: (List<GiveawayParticipant> list) => Column(
                  children: list
                      .map((GiveawayParticipant p) => ListTile(
                            title: Text(p.name?.isNotEmpty == true ? p.name! : '(bez imena)'),
                            subtitle: Text(p.emailOrMasked),
                            trailing: Text(p.entryDate.toLocal().toString()),
                          ))
                      .toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Text('Greška: $e'),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(child: Text('Greška: $e')),
      ),
    );
  }
}

class _RegisterCard extends ConsumerWidget {
  const _RegisterCard({required this.giveawayId, required this.isActive});

  final int giveawayId;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Prijavi se na giveaway'),
            const SizedBox(height: 8),
            Form(
              key: formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Ime (opcionalno)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return 'Email je obavezan';
                      final String val = v.trim();
                      final RegExp re = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$");
                      if (!re.hasMatch(val)) return 'Unesite ispravan email';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: !isActive
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      try {
                        await api.registerParticipant(
                          giveawayId: giveawayId,
                          name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prijava uspješna')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Greška pri prijavi: $e')));
                        }
                      }
                    },
              icon: const Icon(Icons.how_to_vote),
              label: const Text('Prijavi se'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActions extends ConsumerWidget {
  const _AdminActions({required this.giveawayId, required this.isClosed});

  final int giveawayId;
  final bool isClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: isClosed
              ? null
              : () async {
                  try {
                    final GiveawayParticipant winner = await api.drawWinner(giveawayId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Pobjednik: ${winner.emailOrMasked}')));
                    }
                    await ref.read(participantsProvider.notifier).load(giveawayId);
                    await ref.read(giveawaysListProvider.notifier).refresh();
                    await ref.read(giveawayDetailProvider.notifier).fetch(giveawayId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Greška pri izvlačenju: $e')));
                    }
                  }
                },
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('Izvuci pobjednika'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
          onPressed: !isClosed
              ? null
              : () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext ctx) => AlertDialog(
                      title: const Text('Objavi pobjednika'),
                      content: const Text(
                        'Ova akcija će:\n'
                        '• Objaviti pobjednika na Info Panel (novosti)\n'
                        '• Poslati email pobjedniku\n'
                        '• Poslati email svim pretplatnicima na giveaway newsletter\n\n'
                        'Nastaviti?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Odustani'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Objavi'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  
                  try {
                    final AnnounceWinnerResult result = await api.announceWinner(giveawayId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pobjednik ${result.winnerName ?? ""} objavljen! '
                            'Obaviješteno pretplatnika: ${result.subscribersNotified}',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Greška pri objavi: $e')));
                    }
                  }
                },
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Objavi pobjednika'),
        ),
        OutlinedButton.icon(
          onPressed: !isClosed
              ? null
              : () async {
                  try {
                    await api.notifyWinner(giveawayId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Pobjednik obaviješten emailom')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Greška pri slanju maila: $e')));
                    }
                  }
                },
          icon: const Icon(Icons.mail_outline),
          label: const Text('Samo email pobjedniku'),
        ),
      ],
    );
  }
}

class _CreateGiveawaySheet extends ConsumerStatefulWidget {
  const _CreateGiveawaySheet();

  @override
  ConsumerState<_CreateGiveawaySheet> createState() => _CreateGiveawaySheetState();
}

class _CreateGiveawaySheetState extends ConsumerState<_CreateGiveawaySheet> {
  final TextEditingController _title = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Novi giveaway', style: TextStyle(fontWeight: FontWeight.bold)),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Naslov'),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) return 'Naslov je obavezan';
                  if (v.trim().length < 3) return 'Naslov mora imati bar 3 znaka';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: _start,
                    );
                    if (picked != null) setState(() => _start = picked);
                  },
                  child: Text('Start: ${_start.toLocal().toString().split(' ').first}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      firstDate: _start,
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDate: _end,
                    );
                    if (picked != null) setState(() => _end = picked);
                  },
                  child: Text('Kraj: ${_end.toLocal().toString().split(' ').first}'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  if (!_end.isAfter(_start)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kraj mora biti nakon starta')));
                    return;
                  }
                  try {
                    await api.createGiveaway(title: _title.text.trim(), startDate: _start, endDate: _end);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Greška: $e')));
                    }
                  }
                },
                child: const Text('Kreiraj'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

