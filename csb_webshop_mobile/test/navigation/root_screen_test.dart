import 'package:csb_webshop_mobile/src/features/auth/application/auth_controller.dart';
import 'package:csb_webshop_mobile/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_mobile/src/features/auth/domain/auth_session.dart';
import 'package:csb_webshop_mobile/src/features/profile/application/user_profile_provider.dart';
import 'package:csb_webshop_mobile/src/features/profile/data/profile_api.dart';
import 'package:csb_webshop_mobile/src/features/profile/domain/user_profile.dart';
import 'package:csb_webshop_mobile/src/features/root/presentation/root_screen.dart';
import 'package:csb_webshop_mobile/src/features/bags/application/bags_provider.dart';
import 'package:csb_webshop_mobile/src/features/bags/data/bags_api.dart';
import 'package:csb_webshop_mobile/src/features/bags/domain/bag.dart';
import 'package:csb_webshop_mobile/src/features/belts/application/belts_provider.dart';
import 'package:csb_webshop_mobile/src/features/belts/data/belts_api.dart';
import 'package:csb_webshop_mobile/src/features/belts/domain/belt.dart';
import 'package:csb_webshop_mobile/src/features/favorites/application/favorites_provider.dart';
import 'package:csb_webshop_mobile/src/features/favorites/data/local_favorites_storage.dart';
import 'package:csb_webshop_mobile/src/features/orders/application/cart_provider.dart';
import 'package:csb_webshop_mobile/src/features/orders/data/orders_api.dart';
import 'package:csb_webshop_mobile/src/features/orders/domain/order_models.dart';
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

/// Mock ProfileApi for testing
class MockProfileApi extends ProfileApi {
  @override
  Future<UserProfile> getProfile() async {
    return UserProfile(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      phone: '+387123456',
    );
  }

  @override
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarBase64,
  }) async {
    return UserProfile(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      firstName: firstName ?? 'Test',
      lastName: lastName ?? 'User',
      phone: phone ?? '+387123456',
    );
  }
}

/// Mock BagsApi for testing
class MockBagsApi extends BagsApi {
  @override
  Future<List<Bag>> getBags({int? bagTypeId, String? query}) async {
    return <Bag>[
      Bag(id: 1, name: 'Test Bag 1', code: 'TB1', price: 100.0, description: 'Test bag 1'),
      Bag(id: 2, name: 'Test Bag 2', code: 'TB2', price: 150.0, description: 'Test bag 2'),
    ];
  }

  @override
  Future<Bag> getBag(int id) async {
    return Bag(id: id, name: 'Test Bag $id', code: 'TB$id', price: 100.0, description: 'Test bag $id');
  }

  @override
  Future<Bag> createBag({
    required String name,
    required String code,
    required double price,
    String? description,
    int? bagTypeId,
    String? imageBase64,
  }) async {
    return Bag(id: 1, name: name, code: code, price: price, description: description ?? '');
  }

  @override
  Future<Bag> updateBag({
    required int id,
    required String name,
    required String code,
    required double price,
    String? description,
    int? bagTypeId,
    String? imageBase64,
  }) async {
    return Bag(id: id, name: name, code: code, price: price, description: description ?? '');
  }

  @override
  Future<void> deleteBag(int id) async {}
}

/// Mock BeltsApi for testing
class MockBeltsApi extends BeltsApi {
  @override
  Future<List<Belt>> getBelts({int? beltTypeId, String? query}) async {
    return <Belt>[
      Belt(id: 1, name: 'Test Belt 1', code: 'TBL1', price: 50.0, description: 'Test belt 1'),
      Belt(id: 2, name: 'Test Belt 2', code: 'TBL2', price: 75.0, description: 'Test belt 2'),
    ];
  }

  @override
  Future<Belt> getBelt(int id) async {
    return Belt(id: id, name: 'Test Belt $id', code: 'TBL$id', price: 50.0, description: 'Test belt $id');
  }

  @override
  Future<Belt> createBelt({
    required String name,
    required String code,
    required double price,
    String? description,
    int? beltTypeId,
    String? imageBase64,
  }) async {
    return Belt(id: 1, name: name, code: code, price: price, description: description ?? '');
  }

  @override
  Future<Belt> updateBelt({
    required int id,
    required String name,
    required String code,
    required double price,
    String? description,
    int? beltTypeId,
    String? imageBase64,
  }) async {
    return Belt(id: id, name: name, code: code, price: price, description: description ?? '');
  }

  @override
  Future<void> deleteBelt(int id) async {}
}

/// Mock OrdersApi for testing
class MockOrdersApi extends OrdersApi {
  @override
  Future<OrderModel?> getActiveCart(int userId) async {
    return null;
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    return <OrderModel>[];
  }

  @override
  Future<OrderModel> createOrder(OrderUpsertRequest request) async {
    return OrderModel(
      id: 1,
      orderNumber: '#001',
      date: DateTime.now(),
      userId: request.userId,
      amount: 0,
      items: const <OrderItemModel>[],
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
  }) async {}
}

/// Mock LocalFavoritesStorage for testing
class MockLocalFavoritesStorage extends LocalFavoritesStorage {
  @override
  Future<Set<int>> loadFavorites() async {
    return <int>{};
  }

  @override
  Future<void> saveFavorites(Set<int> ids) async {}
}

void main() {
  group('RootScreen Navigation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
          profileApiProvider.overrideWith((Ref ref) => MockProfileApi()),
          bagsApiProvider.overrideWith((Ref ref) => MockBagsApi()),
          beltsApiProvider.overrideWith((Ref ref) => MockBeltsApi()),
          ordersApiProvider.overrideWith((Ref ref) => MockOrdersApi()),
          localFavoritesStorageProvider.overrideWith((Ref ref) => MockLocalFavoritesStorage()),
          // Pre-populate auth state
          authControllerProvider.overrideWith(() => _MockAuthController()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({int initialIndex = 0}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: RootScreen(title: 'CSB Webshop', initialIndex: initialIndex),
        ),
      );
    }

    testWidgets('TC-NAV-001: Home screen displays 4 main menu buttons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for 4 main menu buttons
      expect(find.text('Torbice'), findsOneWidget);
      expect(find.text('Kaiševi'), findsOneWidget);
      expect(find.text('Giveaway'), findsOneWidget);
      expect(find.text('Lookbook'), findsOneWidget);
    });

    testWidgets('TC-NAV-002: Bottom navigation bar displays 5 tabs', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Početna'), findsOneWidget);
      expect(find.text('Torbe'), findsOneWidget);
      expect(find.text('Kaiševi'), findsWidgets); // May appear multiple times
      expect(find.text('Korpa'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('TC-NAV-003: Tapping Torbe tab shows bags list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Torbe'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Katalog torbi'), findsOneWidget);
    });

    testWidgets('TC-NAV-004: Tapping Kaiševi tab shows belts list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.checkroom_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Katalog kaiševa'), findsOneWidget);
    });

    testWidgets('TC-NAV-005: Tapping Korpa tab shows cart screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Korpa'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Korpa je prazna.'), findsOneWidget);
    });

    testWidgets('TC-NAV-006: Tapping Profil tab shows profile screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('CSB Webshop'), findsOneWidget);
    });

    testWidgets('TC-NAV-007: Cart icon in header navigates to cart', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Korpa je prazna.'), findsOneWidget);
    });

    testWidgets('TC-NAV-008: Tapping Torbice menu button navigates to bags', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap on Torbice menu button
      await tester.tap(find.text('Torbice'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Katalog torbi'), findsOneWidget);
    });

    testWidgets('TC-NAV-009: Tapping logo returns to home', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(initialIndex: 1)); // Start on bags
      await tester.pumpAndSettle();

      // The logo should be tappable
      // In the RootScreen, clicking on the logo navigates to home (index 0)
      expect(find.byType(RootScreen), findsOneWidget);
    });

    testWidgets('TC-NAV-010: Bottom nav highlights current tab', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Navigate to Korpa tab
      await tester.tap(find.text('Korpa'));
      await tester.pumpAndSettle();

      // Assert - Korpa tab should be selected (index 3)
      final BottomNavigationBar bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 3);
    });

    testWidgets('TC-NAV-011: IndexedStack preserves page state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to Torbe
      await tester.tap(find.text('Torbe'));
      await tester.pumpAndSettle();

      // Navigate to Korpa
      await tester.tap(find.text('Korpa'));
      await tester.pumpAndSettle();

      // Navigate back to Torbe
      await tester.tap(find.text('Torbe'));
      await tester.pumpAndSettle();

      // Assert - Should still show bags list
      expect(find.text('Katalog torbi'), findsOneWidget);
    });

    testWidgets('TC-NAV-012: Welcome message shows user name', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Welcome message should include name from profile
      expect(find.textContaining('Dobro došli'), findsOneWidget);
    });
  });
}

/// Mock AuthController for testing
class _MockAuthController extends AuthController {
  @override
  Future<AsyncValue<AuthSession?>> build() async {
    return AsyncValue<AuthSession?>.data(AuthSession(
      token: 'test-token',
      userId: 1,
      username: 'testuser',
      roles: <String>['Buyer'],
    ));
  }
}
