import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/collections_provider.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, Set<int>>> collectionsAsync = ref.watch(collectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Moje kolekcije')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String? name = await _promptText(context, 'Nova kolekcija', 'Naziv kolekcije');
          if (name != null && name.trim().isNotEmpty) {
            // Creating empty collection: add and remove placeholder ensures persistence
            await ref.read(collectionsProvider.notifier).addToCollection(collectionName: name.trim(), bagId: -1);
            await ref.read(collectionsProvider.notifier).removeFromCollection(collectionName: name.trim(), bagId: -1);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: collectionsAsync.when(
        data: (Map<String, Set<int>> map) {
          if (map.isEmpty) {
            return const Center(child: Text('Još nema kreiranih kolekcija.'));
          }
          final List<MapEntry<String, Set<int>>> entries = map.entries.toList()
            ..sort((MapEntry<String, Set<int>> a, MapEntry<String, Set<int>> b) => a.key.compareTo(b.key));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final MapEntry<String, Set<int>> e = entries[index];
              return Card(
                child: ListTile(
                  title: Text(e.key),
                  subtitle: Text('${e.value.length} torbica'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String v) async {
                      if (v == 'rename') {
                        final String? newName = await _promptText(context, 'Preimenuj', 'Novi naziv', e.key);
                        if (newName != null && newName.trim().isNotEmpty) {
                          await ref.read(collectionsProvider.notifier).renameCollection(oldName: e.key, newName: newName.trim());
                        }
                      } else if (v == 'delete') {
                        final bool? ok = await _confirm(context, 'Obriši kolekciju', 'Obrisati "${e.key}"?');
                        if (ok == true) {
                          await ref.read(collectionsProvider.notifier).removeCollection(e.key);
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(value: 'rename', child: Text('Preimenuj')),
                      PopupMenuItem<String>(value: 'delete', child: Text('Obriši')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Greška pri učitavanju kolekcija'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(collectionsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovno'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _promptText(BuildContext context, String title, String label, [String initial = '']) async {
    final TextEditingController ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: label)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text), child: const Text('Sačuvaj')),
        ],
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Potvrdi')),
        ],
      ),
    );
  }
}

