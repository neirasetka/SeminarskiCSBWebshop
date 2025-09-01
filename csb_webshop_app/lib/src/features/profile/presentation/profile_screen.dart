import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/user_profile_provider.dart';
import '../domain/user_profile.dart';
import 'profile_update_screen.dart';
import '../../orders/presentation/order_history_screen.dart';
import '../../announcements/presentation/announcements_list_screen.dart';
import '../../giveaways/presentation/giveaways_list_screen.dart';
import '../../auth/application/admin_role_provider.dart';

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
    final Widget adminSection = _AdminActions();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? Text(
                    _initials(profile.fullName),
                    style: const TextStyle(fontSize: 24),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        _infoTile(title: 'Ime i prezime', value: profile.fullName),
        _infoTile(title: 'Email', value: profile.email),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
          ),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Moje narudžbe'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AnnouncementsListScreen()),
          ),
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Najave i obavijesti'),
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

  Widget _infoTile({required String title, required String value}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
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

