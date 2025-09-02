import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/orders/domain/order_models.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/checkout_demo_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/root/presentation/root_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/giveaways/presentation/giveaways_list_screen.dart';
import '../features/lookbook/presentation/lookbook_screen.dart';
import '../features/collections/presentation/collections_screen.dart';
import '../features/reports/presentation/reports_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) => const RootScreen(title: 'CSB Webshop'),
      routes: <RouteBase>[
        GoRoute(
          path: 'checkout',
          name: 'checkoutDemo',
          builder: (BuildContext context, GoRouterState state) => const CheckoutDemoScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'success',
              name: 'checkoutSuccess',
              builder: (BuildContext context, GoRouterState state) => const OrderSuccessScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'reports',
          name: 'reports',
          builder: (BuildContext context, GoRouterState state) => const ReportsScreen(),
        ),
        GoRoute(
          path: 'lookbook',
          name: 'lookbook',
          builder: (BuildContext context, GoRouterState state) => const LookbookScreen(),
        ),
        GoRoute(
          path: 'collections',
          name: 'collections',
          builder: (BuildContext context, GoRouterState state) => const CollectionsScreen(),
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
            return OrderDetailScreen(order: order);
          },
        ),
        GoRoute(
          path: 'events/:id',
          name: 'eventDetail',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int eventId = int.tryParse(idParam ?? '') ?? 1;
            return EventDetailScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: 'giveaways',
          name: 'giveaways',
          builder: (BuildContext context, GoRouterState state) => const GiveawaysListScreen(),
        ),
      ],
    ),
  ],
);

