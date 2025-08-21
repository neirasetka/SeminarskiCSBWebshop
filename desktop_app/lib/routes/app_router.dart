/// Central GoRouter configuration for app routes.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../features/about/about_page.dart';
import '../shared/utils/constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.home,
        name: AppRouteNames.home,
        builder: (BuildContext context, GoRouterState state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        name: AppRouteNames.settings,
        builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutePaths.about,
        name: AppRouteNames.about,
        builder: (BuildContext context, GoRouterState state) => const AboutPage(),
      ),
    ],
  );
}