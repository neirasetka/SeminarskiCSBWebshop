import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/orders/domain/order_models.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/hosted_checkout_mock_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/root/presentation/root_screen.dart';
import '../features/root/presentation/home_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/giveaways/presentation/giveaways_list_screen.dart';
import '../features/lookbook/presentation/lookbook_screen.dart';
import '../features/collections/presentation/collections_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/lookbook/presentation/lookbook_detail_screen.dart';
import '../features/outfit_ideas/presentation/outfit_idea_screen.dart';

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
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) => const AuthGate(
        child: HomeScreen(),
      ),
      routes: <RouteBase>[
        GoRoute(
          path: 'bags',
          name: 'bags',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 0),
          ),
        ),
        GoRoute(
          path: 'belts',
          name: 'belts',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 1),
          ),
        ),
        GoRoute(
          path: 'checkout',
          name: 'checkoutDemo',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: HostedCheckoutMockScreen(),
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
          path: 'reports',
          name: 'reports',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            requiredRoles: <String>['Admin'],
            child: ReportsScreen(),
          ),
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
                return AuthGate(child: LookbookDetailScreen(bagId: bagId));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'collections',
          name: 'collections',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: CollectionsScreen(),
          ),
        ),
        GoRoute(
          path: 'orders/:id',
          name: 'orderDetail',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int orderId = int.tryParse(idParam ?? '') ?? 0;
            // Minimal placeholder order; in a real app, fetch by id.
            final OrderModel order = OrderModel(
              id: orderId,
              orderNumber: '#$orderId',
              date: DateTime.now(),
              userId: 0,
              amount: 0,
              items: const <OrderItemModel>[],
              paymentStatus: 'pending',
              shippingStatus: 'created',
            );
            return AuthGate(child: OrderDetailScreen(order: order));
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
          path: 'bags/:id/outfit-idea',
          name: 'outfitIdea',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int bagId = int.tryParse(idParam ?? '') ?? 0;
            return AuthGate(child: OutfitIdeaScreen(bagId: bagId));
          },
        ),
      ],
    ),
  ],
);

