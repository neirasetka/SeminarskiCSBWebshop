import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenAboutIntent extends Intent {
  const OpenAboutIntent();
}

class QuitIntent extends Intent {
  const QuitIntent();
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int _locationToIndex(String location) {
    if (location.startsWith('/settings')) return 1;
    if (location.startsWith('/about')) return 2;
    return 0;
  }

  void _onSelect(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/settings');
        break;
      case 2:
        context.go('/about');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _locationToIndex(location);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.comma, control: true): OpenSettingsIntent(),
        SingleActivator(LogicalKeyboardKey.f1): OpenAboutIntent(),
        SingleActivator(LogicalKeyboardKey.keyQ, control: true): QuitIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (OpenSettingsIntent intent) {
              context.go('/settings');
              return null;
            },
          ),
          OpenAboutIntent: CallbackAction<OpenAboutIntent>(
            onInvoke: (OpenAboutIntent intent) {
              context.go('/about');
              return null;
            },
          ),
          QuitIntent: CallbackAction<QuitIntent>(
            onInvoke: (QuitIntent intent) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int i) => _onSelect(context, i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: Text('About'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}