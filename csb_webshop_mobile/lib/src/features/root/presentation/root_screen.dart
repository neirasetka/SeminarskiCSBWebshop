import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/admin_role_provider.dart';
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
import '../../lookbook/presentation/lookbook_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../recommendations/presentation/recommendations_screen.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key, required this.title, this.initialIndex = 0});

  final String title;
  final int initialIndex;

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

/// Logo widget za AppBar - prikazuje stiliziranu torbicu
class _AppLogo extends StatelessWidget {
  const _AppLogo({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
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
            size: size * 0.72,
          ),
          Positioned(
            top: size * 0.18,
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: size * 0.63,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glavni meni gumb za Home Screen
class _MainMenuButton extends StatelessWidget {
  const _MainMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Screen sa glavnim meni gumbima (buyer-only na mobilu)
class _HomeMenuScreen extends StatelessWidget {
  const _HomeMenuScreen({
    required this.onTorbice,
    required this.onKaisevi,
    required this.onFavoriti,
    required this.onZaVas,
    required this.onGiveaway,
    required this.onLookbook,
  });

  final VoidCallback onTorbice;
  final VoidCallback onKaisevi;
  final VoidCallback onFavoriti;
  final VoidCallback onZaVas;
  final VoidCallback onGiveaway;
  final VoidCallback onLookbook;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.0,
              children: <Widget>[
                _MainMenuButton(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Torbice',
                  color: colors.primary,
                  onTap: onTorbice,
                ),
                _MainMenuButton(
                  icon: Icons.checkroom_outlined,
                  label: 'Kaiševi',
                  color: colors.secondary,
                  onTap: onKaisevi,
                ),
                _MainMenuButton(
                  icon: Icons.favorite_outline,
                  label: 'Favoriti',
                  color: Colors.pink,
                  onTap: onFavoriti,
                ),
                _MainMenuButton(
                  icon: Icons.recommend_outlined,
                  label: 'Za vas',
                  color: colors.tertiary,
                  onTap: onZaVas,
                ),
                _MainMenuButton(
                  icon: Icons.celebration_outlined,
                  label: 'Giveaway',
                  color: Colors.orange,
                  onTap: onGiveaway,
                ),
                _MainMenuButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Lookbook',
                  color: Colors.purple,
                  onTap: onLookbook,
                ),
              ],
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

  void _navigateToPage(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthSession?> sessionAsync = ref.watch(
      authControllerProvider,
    );
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;
    final AsyncValue<UserProfile?> profileAsync = ref.watch(
      userProfileProvider,
    );
    final AuthSession? session = sessionAsync.value;
    final UserProfile? profile = profileAsync.value;

    final List<Widget> pages = <Widget>[
      // 0 - Home Menu
      _HomeMenuScreen(
        onTorbice: () => _navigateToPage(1),
        onKaisevi: () => _navigateToPage(2),
        onFavoriti: () => _navigateToPage(3),
        onZaVas: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RecommendationsScreen()),
        ),
        onGiveaway: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GiveawaysListScreen()),
        ),
        onLookbook: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const LookbookScreen())),
      ),
      // 1 - Torbice
      const BagsListScreen(),
      // 2 - Kaiševi
      const BeltsListScreen(),
      // 3 - Favoriti
      const FavoritesScreen(),
      if (!isAdmin) ...<Widget>[
        // 4 - Korpa
        const CartScreen(),
      ],
      // Profil
      ProfileScreen(title: widget.title),
    ];
    final int currentIndex = _index.clamp(0, pages.length - 1).toInt();
    final String welcomeName = profile?.firstName ?? session?.username ?? '';
    final String welcomeText = welcomeName.isNotEmpty
        ? 'Dobro došli, $welcomeName!'
        : 'Dobro došli!';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => _navigateToPage(0),
            child: const _AppLogo(),
          ),
        ),
        title: GestureDetector(
          onTap: () => _navigateToPage(0),
          child: Column(
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          if (!isAdmin)
            IconButton(
              tooltip: 'Korpa',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => _navigateToPage(4),
            ),
          // User avatar - vodi na edit profile
          if (sessionAsync.isLoading && session == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (session != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Tooltip(
                message: 'Moj račun',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showUserMenu(profile, isAdmin: isAdmin),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: _avatarImage(profile, isAdmin: isAdmin),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    child: _shouldShowInitials(profile, isAdmin: isAdmin)
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
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Početna',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Torbe',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            label: 'Kaiševi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Favoriti',
          ),
          if (!isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'Korpa',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _avatarImage(UserProfile? profile, {required bool isAdmin}) {
    if (isAdmin) return null;
    final String? url = profile?.avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final String base64Part = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Part);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  bool _shouldShowInitials(UserProfile? profile, {required bool isAdmin}) {
    return _avatarImage(profile, isAdmin: isAdmin) == null;
  }

  String _avatarInitials(UserProfile? profile, AuthSession? session) {
    String source = (profile?.fullName ?? '').trim();
    if (source.isEmpty) source = (profile?.username ?? '').trim();
    if (source.isEmpty) source = (profile?.email ?? '').trim();
    if (source.isEmpty) source = (session?.username ?? '').trim();
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first[0].toUpperCase();
    }
    final String first = parts.first.isNotEmpty ? parts.first[0] : '';
    final String last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _showUserMenu(UserProfile? profile, {required bool isAdmin}) async {
    if (!mounted) return;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AuthSession?> sessionAsync = ref.read(
      authControllerProvider,
    );
    final AuthSession? session = sessionAsync.value;
    final int profilePageIndex = isAdmin ? 4 : 5;

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
                      backgroundImage: _avatarImage(profile, isAdmin: isAdmin),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: _shouldShowInitials(profile, isAdmin: isAdmin)
                          ? Text(
                              _avatarInitials(profile, session),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          if (profile?.email != null &&
                              profile!.email.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              profile.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aktivan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
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
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Moj profil'),
                subtitle: const Text('Pregled korisničkih podataka'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _index = profilePageIndex);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Uredi podatke'),
                subtitle: const Text('Promijeni ime, telefon...'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final UserProfile? profileForEdit =
                      profile ??
                      await ref
                          .read(userProfileProvider.notifier)
                          .ensureLoaded();
                  if (!mounted) return;
                  if (profileForEdit == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profil trenutno nije dostupan. Pokušajte ponovo.',
                        ),
                      ),
                    );
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfileUpdateScreen(initial: profileForEdit),
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
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                title: const Text('Moje narudžbe'),
                subtitle: const Text('Povijest kupovine'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
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
                  child: Icon(
                    Icons.logout,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                ),
                title: Text(
                  'Odjava',
                  style: TextStyle(color: Colors.red.shade700),
                ),
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
