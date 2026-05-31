import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/orders/presentation/order_detail_loader_screen.dart';
import '../features/orders/presentation/cart_screen.dart';
import '../features/orders/presentation/payment_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/root/presentation/root_screen.dart';
import '../features/root/presentation/info_panel_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/giveaways/presentation/giveaways_list_screen.dart';
import '../features/lookbook/presentation/lookbook_screen.dart';
import '../features/lookbook/presentation/lookbook_detail_screen.dart';
import '../features/outfit_ideas/presentation/outfit_idea_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) => const AuthGate(
        child: RootScreen(title: 'CSB Webshop'),
      ),
      routes: <RouteBase>[
        GoRoute(
          path: 'bags',
          name: 'bags',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 1),
          ),
        ),
        GoRoute(
          path: 'belts',
          name: 'belts',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 2),
          ),
        ),
        GoRoute(
          path: 'favorites',
          name: 'favorites',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 3),
          ),
        ),
        GoRoute(
          path: 'cart',
          name: 'cart',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: CartScreen(),
          ),
        ),
        GoRoute(
          path: 'checkout',
          name: 'checkout',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: PaymentScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'success',
              name: 'checkoutSuccess',
              builder: (BuildContext context, GoRouterState state) => const AuthGate(
                child: OrderSuccessScreen(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'lookbook',
          name: 'lookbook',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: LookbookScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              name: 'lookbookDetail',
              builder: (BuildContext context, GoRouterState state) {
                final String? idParam = state.pathParameters['id'];
                final int bagId = int.tryParse(idParam ?? '') ?? 0;
                return AuthGate(
                  child: LookbookDetailScreen(bagId: bagId),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'info-panel',
          name: 'infoPanel',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: InfoPanelScreen(),
          ),
        ),
        GoRoute(
          path: 'orders/:id',
          name: 'orderDetail',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int orderId = int.tryParse(idParam ?? '') ?? 0;
            return AuthGate(child: OrderDetailLoaderScreen(orderId: orderId));
          },
        ),
        GoRoute(
          path: 'events/:id',
          name: 'eventDetail',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int eventId = int.tryParse(idParam ?? '') ?? 1;
            return AuthGate(child: EventDetailScreen(eventId: eventId));
          },
        ),
        GoRoute(
          path: 'giveaways',
          name: 'giveaways',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: GiveawaysListScreen(),
          ),
        ),
        GoRoute(
          path: 'notifications',
          name: 'notifications',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: 'bags/:id/outfit-idea',
          name: 'outfitIdea',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int bagId = int.tryParse(idParam ?? '') ?? 0;
            final String? bagName = state.uri.queryParameters['name'];
            return AuthGate(
              child: OutfitIdeaScreen(bagId: bagId, bagName: bagName),
            );
          },
        ),
      ],
    ),
  ],
);

