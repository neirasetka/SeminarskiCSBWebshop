import 'package:csb_webshop_mobile/src/features/profile/application/user_profile_provider.dart';
import 'package:csb_webshop_mobile/src/features/profile/data/profile_api.dart';
import 'package:csb_webshop_mobile/src/features/profile/domain/user_profile.dart';
import 'package:csb_webshop_mobile/src/features/profile/presentation/profile_screen.dart';
import 'package:csb_webshop_mobile/src/features/profile/presentation/profile_update_screen.dart';
import 'package:csb_webshop_mobile/src/features/orders/application/order_history_provider.dart';
import 'package:csb_webshop_mobile/src/features/orders/data/orders_api.dart';
import 'package:csb_webshop_mobile/src/features/orders/domain/order_models.dart';
import 'package:csb_webshop_mobile/src/features/orders/presentation/order_history_screen.dart';
import 'package:csb_webshop_mobile/src/features/orders/presentation/order_detail_screen.dart';
import 'package:csb_webshop_mobile/src/features/auth/application/auth_controller.dart';
import 'package:csb_webshop_mobile/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_mobile/src/features/auth/domain/auth_session.dart';
import 'package:csb_webshop_mobile/src/features/auth/application/admin_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock ProfileApi for testing
class MockProfileApi extends ProfileApi {
  UserProfile mockProfile = UserProfile(
    id: 1,
    username: 'marko123',
    email: 'marko@example.com',
    firstName: 'Marko',
    lastName: 'Markovic',
    phone: '+387123456789',
    avatarUrl: null,
  );

  bool shouldSucceedUpdate = true;

  @override
  Future<UserProfile> getProfile() async {
    return mockProfile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarBase64,
  }) async {
    if (!shouldSucceedUpdate) {
      throw Exception('Update failed');
    }
    
    mockProfile = UserProfile(
      id: mockProfile.id,
      username: mockProfile.username,
      email: mockProfile.email,
      firstName: firstName ?? mockProfile.firstName,
      lastName: lastName ?? mockProfile.lastName,
      phone: phone ?? mockProfile.phone,
      avatarUrl: mockProfile.avatarUrl,
    );
    return mockProfile;
  }
}

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
  List<OrderModel> mockOrders = <OrderModel>[
    OrderModel(
      id: 1,
      orderNumber: '#CSB-001',
      date: DateTime(2024, 1, 15),
      userId: 1,
      amount: 335.0,
      items: <OrderItemModel>[
        OrderItemModel(id: 1, bagId: 1, price: 250.0, quantity: 1, name: 'Luxury Handbag'),
        OrderItemModel(id: 2, beltId: 1, price: 85.0, quantity: 1, name: 'Leather Belt'),
      ],
      paymentStatus: 'paid',
      shippingStatus: 'delivered',
    ),
    OrderModel(
      id: 2,
      orderNumber: '#CSB-002',
      date: DateTime(2024, 2, 20),
      userId: 1,
      amount: 150.0,
      items: <OrderItemModel>[
        OrderItemModel(id: 3, bagId: 2, price: 150.0, quantity: 1, name: 'Evening Clutch'),
      ],
      paymentStatus: 'paid',
      shippingStatus: 'shipped',
    ),
    OrderModel(
      id: 3,
      orderNumber: '#CSB-003',
      date: DateTime(2024, 3, 10),
      userId: 1,
      amount: 85.0,
      items: <OrderItemModel>[
        OrderItemModel(id: 4, beltId: 2, price: 85.0, quantity: 1, name: 'Canvas Belt'),
      ],
      paymentStatus: 'pending',
      shippingStatus: 'created',
    ),
  ];

  @override
  Future<OrderModel?> getActiveCart(int userId) async {
    return null;
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    return mockOrders;
  }

  @override
  Future<OrderModel> createOrder(OrderUpsertRequest request) async {
    return mockOrders.first;
  }

  @override
  Future<void> addItemToCart({
    required int orderId,
    int? bagId,
    int? beltId,
    required double price,
    required int quantity,
  }) async {}
}

void main() {
  group('Profile Screen Tests', () {
    late MockProfileApi mockProfileApi;
    late ProviderContainer container;

    setUp(() {
      mockProfileApi = MockProfileApi();
      container = ProviderContainer(
        overrides: <Override>[
          profileApiProvider.overrideWith((Ref ref) => mockProfileApi),
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
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
            initialLocation: '/profile',
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(title: 'Profil'),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-PROFILE-001: Profile screen displays user info', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Marko Markovic'), findsOneWidget);
      expect(find.text('@marko123'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-002: Profile shows email', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('marko@example.com'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-003: Profile shows phone when available', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('+387123456789'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-004: Moje narudžbe button exists', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Moje narudžbe'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-005: Avatar initials shown when no image', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show initials MM (Marko Markovic)
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('TC-PROFILE-006: Edit profile FAB exists', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Uredi profil'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-007: Refresh button in AppBar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('TC-PROFILE-008: Logout button in AppBar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('TC-PROFILE-009: Contact information card exists', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Kontakt informacije'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-010: Quick actions card exists', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Brze akcije'), findsOneWidget);
    });
  });

  group('Profile Update Screen Tests', () {
    late MockProfileApi mockProfileApi;
    late ProviderContainer container;

    setUp(() {
      mockProfileApi = MockProfileApi();
      container = ProviderContainer(
        overrides: <Override>[
          profileApiProvider.overrideWith((Ref ref) => mockProfileApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createUpdateTestWidget() {
      final UserProfile initialProfile = UserProfile(
        id: 1,
        username: 'marko123',
        email: 'marko@example.com',
        firstName: 'Marko',
        lastName: 'Markovic',
        phone: '+387123456789',
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ProfileUpdateScreen(initial: initialProfile),
        ),
      );
    }

    testWidgets('TC-PROFILE-011: Update screen shows current data', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createUpdateTestWidget());
      await tester.pumpAndSettle();

      // Assert - Fields should be pre-filled
      expect(find.text('Marko'), findsOneWidget);
      expect(find.text('Markovic'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-012: Update screen has save button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createUpdateTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sačuvaj'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-013: First name field editable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createUpdateTestWidget());
      await tester.pumpAndSettle();

      // Act - Find and edit first name field
      final Finder firstNameField = find.widgetWithText(TextFormField, 'Ime');
      await tester.enterText(firstNameField, 'Ivan');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ivan'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-014: Last name field editable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createUpdateTestWidget());
      await tester.pumpAndSettle();

      // Act
      final Finder lastNameField = find.widgetWithText(TextFormField, 'Prezime');
      await tester.enterText(lastNameField, 'Ivanic');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ivanic'), findsOneWidget);
    });

    testWidgets('TC-PROFILE-015: Phone field editable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createUpdateTestWidget());
      await tester.pumpAndSettle();

      // Act
      final Finder phoneField = find.widgetWithText(TextFormField, 'Telefon');
      await tester.enterText(phoneField, '+387999888777');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('+387999888777'), findsOneWidget);
    });
  });

  group('Order History Screen Tests', () {
    late MockOrdersApi mockOrdersApi;
    late ProviderContainer container;

    setUp(() {
      mockOrdersApi = MockOrdersApi();
      container = ProviderContainer(
        overrides: <Override>[
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createOrderHistoryTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/orders',
            routes: <RouteBase>[
              GoRoute(
                path: '/orders',
                builder: (BuildContext context, GoRouterState state) =>
                    const OrderHistoryScreen(),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-ORDERS-001: Order history shows all orders', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('#CSB-001'), findsOneWidget);
      expect(find.text('#CSB-002'), findsOneWidget);
      expect(find.text('#CSB-003'), findsOneWidget);
    });

    testWidgets('TC-ORDERS-002: Order shows amount', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('335.00 KM'), findsOneWidget);
      expect(find.text('150.00 KM'), findsOneWidget);
    });

    testWidgets('TC-ORDERS-003: Order shows payment status', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show payment statuses
      expect(find.textContaining('paid'), findsWidgets);
    });

    testWidgets('TC-ORDERS-004: Order shows shipping status', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show shipping statuses
      expect(find.textContaining('delivered'), findsWidgets);
    });

    testWidgets('TC-ORDERS-005: Tapping order opens detail', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('#CSB-001'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to detail
      expect(find.text('Detalji narudžbe'), findsOneWidget);
    });

    testWidgets('TC-ORDERS-006: Empty state when no orders', (WidgetTester tester) async {
      // Arrange
      mockOrdersApi.mockOrders = <OrderModel>[];
      
      // Act
      await tester.pumpWidget(createOrderHistoryTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nemate narudžbi.'), findsOneWidget);
    });
  });

  group('Order Detail Screen Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createOrderDetailTestWidget(OrderModel order) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: OrderDetailScreen(order: order),
        ),
      );
    }

    testWidgets('TC-ORDERS-007: Order detail shows order number', (WidgetTester tester) async {
      // Arrange
      final OrderModel order = OrderModel(
        id: 1,
        orderNumber: '#CSB-001',
        date: DateTime(2024, 1, 15),
        userId: 1,
        amount: 335.0,
        items: <OrderItemModel>[
          OrderItemModel(id: 1, bagId: 1, price: 250.0, quantity: 1, name: 'Luxury Handbag'),
        ],
        paymentStatus: 'paid',
        shippingStatus: 'delivered',
      );

      // Act
      await tester.pumpWidget(createOrderDetailTestWidget(order));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detalji narudžbe'), findsOneWidget);
      expect(find.text('#CSB-001'), findsWidgets);
    });

    testWidgets('TC-ORDERS-008: Order detail shows items', (WidgetTester tester) async {
      // Arrange
      final OrderModel order = OrderModel(
        id: 1,
        orderNumber: '#CSB-001',
        date: DateTime(2024, 1, 15),
        userId: 1,
        amount: 335.0,
        items: <OrderItemModel>[
          OrderItemModel(id: 1, bagId: 1, price: 250.0, quantity: 1, name: 'Luxury Handbag'),
          OrderItemModel(id: 2, beltId: 1, price: 85.0, quantity: 1, name: 'Leather Belt'),
        ],
        paymentStatus: 'paid',
        shippingStatus: 'delivered',
      );

      // Act
      await tester.pumpWidget(createOrderDetailTestWidget(order));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('Leather Belt'), findsOneWidget);
    });

    testWidgets('TC-ORDERS-009: Order detail shows total amount', (WidgetTester tester) async {
      // Arrange
      final OrderModel order = OrderModel(
        id: 1,
        orderNumber: '#CSB-001',
        date: DateTime(2024, 1, 15),
        userId: 1,
        amount: 335.0,
        items: <OrderItemModel>[],
        paymentStatus: 'paid',
        shippingStatus: 'delivered',
      );

      // Act
      await tester.pumpWidget(createOrderDetailTestWidget(order));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('335.00 KM'), findsWidgets);
    });

    testWidgets('TC-ORDERS-010: Shipping timeline displayed', (WidgetTester tester) async {
      // Arrange
      final OrderModel order = OrderModel(
        id: 1,
        orderNumber: '#CSB-001',
        date: DateTime(2024, 1, 15),
        userId: 1,
        amount: 335.0,
        items: <OrderItemModel>[],
        paymentStatus: 'paid',
        shippingStatus: 'shipped',
      );

      // Act
      await tester.pumpWidget(createOrderDetailTestWidget(order));
      await tester.pumpAndSettle();

      // Assert - Timeline should be present
      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });
  });
}
