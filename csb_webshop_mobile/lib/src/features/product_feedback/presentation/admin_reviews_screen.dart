import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/status_badge.dart';
import '../application/admin_reviews_provider.dart';
import '../domain/product_feedback.dart';

/// Admin moderacija recenzija (Pending → Approved / Rejected).
class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  static const List<(String key, String label)> _filters = <(String, String)>[
    ('Pending', 'Na čekanju'),
    ('Approved', 'Odobrene'),
    ('Rejected', 'Odbijene'),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProductReview>> reviewsAsync = ref.watch(adminReviewsProvider);
    final String activeFilter = ref.watch(adminReviewsProvider.notifier).statusFilter;
    final DateFormat dateFormat = DateFormat('dd.MM.yyyy. HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderacija recenzija'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Osvježi',
            onPressed: () => ref.read(adminReviewsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: _filters.map(((String key, String label) filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.$2),
                    selected: activeFilter == filter.$1,
                    onSelected: (_) =>
                        ref.read(adminReviewsProvider.notifier).refresh(statusKey: filter.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.read(adminReviewsProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (List<ProductReview> reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Text(
                      activeFilter == 'Pending'
                          ? 'Nema recenzija na čekanju.'
                          : 'Nema recenzija u ovom filteru.',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminReviewsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final ProductReview review = reviews[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      review.userDisplayName ?? 'Kupac #${review.userId}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  StatusBadge(status: review.statusBadgeKey),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${review.productLabel} · ${dateFormat.format(review.date.toLocal())}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(review.comment),
                              if (activeFilter == 'Pending') ...<Widget>[
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    FilledButton.icon(
                                      onPressed: () => _moderate(
                                        review.id,
                                        approve: true,
                                      ),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Odobri'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _moderate(
                                        review.id,
                                        approve: false,
                                      ),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Odbij'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moderate(int reviewId, {required bool approve}) async {
    try {
      if (approve) {
        await ref.read(adminReviewsProvider.notifier).approve(reviewId);
      } else {
        await ref.read(adminReviewsProvider.notifier).reject(reviewId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Recenzija je odobrena.' : 'Recenzija je odbijena.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    }
  }
}
