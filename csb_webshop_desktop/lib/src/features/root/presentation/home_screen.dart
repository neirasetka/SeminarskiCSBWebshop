import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    const List<_NavShortcut> shortcuts = <_NavShortcut>[
      _NavShortcut(icon: Icons.shopping_bag_outlined, label: 'Bags', route: '/bags'),
      _NavShortcut(icon: Icons.shopping_bag, label: 'Torbice', route: '/torbice'),
      _NavShortcut(icon: Icons.checkroom_outlined, label: 'Belts', route: '/belts'),
      _NavShortcut(icon: Icons.straighten, label: 'Kaisevi', route: '/kaisevi'),
      _NavShortcut(icon: Icons.grid_view_outlined, label: 'Lookbook', route: '/lookbook'),
      _NavShortcut(icon: Icons.card_giftcard, label: 'Giveaway', route: '/giveaways'),
      _NavShortcut(icon: Icons.shopping_cart, label: 'Korpa', route: '/checkout'),
      _NavShortcut(icon: Icons.insights_outlined, label: 'Reports', route: '/reports'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HomeHeader(shortcuts: shortcuts),
              const Spacer(),
              Center(
                child: Text(
                  'Welcome',
                  style: textTheme.displayLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.shortcuts});

  final List<_NavShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _LogoBadge(),
        const Spacer(),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              runAlignment: WrapAlignment.end,
              children: shortcuts.map((_) => _NavShortcutButton(shortcut: _)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  static const String _logoImageUrl =
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=240&q=80';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _logoImageUrl,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => SizedBox(
              width: 140,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  color: colorScheme.primary,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavShortcutButton extends StatelessWidget {
  const _NavShortcutButton({required this.shortcut});

  final _NavShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Material(
          color: colorScheme.primary.withOpacity(0.08),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: shortcut.label,
            icon: Icon(shortcut.icon, color: colorScheme.primary),
            onPressed: () => context.go(shortcut.route),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shortcut.label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _NavShortcut {
  const _NavShortcut({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}
