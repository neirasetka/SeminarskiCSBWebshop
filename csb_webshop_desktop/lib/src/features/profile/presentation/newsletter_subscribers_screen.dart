import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/user_profile_provider.dart';
import '../data/profile_api.dart';

class NewsletterSubscribersScreen extends ConsumerStatefulWidget {
  const NewsletterSubscribersScreen({super.key});

  @override
  ConsumerState<NewsletterSubscribersScreen> createState() => _NewsletterSubscribersScreenState();
}

class _NewsletterSubscribersScreenState extends ConsumerState<NewsletterSubscribersScreen> {
  late Future<List<NewsletterSubscriber>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSubscribers();
  }

  Future<List<NewsletterSubscriber>> _loadSubscribers() {
    return ref.read(profileApiProvider).getNewsletterSubscribers();
  }

  Future<void> _refresh() async {
    final Future<List<NewsletterSubscriber>> next = _loadSubscribers();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pretplatnici na newsletter'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<NewsletterSubscriber>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<NewsletterSubscriber>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Greška pri učitavanju pretplatnika.'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<NewsletterSubscriber> subscribers = snapshot.data ?? <NewsletterSubscriber>[];
          if (subscribers.isEmpty) {
            return const Center(child: Text('Trenutno nema pretplatnika.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: subscribers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final NewsletterSubscriber item = subscribers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(item.email),
                  subtitle: Text(
                    item.isSubscribedToGiveaway
                        ? 'Pretplaćen i na giveaway newsletter'
                        : 'Samo newsletter novih kolekcija',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
