import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/profile_api.dart';
import '../application/user_profile_provider.dart';
import '../domain/user_profile.dart';
import 'newsletter_subscribers_screen.dart';
import 'profile_update_screen.dart';
import '../../product_feedback/presentation/admin_reviews_screen.dart';
import '../../orders/presentation/admin_orders_screen.dart';
import '../../orders/presentation/order_history_screen.dart';
import '../../announcements/presentation/announcements_list_screen.dart';
import '../../giveaways/presentation/giveaways_list_screen.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.title,
    this.showBackToHome = false,
  });

  final String title;
  final bool showBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showBackToHome
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Natrag na početnu',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              )
            : null,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(userProfileProvider.notifier).refreshProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (UserProfile? profile) {
          if (profile == null) {
            return const Center(child: Text('Niste prijavljeni ili profil nije dostupan.'));
          }
          return _ProfileDetails(
            profile: profile,
            session: ref.watch(authControllerProvider).value,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Greška pri dohvaćanju profila'),
                const SizedBox(height: 8),
                Text(error.toString(), style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(userProfileProvider.notifier).refreshProfile(),
                  child: const Text('Pokušaj ponovno'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: profileAsync.maybeWhen(
        data: (UserProfile? profile) => profile != null
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final UserProfile? current = await ref.read(userProfileProvider.notifier).ensureLoaded();
                  if (!context.mounted) return;
                  if (current == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil trenutno nije dostupan. Pokušajte ponovo.'),
                      ),
                    );
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ProfileUpdateScreen(initial: current),
                    ),
                  );
                  await ref.read(userProfileProvider.notifier).refreshProfile();
                },
                icon: const Icon(Icons.edit),
                label: const Text('Uredi profil'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, this.session});

  final UserProfile profile;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget adminSection = _AdminActions();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text(
                        _initials(_initialsSource(profile, session)),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.username,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NewsletterSubscriptionCard(email: profile.email),
        const SizedBox(height: 16),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Kontakt informacije',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: profile.email,
              ),
              if (profile.phone != null && profile.phone!.isNotEmpty)
                _InfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Telefon',
                  value: profile.phone!,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Brze akcije',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const _OrdersQuickActionTile(),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Najave i obavijesti'),
                subtitle: const Text('Pratite novosti'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AnnouncementsListScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        adminSection,
      ],
    );
  }

  String _initialsSource(UserProfile profile, AuthSession? session) {
    String source = profile.fullName.trim();
    if (source.isEmpty) source = profile.username.trim();
    if (source.isEmpty) source = profile.email.trim();
    if (source.isEmpty) source = (session?.username ?? '').trim();
    return source;
  }

  String _initials(String name) {
    final String source = name.trim();
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final String p = parts.first;
      if (p.isEmpty) return '?';
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p[0].toUpperCase();
    }
    final String first = parts.first.isNotEmpty ? parts.first[0] : '';
    final String last = parts.last.isNotEmpty ? parts.last[0] : '';
    final String two = (first + last).toUpperCase();
    return two.isNotEmpty ? two : '?';
  }
}

class _NewsletterSubscriptionCard extends ConsumerStatefulWidget {
  const _NewsletterSubscriptionCard({required this.email});

  final String email;

  @override
  ConsumerState<_NewsletterSubscriptionCard> createState() => _NewsletterSubscriptionCardState();
}

class _NewsletterSubscriptionCardState extends ConsumerState<_NewsletterSubscriptionCard> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _subscribed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bool value = await ref.read(profileApiProvider).getNewCollectionSubscription(widget.email);
      if (!mounted) return;
      setState(() {
        _subscribed = value;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ne mogu učitati status newsletter pretplate.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri učitavanju newsletter statusa: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onChanged(bool? value) async {
    if (value == null || _isSaving) return;
    final bool previous = _subscribed;
    setState(() {
      _subscribed = value;
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(profileApiProvider).setNewCollectionSubscription(
            email: widget.email,
            subscribed: value,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Uspješno ste prijavljeni na newsletter za nove kolekcije.'
                : 'Uspješno ste odjavljeni sa newslettera za nove kolekcije.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subscribed = previous;
        _errorMessage = 'Spremanje nije uspjelo. Pokušajte ponovo.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri spremanju newsletter postavke: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    if (isAdminAsync.valueOrNull == true || isAdminAsync.isLoading) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Newsletter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _subscribed,
              onChanged: (_isLoading || _isSaving) ? null : _onChanged,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Želim primati obavijesti o novim kolekcijama'),
              subtitle: _isLoading
                  ? const Text('Učitavanje statusa...')
                  : const Text('Primajte newsletter mailove za nove torbice i kolekcije.'),
            ),
            if (_isSaving)
              const LinearProgressIndicator(),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrdersQuickActionTile extends ConsumerWidget {
  const _OrdersQuickActionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.receipt_long,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(isAdmin ? 'Lista narudžbi' : 'Narudžbe'),
      subtitle: Text(
        isAdmin ? 'Pregled svih narudžbi' : 'Pogledajte historiju narudžbi',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => isAdmin ? const AdminOrdersScreen() : const OrderHistoryScreen(),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}

class _AdminActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> isAdminAsync = ref.watch(adminRoleProvider);
    return isAdminAsync.when(
      data: (bool isAdmin) {
        if (!isAdmin) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Divider(height: 24),
            const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AdminReviewsScreen()),
              ),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Moderacija recenzija'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GiveawaysListScreen(forAdmin: true)),
              ),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Upravljanje giveawayima'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NewsletterSubscribersScreen()),
              ),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Lista newsletter pretplatnika'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
