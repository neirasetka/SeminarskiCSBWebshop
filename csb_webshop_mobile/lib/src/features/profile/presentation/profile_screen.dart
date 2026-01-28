import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/user_profile_provider.dart';
import '../domain/user_profile.dart';
import 'profile_update_screen.dart';
import '../../orders/presentation/order_history_screen.dart';
import '../../announcements/presentation/announcements_list_screen.dart';
import '../../giveaways/presentation/giveaways_list_screen.dart';
import '../../auth/application/admin_role_provider.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
          return _ProfileDetails(profile: profile);
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
      floatingActionButton: profileAsync.hasValue && profileAsync.value != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final UserProfile? current = ref.read(userProfileProvider).value;
                if (current == null) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ProfileUpdateScreen(initial: current),
                  ),
                );
                // After returning, refresh to ensure data is up to date
                await ref.read(userProfileProvider.notifier).refreshProfile();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Uredi profil'),
            )
          : null,
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget adminSection = _AdminActions();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Profile header card
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
                      backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                          ? Text(
                              _initials(profile.fullName),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
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
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
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
                  '@${profile.username}',
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
        // Contact info card
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Kontakt informacije',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        // Quick actions card
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Brze akcije',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: const Text('Moje narudžbe'),
                subtitle: const Text('Pogledajte povijest narudžbi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.campaign_outlined, color: theme.colorScheme.onSecondaryContainer),
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

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r"\s+"));
    final String first = parts.isNotEmpty ? parts.first : '';
    final String last = parts.length > 1 ? parts.last : '';
    return (first.isNotEmpty ? first[0] : '') + (last.isNotEmpty ? last[0] : '');
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
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                MaterialPageRoute<void>(builder: (_) => const GiveawaysListScreen(forAdmin: true)),
              ),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Upravljanje giveawayima'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

