import 'package:csb_webshop_desktop/src/features/auth/application/auth_controller.dart';
import 'package:csb_webshop_desktop/src/features/auth/application/admin_role_provider.dart';
import 'package:csb_webshop_desktop/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_desktop/src/features/auth/domain/auth_session.dart';
import 'package:csb_webshop_desktop/src/features/bags/application/bags_provider.dart';
import 'package:csb_webshop_desktop/src/features/bags/data/bags_api.dart';
import 'package:csb_webshop_desktop/src/features/bags/domain/bag.dart';
import 'package:csb_webshop_desktop/src/features/belts/application/belts_provider.dart';
import 'package:csb_webshop_desktop/src/features/belts/data/belts_api.dart';
import 'package:csb_webshop_desktop/src/features/belts/domain/belt.dart';
import 'package:csb_webshop_desktop/src/features/favorites/application/favorites_provider.dart';
import 'package:csb_webshop_desktop/src/features/favorites/data/local_favorites_storage.dart';
import 'package:csb_webshop_desktop/src/features/recommendations/application/recommendations_provider.dart';
import 'package:csb_webshop_desktop/src/features/recommendations/data/recommendations_api.dart';
import 'package:csb_webshop_desktop/src/features/announcements/application/announcements_provider.dart';
import 'package:csb_webshop_desktop/src/features/announcements/data/announcements_api.dart';
import 'package:csb_webshop_desktop/src/features/announcements/domain/announcement.dart';
import 'package:csb_webshop_desktop/src/features/root/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock AuthApi
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

/// Mock BagsApi
class MockBagsApi extends BagsApi {
  @override
  Future<List<Bag>> getBags({int? bagTypeId, String? query}) async {
    return <Bag>[
      Bag(id: 1, name: 'Test Bag', code: 'TB1', price: 100.0, description: 'Test'),
    ];
  }

  @override
  Future<Bag> getBag(int id) async {
    return Bag(id: id, name: 'Test Bag', code: 'TB1', price: 100.0, description: 'Test');
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

/// Mock BeltsApi
class MockBeltsApi extends BeltsApi {
  @override
  Future<List<Belt>> getBelts({int? beltTypeId, String? query}) async {
    return <Belt>[
      Belt(id: 1, name: 'Test Belt', code: 'TBL1', price: 50.0, description: 'Test'),
    ];
  }

  @override
  Future<Belt> getBelt(int id) async {
    return Belt(id: id, name: 'Test Belt', code: 'TBL1', price: 50.0, description: 'Test');
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

/// Mock RecommendationsApi
class MockRecommendationsApi extends RecommendationsApi {
  bool returnEmpty = false;

  @override
  Future<List<Bag>> getRecommendedBags({int? take}) async {
    if (returnEmpty) return <Bag>[];
    return <Bag>[
      Bag(id: 1, name: 'Recommended Bag', code: 'RB1', price: 200.0, description: 'For you'),
    ];
  }

  @override
  Future<List<Belt>> getRecommendedBelts({int? take}) async {
    if (returnEmpty) return <Belt>[];
    return <Belt>[
      Belt(id: 1, name: 'Recommended Belt', code: 'RBL1', price: 80.0, description: 'For you'),
    ];
  }
}

/// Mock AnnouncementsApi
class MockAnnouncementsApi extends AnnouncementsApi {
  @override
  Future<List<Announcement>> getAnnouncements() async {
    return <Announcement>[
      Announcement(
        id: 1,
        title: 'New Collection Arrived!',
        body: 'Check out our latest collection',
        publishedAt: DateTime.now(),
        segment: 'AllSubscribers',
        type: AnnouncementType.info,
      ),
    ];
  }
}

/// Mock LocalFavoritesStorage
class MockLocalFavoritesStorage extends LocalFavoritesStorage {
  @override
  Future<Set<int>> loadFavorites() async => <int>{};

  @override
  Future<void> saveFavorites(Set<int> ids) async {}
}

void main() {
  group('Desktop HomeScreen Tests', () {
    late ProviderContainer container;
    late MockRecommendationsApi mockRecommendationsApi;

    setUp(() {
      mockRecommendationsApi = MockRecommendationsApi();
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
          bagsApiProvider.overrideWith((Ref ref) => MockBagsApi()),
          beltsApiProvider.overrideWith((Ref ref) => MockBeltsApi()),
          recommendationsApiProvider.overrideWith((Ref ref) => mockRecommendationsApi),
          announcementsApiProvider.overrideWith((Ref ref) => MockAnnouncementsApi()),
          localFavoritesStorageProvider.overrideWith((Ref ref) => MockLocalFavoritesStorage()),
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
            initialLocation: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
              GoRoute(
                path: '/bags',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Bags Screen')),
              ),
              GoRoute(
                path: '/belts',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Belts Screen')),
              ),
              GoRoute(
                path: '/torbice',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Torbice Shop')),
              ),
              GoRoute(
                path: '/kaisevi',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Kaisevi Shop')),
              ),
              GoRoute(
                path: '/lookbook',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Lookbook')),
              ),
              GoRoute(
                path: '/giveaways',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Giveaways')),
              ),
              GoRoute(
                path: '/checkout',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Checkout')),
              ),
              GoRoute(
                path: '/reports',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Reports')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-DESKTOP-001: Home screen shows welcome message', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dobro došli'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-002: Home screen shows navigation shortcuts', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for navigation shortcuts
      expect(find.text('Bags'), findsOneWidget);
      expect(find.text('Torbice'), findsOneWidget);
      expect(find.text('Belts'), findsOneWidget);
      expect(find.text('Kaisevi'), findsOneWidget);
      expect(find.text('Lookbook'), findsOneWidget);
      expect(find.text('Giveaway'), findsOneWidget);
      expect(find.text('Korpa'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-003: Bags shortcut navigates to bags', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Bags'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Bags Screen'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-004: Torbice shortcut navigates to shop', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Torbice'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Torbice Shop'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-005: Belts shortcut navigates to belts', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Belts'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Belts Screen'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-006: Kaisevi shortcut navigates to shop', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Kaisevi'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Kaisevi Shop'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-007: Lookbook shortcut navigates to lookbook', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Lookbook'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lookbook'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-008: Giveaway shortcut navigates to giveaways', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Giveaway'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Giveaways'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-009: Korpa shortcut navigates to checkout', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Korpa'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-010: For You section exists for logged in users', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('For You'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-011: For You shows recommendations subtitle', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('recommended'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-012: Refresh button exists in For You section', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('TC-DESKTOP-013: Empty recommendations shows message', (WidgetTester tester) async {
      // Arrange
      mockRecommendationsApi.returnEmpty = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show empty message
      expect(find.textContaining('No recommendations'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-014: Browse Bags button shown when no recommendations', (WidgetTester tester) async {
      // Arrange
      mockRecommendationsApi.returnEmpty = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Browse Bags'), findsOneWidget);
      expect(find.text('Browse Belts'), findsOneWidget);
    });
  });

  group('Desktop For You Recommendations Tests', () {
    late ProviderContainer container;
    late MockRecommendationsApi mockRecommendationsApi;

    setUp(() {
      mockRecommendationsApi = MockRecommendationsApi();
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => MockAuthApi()),
          bagsApiProvider.overrideWith((Ref ref) => MockBagsApi()),
          beltsApiProvider.overrideWith((Ref ref) => MockBeltsApi()),
          recommendationsApiProvider.overrideWith((Ref ref) => mockRecommendationsApi),
          announcementsApiProvider.overrideWith((Ref ref) => MockAnnouncementsApi()),
          localFavoritesStorageProvider.overrideWith((Ref ref) => MockLocalFavoritesStorage()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('TC-DESKTOP-015: Recommended Bags section shows when data available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
              GoRoute(
                path: '/torbice/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Bag Detail')),
              ),
              GoRoute(
                path: '/kaisevi/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Belt Detail')),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Recommended Bags'), findsOneWidget);
    });

    testWidgets('TC-DESKTOP-016: Recommended Belts section shows when data available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
              GoRoute(
                path: '/torbice/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Bag Detail')),
              ),
              GoRoute(
                path: '/kaisevi/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Belt Detail')),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Recommended Belts'), findsOneWidget);
    });
  });
}
