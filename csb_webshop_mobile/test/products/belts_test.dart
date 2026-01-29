import 'package:csb_webshop_mobile/src/features/belts/application/belts_provider.dart';
import 'package:csb_webshop_mobile/src/features/belts/application/belt_types_provider.dart';
import 'package:csb_webshop_mobile/src/features/belts/data/belts_api.dart';
import 'package:csb_webshop_mobile/src/features/belts/data/belt_types_api.dart';
import 'package:csb_webshop_mobile/src/features/belts/domain/belt.dart';
import 'package:csb_webshop_mobile/src/features/belts/domain/belt_type.dart';
import 'package:csb_webshop_mobile/src/features/belts/presentation/belts_list_screen.dart';
import 'package:csb_webshop_mobile/src/features/belts/presentation/belts_detail_screen.dart';
import 'package:csb_webshop_mobile/src/features/favorites/application/favorites_provider.dart';
import 'package:csb_webshop_mobile/src/features/favorites/data/local_favorites_storage.dart';
import 'package:csb_webshop_mobile/src/features/orders/application/cart_provider.dart';
import 'package:csb_webshop_mobile/src/features/orders/data/orders_api.dart';
import 'package:csb_webshop_mobile/src/features/orders/domain/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock BeltsApi for testing
class MockBeltsApi extends BeltsApi {
  List<Belt> mockBelts = <Belt>[
    Belt(
      id: 1,
      name: 'Leather Belt Classic',
      code: 'LBC001',
      price: 85.0,
      description: 'Classic leather belt with silver buckle',
      beltTypeId: 1,
      averageRating: 4.6,
    ),
    Belt(
      id: 2,
      name: 'Casual Canvas Belt',
      code: 'CCB002',
      price: 45.0,
      description: 'Casual canvas belt for everyday wear',
      beltTypeId: 2,
      averageRating: 4.2,
    ),
    Belt(
      id: 3,
      name: 'Braided Leather Belt',
      code: 'BLB003',
      price: 120.0,
      description: 'Elegant braided leather belt',
      beltTypeId: 1,
      averageRating: 4.9,
    ),
  ];

  @override
  Future<List<Belt>> getBelts({int? beltTypeId, String? query}) async {
    List<Belt> result = mockBelts;
    if (beltTypeId != null) {
      result = result.where((Belt b) => b.beltTypeId == beltTypeId).toList();
    }
    if (query != null && query.isNotEmpty) {
      result = result.where((Belt b) => 
        b.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return result;
  }

  @override
  Future<Belt> getBelt(int id) async {
    return mockBelts.firstWhere((Belt b) => b.id == id);
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
    final Belt newBelt = Belt(
      id: mockBelts.length + 1,
      name: name,
      code: code,
      price: price,
      description: description ?? '',
      beltTypeId: beltTypeId,
    );
    mockBelts.add(newBelt);
    return newBelt;
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
    final int index = mockBelts.indexWhere((Belt b) => b.id == id);
    mockBelts[index] = Belt(
      id: id,
      name: name,
      code: code,
      price: price,
      description: description ?? '',
      beltTypeId: beltTypeId,
    );
    return mockBelts[index];
  }

  @override
  Future<void> deleteBelt(int id) async {
    mockBelts.removeWhere((Belt b) => b.id == id);
  }
}

/// Mock BeltTypesApi for testing
class MockBeltTypesApi extends BeltTypesApi {
  @override
  Future<List<BeltType>> getBeltTypes() async {
    return <BeltType>[
      BeltType(id: 1, name: 'Leather'),
      BeltType(id: 2, name: 'Canvas'),
      BeltType(id: 3, name: 'Braided'),
    ];
  }

  @override
  Future<BeltType> createBeltType(String name) async {
    return BeltType(id: 4, name: name);
  }

  @override
  Future<BeltType> updateBeltType(int id, String name) async {
    return BeltType(id: id, name: name);
  }

  @override
  Future<void> deleteBeltType(int id) async {}
}

/// Mock OrdersApi for testing
class MockOrdersApi extends OrdersApi {
  List<OrderItemModel> cartItems = <OrderItemModel>[];

  @override
  Future<OrderModel?> getActiveCart(int userId) async {
    if (cartItems.isEmpty) return null;
    return OrderModel(
      id: 1,
      orderNumber: '#001',
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
      orderNumber: '#001',
      date: DateTime.now(),
      userId: request.userId,
      amount: 0,
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
      name: 'Belt Item',
    ));
  }
}

/// Mock LocalFavoritesStorage for testing
class MockLocalFavoritesStorage extends LocalFavoritesStorage {
  Set<int> favorites = <int>{};

  @override
  Future<Set<int>> loadFavorites() async => favorites;

  @override
  Future<void> saveFavorites(Set<int> ids) async {
    favorites = ids;
  }
}

void main() {
  group('Belts List Screen Tests', () {
    late MockBeltsApi mockBeltsApi;
    late MockBeltTypesApi mockBeltTypesApi;
    late MockOrdersApi mockOrdersApi;
    late MockLocalFavoritesStorage mockFavoritesStorage;
    late ProviderContainer container;

    setUp(() {
      mockBeltsApi = MockBeltsApi();
      mockBeltTypesApi = MockBeltTypesApi();
      mockOrdersApi = MockOrdersApi();
      mockFavoritesStorage = MockLocalFavoritesStorage();

      container = ProviderContainer(
        overrides: <Override>[
          beltsApiProvider.overrideWith((Ref ref) => mockBeltsApi),
          beltTypesApiProvider.overrideWith((Ref ref) => mockBeltTypesApi),
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
          localFavoritesStorageProvider.overrideWith((Ref ref) => mockFavoritesStorage),
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
            initialLocation: '/belts',
            routes: <RouteBase>[
              GoRoute(
                path: '/belts',
                builder: (BuildContext context, GoRouterState state) =>
                    const BeltsListScreen(),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-BELT-001: Belts list screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Katalog kaiševa'), findsOneWidget);
      expect(find.text('Leather Belt Classic'), findsOneWidget);
      expect(find.text('Casual Canvas Belt'), findsOneWidget);
      expect(find.text('Braided Leather Belt'), findsOneWidget);
    });

    testWidgets('TC-BELT-002: Each belt shows name and price', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check price format
      expect(find.text('85.00 KM'), findsOneWidget);
      expect(find.text('45.00 KM'), findsOneWidget);
      expect(find.text('120.00 KM'), findsOneWidget);
    });

    testWidgets('TC-BELT-003: Search filters belts by name', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'Canvas');
      await tester.tap(find.text('Traži'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Casual Canvas Belt'), findsOneWidget);
    });

    testWidgets('TC-BELT-004: Belt type filter dropdown shows types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Type filter dropdown exists
      expect(find.byType(DropdownButton<int?>), findsOneWidget);
    });

    testWidgets('TC-BELT-005: Tapping belt navigates to detail screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap on first belt
      await tester.tap(find.text('Leather Belt Classic'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to detail screen
      expect(find.text('Detalji kaiša'), findsOneWidget);
    });

    testWidgets('TC-BELT-006: Add to cart button shows snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap add to cart button
      await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
      await tester.pumpAndSettle();

      // Assert - Snackbar should appear
      expect(find.text('Dodano u korpu'), findsOneWidget);
    });

    testWidgets('TC-BELT-007: Rating is displayed when available', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Rating should be shown
      expect(find.text('4.6'), findsOneWidget);
    });

    testWidgets('TC-BELT-008: Pull to refresh reloads list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - List should still be displayed
      expect(find.text('Leather Belt Classic'), findsOneWidget);
    });

    testWidgets('TC-BELT-009: Empty state shown when no results', (WidgetTester tester) async {
      // Arrange - Clear mock belts
      mockBeltsApi.mockBelts = <Belt>[];
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nema rezultata.'), findsOneWidget);
    });
  });

  group('Belt Detail Screen Tests', () {
    late MockBeltsApi mockBeltsApi;
    late MockOrdersApi mockOrdersApi;
    late MockLocalFavoritesStorage mockFavoritesStorage;
    late ProviderContainer container;

    setUp(() {
      mockBeltsApi = MockBeltsApi();
      mockOrdersApi = MockOrdersApi();
      mockFavoritesStorage = MockLocalFavoritesStorage();

      container = ProviderContainer(
        overrides: <Override>[
          beltsApiProvider.overrideWith((Ref ref) => mockBeltsApi),
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
          localFavoritesStorageProvider.overrideWith((Ref ref) => mockFavoritesStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createDetailTestWidget(int beltId) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/belts/$beltId',
            routes: <RouteBase>[
              GoRoute(
                path: '/belts/:id',
                builder: (BuildContext context, GoRouterState state) {
                  final int id = int.parse(state.pathParameters['id']!);
                  return BeltDetailScreen(id: id);
                },
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-BELT-010: Detail screen shows belt information', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detalji kaiša'), findsOneWidget);
      expect(find.text('Leather Belt Classic'), findsOneWidget);
      expect(find.text('85.00 KM'), findsOneWidget);
    });

    testWidgets('TC-BELT-011: Detail screen shows description', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Opis'), findsOneWidget);
      expect(find.text('Classic leather belt with silver buckle'), findsOneWidget);
    });

    testWidgets('TC-BELT-012: Add to cart from detail screen works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Dodaj u korpu'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TC-BELT-013: Belt code displayed on detail screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Šifra'), findsOneWidget);
      expect(find.text('LBC001'), findsOneWidget);
    });

    testWidgets('TC-BELT-014: Rating displayed on detail screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('4.6'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
