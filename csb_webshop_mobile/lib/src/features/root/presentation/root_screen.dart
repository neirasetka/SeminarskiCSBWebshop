import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../../announcements/presentation/add_announcement_screen.dart';
import '../../bags/presentation/bags_list_screen.dart';
import '../../belts/presentation/belts_list_screen.dart';
import '../../giveaways/presentation/giveaways_list_screen.dart';
import '../../orders/presentation/cart_screen.dart';
import '../../orders/presentation/order_history_screen.dart';
import '../../profile/application/user_profile_provider.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/profile_update_screen.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key, required this.title, this.initialIndex = 0});

  final String title;
  final int initialIndex;

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthSession?> sessionAsync = ref.watch(authControllerProvider);
    final AsyncValue<UserProfile?> profileAsync = ref.watch(userProfileProvider);
    final AuthSession? session = sessionAsync.valueOrNull;
    final UserProfile? profile = profileAsync.valueOrNull;

    final List<Widget> pages = <Widget>[
      const BagsListScreen(),
      const BeltsListScreen(),
      const CartScreen(),
      ProfileScreen(title: widget.title),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Nova najava',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddAnnouncementScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Info panel',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.go('/info-panel'),
          ),
          IconButton(
            tooltip: 'Kaiševi',
            icon: const Icon(Icons.checkroom_outlined),
            onPressed: () => context.go('/belts'),
          ),
          IconButton(
            tooltip: 'Izvještaji',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.go('/reports'),
          ),
          IconButton(
            tooltip: 'Checkout demo',
            icon: const Icon(Icons.payment_outlined),
            onPressed: () => context.go('/checkout'),
          ),
          IconButton(
            tooltip: 'Lookbook',
            icon: const Icon(Icons.grid_view_outlined),
            onPressed: () => context.go('/lookbook'),
          ),
          IconButton(
            tooltip: 'Kolekcije',
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () => context.go('/collections'),
          ),
          if (sessionAsync.isLoading && session == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (session != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Tooltip(
                message: 'Moj račun',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showUserMenu(profile),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: _avatarImage(profile),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    child: _shouldShowInitials(profile)
                        ? Text(
                            _avatarInitials(profile, session),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const GiveawaysListScreen()),
          );
        },
        label: const Text('Giveawayi'),
        icon: const Icon(Icons.celebration_outlined),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (int i) => setState(() => _index = i),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Torbe'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Kaiševi'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Korpa'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  ImageProvider<Object>? _avatarImage(UserProfile? profile) {
    final String? url = profile?.avatarUrl;
    if (url == null || url.isEmpty) return null;
    return NetworkImage(url);
  }

  bool _shouldShowInitials(UserProfile? profile) {
    final String? url = profile?.avatarUrl;
    return url == null || url.isEmpty;
  }

  String _avatarInitials(UserProfile? profile, AuthSession? session) {
    final String source = (profile?.fullName ?? session?.username ?? '').trim();
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.length >= 2 ? parts.first.substring(0, 2).toUpperCase() : parts.first[0].toUpperCase();
    }
    final String first = parts.first.isNotEmpty ? parts.first[0] : '';
    final String last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _showUserMenu(UserProfile? profile) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final String? fullName = profile?.fullName;
        final bool hasFullName = fullName != null && fullName.isNotEmpty;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(hasFullName ? fullName! : 'Moj profil'),
                subtitle: Text(profile?.email ?? 'Pregled korisničkih podataka'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _index = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Moje narudžbe'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Uredi korisničke podatke'),
                enabled: profile != null,
                onTap: profile == null
                    ? null
                    : () async {
                        Navigator.of(sheetContext).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfileUpdateScreen(initial: profile),
                          ),
                        );
                        await ref.read(userProfileProvider.notifier).refreshProfile();
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

