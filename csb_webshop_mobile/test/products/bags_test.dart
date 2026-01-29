import 'package:csb_webshop_mobile/src/features/bags/application/bags_provider.dart';
import 'package:csb_webshop_mobile/src/features/bags/application/bag_types_provider.dart';
import 'package:csb_webshop_mobile/src/features/bags/data/bags_api.dart';
import 'package:csb_webshop_mobile/src/features/bags/data/bag_types_api.dart';
import 'package:csb_webshop_mobile/src/features/bags/domain/bag.dart';
import 'package:csb_webshop_mobile/src/features/bags/domain/bag_type.dart';
import 'package:csb_webshop_mobile/src/features/bags/presentation/bags_list_screen.dart';
import 'package:csb_webshop_mobile/src/features/bags/presentation/bags_detail_screen.dart';
import 'package:csb_webshop_mobile/src/features/favorites/application/favorites_provider.dart';
import 'package:csb_webshop_mobile/src/features/favorites/data/local_favorites_storage.dart';
import 'package:csb_webshop_mobile/src/features/orders/application/cart_provider.dart';
import 'package:csb_webshop_mobile/src/features/orders/data/orders_api.dart';
import 'package:csb_webshop_mobile/src/features/orders/domain/order_models.dart';
import 'package:csb_webshop_mobile/src/features/auth/application/admin_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock BagsApi for testing
class MockBagsApi extends BagsApi {
  List<Bag> mockBags = <Bag>[
    Bag(
      id: 1,
      name: 'Luxury Handbag',
      code: 'LH001',
      price: 250.0,
      description: 'A beautiful luxury handbag made of genuine leather',
      bagTypeId: 1,
      averageRating: 4.5,
      imageUrl: 'https://example.com/bag1.jpg',
    ),
    Bag(
      id: 2,
      name: 'Casual Tote',
      code: 'CT002',
      price: 75.0,
      description: 'Everyday casual tote bag',
      bagTypeId: 2,
      averageRating: 4.0,
    ),
    Bag(
      id: 3,
      name: 'Evening Clutch',
      code: 'EC003',
      price: 150.0,
      description: 'Elegant evening clutch',
      bagTypeId: 1,
      averageRating: 4.8,
    ),
  ];

  @override
  Future<List<Bag>> getBags({int? bagTypeId, String? query}) async {
    List<Bag> result = mockBags;
    if (bagTypeId != null) {
      result = result.where((Bag b) => b.bagTypeId == bagTypeId).toList();
    }
    if (query != null && query.isNotEmpty) {
      result = result.where((Bag b) => 
        b.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return result;
  }

  @override
  Future<Bag> getBag(int id) async {
    return mockBags.firstWhere((Bag b) => b.id == id);
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
    final Bag newBag = Bag(
      id: mockBags.length + 1,
      name: name,
      code: code,
      price: price,
      description: description ?? '',
      bagTypeId: bagTypeId,
    );
    mockBags.add(newBag);
    return newBag;
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
    final int index = mockBags.indexWhere((Bag b) => b.id == id);
    mockBags[index] = Bag(
      id: id,
      name: name,
      code: code,
      price: price,
      description: description ?? '',
      bagTypeId: bagTypeId,
    );
    return mockBags[index];
  }

  @override
  Future<void> deleteBag(int id) async {
    mockBags.removeWhere((Bag b) => b.id == id);
  }
}

/// Mock BagTypesApi for testing
class MockBagTypesApi extends BagTypesApi {
  @override
  Future<List<BagType>> getBagTypes() async {
    return <BagType>[
      BagType(id: 1, name: 'Luxury'),
      BagType(id: 2, name: 'Casual'),
      BagType(id: 3, name: 'Evening'),
    ];
  }

  @override
  Future<BagType> createBagType(String name) async {
    return BagType(id: 4, name: name);
  }

  @override
  Future<BagType> updateBagType(int id, String name) async {
    return BagType(id: id, name: name);
  }

  @override
  Future<void> deleteBagType(int id) async {}
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
      name: 'Item',
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
  group('Bags List Screen Tests', () {
    late MockBagsApi mockBagsApi;
    late MockBagTypesApi mockBagTypesApi;
    late MockOrdersApi mockOrdersApi;
    late MockLocalFavoritesStorage mockFavoritesStorage;
    late ProviderContainer container;

    setUp(() {
      mockBagsApi = MockBagsApi();
      mockBagTypesApi = MockBagTypesApi();
      mockOrdersApi = MockOrdersApi();
      mockFavoritesStorage = MockLocalFavoritesStorage();

      container = ProviderContainer(
        overrides: <Override>[
          bagsApiProvider.overrideWith((Ref ref) => mockBagsApi),
          bagTypesApiProvider.overrideWith((Ref ref) => mockBagTypesApi),
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
            initialLocation: '/bags',
            routes: <RouteBase>[
              GoRoute(
                path: '/bags',
                builder: (BuildContext context, GoRouterState state) =>
                    const BagsListScreen(),
              ),
              GoRoute(
                path: '/bags/:id/outfit-idea',
                name: 'outfitIdea',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Outfit Idea')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-BAG-001: Bags list screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Katalog torbi'), findsOneWidget);
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('Casual Tote'), findsOneWidget);
      expect(find.text('Evening Clutch'), findsOneWidget);
    });

    testWidgets('TC-BAG-002: Each bag shows name, price, and image placeholder', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check price format
      expect(find.text('250.00 KM'), findsOneWidget);
      expect(find.text('75.00 KM'), findsOneWidget);
    });

    testWidgets('TC-BAG-003: Search filters bags by name', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'Luxury');
      await tester.tap(find.text('Traži'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Luxury Handbag'), findsOneWidget);
    });

    testWidgets('TC-BAG-004: Bag type filter dropdown shows types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Type filter dropdown exists
      expect(find.byType(DropdownButton<int?>), findsOneWidget);
    });

    testWidgets('TC-BAG-005: Tapping bag navigates to detail screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap on first bag
      await tester.tap(find.text('Luxury Handbag'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to detail screen
      expect(find.text('Detalji torbe'), findsOneWidget);
    });

    testWidgets('TC-BAG-006: Favorite button toggles favorite status', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap favorite button
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();

      // Assert - Should show filled heart
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('TC-BAG-007: Add to cart button shows snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap add to cart button
      await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
      await tester.pumpAndSettle();

      // Assert - Snackbar should appear
      expect(find.text('Dodano u korpu'), findsOneWidget);
    });

    testWidgets('TC-BAG-008: Rating is displayed when available', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Rating should be shown
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('TC-BAG-009: Pull to refresh reloads list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - List should still be displayed
      expect(find.text('Luxury Handbag'), findsOneWidget);
    });

    testWidgets('TC-BAG-010: Empty state shown when no results', (WidgetTester tester) async {
      // Arrange - Clear mock bags
      mockBagsApi.mockBags = <Bag>[];
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nema rezultata.'), findsOneWidget);
    });
  });

  group('Bag Detail Screen Tests', () {
    late MockBagsApi mockBagsApi;
    late MockOrdersApi mockOrdersApi;
    late MockLocalFavoritesStorage mockFavoritesStorage;
    late ProviderContainer container;

    setUp(() {
      mockBagsApi = MockBagsApi();
      mockOrdersApi = MockOrdersApi();
      mockFavoritesStorage = MockLocalFavoritesStorage();

      container = ProviderContainer(
        overrides: <Override>[
          bagsApiProvider.overrideWith((Ref ref) => mockBagsApi),
          ordersApiProvider.overrideWith((Ref ref) => mockOrdersApi),
          localFavoritesStorageProvider.overrideWith((Ref ref) => mockFavoritesStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createDetailTestWidget(int bagId) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/bags/$bagId',
            routes: <RouteBase>[
              GoRoute(
                path: '/bags/:id',
                builder: (BuildContext context, GoRouterState state) {
                  final int id = int.parse(state.pathParameters['id']!);
                  return BagDetailScreen(id: id);
                },
              ),
              GoRoute(
                path: '/bags/:id/outfit-idea',
                name: 'outfitIdea',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Outfit Idea Screen')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-BAG-011: Detail screen shows bag information', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detalji torbe'), findsOneWidget);
      expect(find.text('Luxury Handbag'), findsOneWidget);
      expect(find.text('250.00 KM'), findsOneWidget);
    });

    testWidgets('TC-BAG-012: Detail screen shows description', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Opis'), findsOneWidget);
      expect(find.text('A beautiful luxury handbag made of genuine leather'), findsOneWidget);
    });

    testWidgets('TC-BAG-013: Add to cart from detail screen works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Dodaj u korpu'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TC-BAG-014: Favorite toggle works from detail', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act - Toggle favorite
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Assert - Should show filled heart
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('TC-BAG-015: Outfit Idea button navigates correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Outfit Idea'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Outfit Idea Screen'), findsOneWidget);
    });

    testWidgets('TC-BAG-016: Rating displayed on detail screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('TC-BAG-017: Bag code displayed on detail screen', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Šifra'), findsOneWidget);
      expect(find.text('LH001'), findsOneWidget);
    });
  });
}
