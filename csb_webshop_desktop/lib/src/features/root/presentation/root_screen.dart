import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
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

/// Logo widget za AppBar - prikazuje stiliziranu torbicu
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(
            Icons.shopping_bag,
            color: Colors.white.withValues(alpha: 0.3),
            size: 32,
          ),
          const Positioned(
            top: 8,
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
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
    final String welcomeName = profile?.firstName ?? session?.username ?? '';
    final String welcomeText = welcomeName.isNotEmpty ? 'Dobro došli, $welcomeName!' : 'Dobro došli!';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: _AppLogo(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              welcomeText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: <Widget>[
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
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AuthSession?> sessionAsync = ref.read(authControllerProvider);
    final AuthSession? session = sessionAsync.valueOrNull;
    
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        final String? fullName = profile?.fullName;
        final bool hasFullName = fullName != null && fullName.isNotEmpty;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Profile header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _avatarImage(profile),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: _shouldShowInitials(profile)
                          ? Text(
                              _avatarInitials(profile, session),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            hasFullName ? fullName! : 'Korisnik',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${profile?.username ?? session?.username ?? ''}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          if (profile?.email != null && profile!.email.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              profile.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Aktivan',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Menu items
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_outline, size: 20, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: const Text('Moj profil'),
                subtitle: const Text('Pregled korisničkih podataka'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _index = 3);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSecondaryContainer),
                ),
                title: const Text('Uredi podatke'),
                subtitle: const Text('Promijeni ime, telefon...'),
                trailing: const Icon(Icons.chevron_right, size: 20),
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long_outlined, size: 20, color: theme.colorScheme.onTertiaryContainer),
                ),
                title: const Text('Moje narudžbe'),
                subtitle: const Text('Povijest kupovine'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.logout, size: 20, color: Colors.red.shade700),
                ),
                title: Text('Odjava', style: TextStyle(color: Colors.red.shade700)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

