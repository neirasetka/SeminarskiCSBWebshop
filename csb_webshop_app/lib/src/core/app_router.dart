import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/orders/domain/order_models.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/root/presentation/root_screen.dart';

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
      ],
    ),
  ],
);

