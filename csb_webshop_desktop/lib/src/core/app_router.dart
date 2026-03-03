import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/presentation/announcement_detail_screen.dart';
import '../features/announcements/presentation/announcement_edit_screen.dart';
import '../features/announcements/presentation/announcement_form_screen.dart';
import '../features/announcements/presentation/announcements_list_screen.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/orders/domain/order_models.dart';
import '../features/orders/presentation/cart_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/payment_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/root/presentation/root_screen.dart';
import '../features/root/presentation/home_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/giveaways/presentation/giveaways_list_screen.dart';
import '../features/lookbook/presentation/lookbook_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/bags/domain/bag.dart';
import '../features/lookbook/presentation/lookbook_detail_screen.dart';
import '../features/outfit_ideas/presentation/outfit_idea_screen.dart';
import '../features/outfit_ideas/presentation/outfit_idea_belt_screen.dart';
import '../features/belts/domain/belt.dart';
import '../features/bags/presentation/bags_detail_screen.dart';
import '../features/belts/presentation/belts_detail_screen.dart';
import '../features/torbice_shop/presentation/torbice_shop_screen.dart';
import '../features/kaisevi_shop/presentation/kaisevi_shop_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';

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
        child: HomeScreen(),
      ),
      routes: <RouteBase>[
        GoRoute(
          path: 'belts',
          name: 'belts',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: RootScreen(title: 'CSB Webshop', initialIndex: 1),
          ),
        ),
        GoRoute(
          path: 'torbice',
          name: 'torbice',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: TorbiceShopScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              name: 'torbiceDetail',
              builder: (BuildContext context, GoRouterState state) {
                final String? idParam = state.pathParameters['id'];
                final int bagId = int.tryParse(idParam ?? '') ?? 0;
                return AuthGate(child: BagDetailScreen(id: bagId));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'kaisevi',
          name: 'kaisevi',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: KaiseviShopScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              name: 'kaiseviDetail',
              builder: (BuildContext context, GoRouterState state) {
                final String? idParam = state.pathParameters['id'];
                final int beltId = int.tryParse(idParam ?? '') ?? 0;
                return AuthGate(child: BeltDetailScreen(id: beltId));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'favoriti',
          name: 'favoriti',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: FavoritesScreen(),
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
          path: 'giveaways/admin',
          name: 'giveawaysAdmin',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            requiredRoles: <String>['Admin'],
            child: GiveawaysListScreen(forAdmin: true),
          ),
        ),
        GoRoute(
          path: 'announcements',
          name: 'announcements',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            child: AnnouncementsListScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              name: 'announcementDetail',
              builder: (BuildContext context, GoRouterState state) {
                final String? idParam = state.pathParameters['id'];
                final int id = int.tryParse(idParam ?? '') ?? 0;
                return AuthGate(child: AnnouncementDetailScreen(id: id));
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'edit',
                  name: 'announcementEdit',
                  builder: (BuildContext context, GoRouterState state) {
                    final String? idParam = state.pathParameters['id'];
                    final int id = int.tryParse(idParam ?? '') ?? 0;
                    return AuthGate(
                      requiredRoles: <String>['Admin'],
                      child: AnnouncementEditScreen(id: id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'announcement/new',
          name: 'announcementForm',
          builder: (BuildContext context, GoRouterState state) => const AuthGate(
            requiredRoles: <String>['Admin'],
            child: AnnouncementFormScreen(),
          ),
        ),
        GoRoute(
          path: 'bags/:id/outfit-idea',
          name: 'outfitIdea',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int bagId = int.tryParse(idParam ?? '') ?? 0;
            final Bag? initialBag = state.extra is Bag ? state.extra as Bag : null;
            return AuthGate(
              child: OutfitIdeaScreen(bagId: bagId, initialBag: initialBag),
            );
          },
        ),
        GoRoute(
          path: 'belts/:id/outfit-idea',
          name: 'outfitIdeaBelt',
          builder: (BuildContext context, GoRouterState state) {
            final String? idParam = state.pathParameters['id'];
            final int beltId = int.tryParse(idParam ?? '') ?? 0;
            final Belt? initialBelt = state.extra is Belt ? state.extra as Belt : null;
            return AuthGate(
              child: OutfitIdeaBeltScreen(beltId: beltId, initialBelt: initialBelt),
            );
          },
        ),
      ],
    ),
  ],
);

