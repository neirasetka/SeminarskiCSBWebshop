import 'package:csb_webshop_mobile/src/features/orders/application/cart_provider.dart';
import 'package:csb_webshop_mobile/src/features/orders/data/orders_api.dart';
import 'package:csb_webshop_mobile/src/features/orders/domain/order_models.dart';
import 'package:csb_webshop_mobile/src/features/orders/presentation/cart_screen.dart';
import 'package:csb_webshop_mobile/src/features/orders/presentation/order_success_screen.dart';
import 'package:csb_webshop_mobile/src/features/auth/application/auth_controller.dart';
import 'package:csb_webshop_mobile/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_mobile/src/features/auth/domain/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock AuthApi for testing
class MockAuthApi extends AuthApi {
  @override
  Future<AuthSession> login({required String username, required String password}) async {
    return AuthSession(
      token: 'test-token',
      userId: 1,
      username: username,
      roles: <String>['Buyer'],
    );
  }

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    String? phone,
  }) async {
    return AuthSession(
      token: 'test-token',
      userId: 1,
      username: username,
      roles: <String>['Buyer'],
    );
  }

  @override
  Future<void> logout() async {}
}

/// Mock OrdersApi for testing
class MockOrdersApi extends OrdersApi {
  List<OrderItemModel> cartItems = <OrderItemModel>[];
  bool shouldReturnEmptyCart = true;

  void addItem(OrderItemModel item) {
    cartItems.add(item);
    shouldReturnEmptyCart = false;
  }

  void clearCart() {
    cartItems.clear();
    shouldReturnEmptyCart = true;
  }

  @override
  Future<OrderModel?> getActiveCart(int userId) async {
    if (shouldReturnEmptyCart || cartItems.isEmpty) return null;
    return OrderModel(
      id: 1,
      orderNumber: '#CSB-001',
      date: DateTime.now(),
      userId: userId,
      amount: cartItems.fold(0, (double sum, OrderItemModel item) => sum + (item.price * item.quantity)),
      items: cartItems,
      paymentStatus: 'pending',
      shippingStatus: 'created',
    );
  }

  @override
  Future<List<OrderModel>> getOrders() async => <OrderModel>[];

  @override
  Future<OrderModel> createOrder(OrderUpsertRequest request) async {
    return OrderModel(
      id: 1,
      orderNumber: '#CSB-001',
      date: DateTime.now(),
      userId: request.userId,
      amount: cartItems.fold(0, (double sum, OrderItemModel item) => sum + (item.price * item.quantity)),
      items: cartItems,
      paymentStatus: 'pending',
      shippingStatus: 'created',
    );
  }

  @override
  Future<void> addItemToCart({
    required int orderId,
    int? bagId,
    int? beltId,
    required double price,
    required int quantity,
  }) async {
    cartItems.add(OrderItemModel(
      id: cartItems.length + 1,
      bagId: bagId,
      beltId: beltId,
      price: price,
      quantity: quantity,
      name: bagId != null ? 'Bag #$bagId' : 'Belt #$beltId',
    ));
    shouldReturnEmptyCart = false;
  }
}

void main() {
  group('Cart Screen Tests', () {
    late MockOrdersApi mockOrdersApi;
    late ProviderContainer container;

    setUp(() {
      mockOrdersApi = MockOrdersApi();
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/cart',
            routes: <RouteBase>[
              GoRoute(
                path: '/cart',
                builder: (BuildContext context, GoRouterState state) =>
                    const CartScreen(),
              ),
              GoRoute(
                path: '/checkout',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Checkout Screen')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-CART-001: Empty cart shows empty message', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.shouldReturnEmptyCart = true;
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Korpa je prazna.'), findsOneWidget);
    });

    testWidgets('TC-CART-002: Cart with items shows item list', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      mockOrdersApi.addItem(OrderItemModel(
        id: 2,
        beltId: 1,
        price: 85.0,
        quantity: 2,
        name: 'Leather Belt',
      ));
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('Leather Belt'), findsOneWidget);
    });

    testWidgets('TC-CART-003: Cart shows item quantities', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 2,
        name: 'Luxury Handbag',
      ));
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Količina: 2'), findsOneWidget);
    });

    testWidgets('TC-CART-004: Cart shows total amount', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      mockOrdersApi.addItem(OrderItemModel(
        id: 2,
        beltId: 1,
        price: 50.0,
        quantity: 1,
        name: 'Leather Belt',
      ));
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ukupno:'), findsOneWidget);
      expect(find.text('300.00 KM'), findsOneWidget);
    });

    testWidgets('TC-CART-005: Checkout button navigates to checkout', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Nastavi na plaćanje'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Checkout Screen'), findsOneWidget);
    });

    testWidgets('TC-CART-006: Cart AppBar shows Korpa title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Korpa'), findsOneWidget);
    });

    testWidgets('TC-CART-007: Cart shows individual item prices', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Cijena: 250.00 KM'), findsOneWidget);
    });

    testWidgets('TC-CART-008: Checkout button disabled for empty cart', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.shouldReturnEmptyCart = true;
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - No checkout button for empty cart
      expect(find.text('Nastavi na plaćanje'), findsNothing);
    });

    testWidgets('TC-CART-009: Line total calculated correctly', (WidgetTester tester) async {
      // Arrange - Add item with quantity 2
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 100.0,
        quantity: 2,
        name: 'Test Bag',
      ));
      
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Line total should be 200 KM
      expect(find.text('200.00 KM'), findsWidgets);
    });
  });

  group('Order Success Screen Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createSuccessTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/success',
            routes: <RouteBase>[
              GoRoute(
                path: '/success',
                builder: (BuildContext context, GoRouterState state) =>
                    const OrderSuccessScreen(),
              ),
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Home')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-CHECKOUT-001: Order success screen displays confirmation', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSuccessTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show success message
      expect(find.textContaining('Narudžba'), findsWidgets);
    });

    testWidgets('TC-CHECKOUT-002: Success screen has return to home button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createSuccessTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have button to return home
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('Checkout Flow Integration Tests', () {
    late MockOrdersApi mockOrdersApi;
    late ProviderContainer container;

    setUp(() {
      mockOrdersApi = MockOrdersApi();
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('TC-CHECKOUT-003: Full checkout flow - add items and proceed', (WidgetTester tester) async {
      // This test simulates the complete checkout flow
      
      // Step 1: Add items to cart
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      
      // Step 2: View cart
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/cart',
            routes: <RouteBase>[
              GoRoute(
                path: '/cart',
                builder: (BuildContext context, GoRouterState state) =>
                    const CartScreen(),
              ),
              GoRoute(
                path: '/checkout',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Stripe Payment Sheet')),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Verify cart shows item
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('250.00 KM'), findsWidgets);
      
      // Step 3: Proceed to checkout
      await tester.tap(find.text('Nastavi na plaćanje'));
      await tester.pumpAndSettle();
      
      // Verify checkout screen
      expect(find.text('Stripe Payment Sheet'), findsOneWidget);
    });

    testWidgets('TC-CHECKOUT-004: Cart with multiple item types', (WidgetTester tester) async {
      // Add both bag and belt
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Luxury Handbag',
      ));
      mockOrdersApi.addItem(OrderItemModel(
        id: 2,
        beltId: 1,
        price: 85.0,
        quantity: 1,
        name: 'Leather Belt',
      ));
      
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Verify both items are shown
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('Leather Belt'), findsOneWidget);
      
      // Verify total (250 + 85 = 335)
      expect(find.text('335.00 KM'), findsOneWidget);
    });

    testWidgets('TC-CHECKOUT-005: Cart shows payment icon', (WidgetTester tester) async {
      mockOrdersApi.addItem(OrderItemModel(
        id: 1,
        bagId: 1,
        price: 250.0,
        quantity: 1,
        name: 'Test Bag',
      ));
      
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Verify payment icon on checkout button
      expect(find.byIcon(Icons.payment), findsOneWidget);
    });
  });
}
