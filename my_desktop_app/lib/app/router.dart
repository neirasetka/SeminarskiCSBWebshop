import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/open_file/open_file_page.dart';
import '../features/settings/settings_page.dart';
import '../features/about/about_page.dart';
import '../features/viewer/viewer_page.dart';
import 'scaffold.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppScaffold(location: state.uri.toString(), child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'home',
          builder: (BuildContext context, GoRouterState state) => const OpenFilePage(),
        ),
        GoRoute(
          path: '/viewer',
          name: 'viewer',
          builder: (BuildContext context, GoRouterState state) {
            final String path = (state.extra ?? '') as String;
            return ViewerPage(path: path);
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/about',
          name: 'about',
          builder: (BuildContext context, GoRouterState state) => const AboutPage(),
        ),
      ],
    ),
  ],
);