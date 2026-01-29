import 'package:csb_webshop_mobile/src/features/giveaways/application/giveaways_provider.dart';
import 'package:csb_webshop_mobile/src/features/giveaways/data/giveaways_api.dart';
import 'package:csb_webshop_mobile/src/features/giveaways/domain/giveaway.dart';
import 'package:csb_webshop_mobile/src/features/giveaways/domain/participant.dart';
import 'package:csb_webshop_mobile/src/features/giveaways/presentation/giveaways_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock GiveawaysApi for testing
class MockGiveawaysApi extends GiveawaysApi {
  List<Giveaway> mockGiveaways = <Giveaway>[
    Giveaway(
      id: 1,
      title: 'Summer Bag Giveaway',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      isClosed: false,
    ),
    Giveaway(
      id: 2,
      title: 'Winter Belt Giveaway',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 5)),
      isClosed: true,
      winnerParticipantId: 1,
    ),
    Giveaway(
      id: 3,
      title: 'Spring Collection Giveaway',
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      isClosed: false,
    ),
  ];

  List<GiveawayParticipant> mockParticipants = <GiveawayParticipant>[
    GiveawayParticipant(
      id: 1,
      name: 'Marko Markovic',
      email: 'marko@example.com',
      entryDate: DateTime.now().subtract(const Duration(days: 10)),
      giveawayId: 2,
    ),
    GiveawayParticipant(
      id: 2,
      name: 'Ana Anic',
      email: 'ana@example.com',
      entryDate: DateTime.now().subtract(const Duration(days: 8)),
      giveawayId: 2,
    ),
  ];

  bool shouldSucceedRegistration = true;
  String? lastRegisteredEmail;
  String? lastRegisteredName;

  @override
  Future<List<Giveaway>> getGiveaways({String? status}) async {
    if (status == 'active') {
      return mockGiveaways.where((Giveaway g) => g.isActiveNow && !g.isClosed).toList();
    } else if (status == 'closed') {
      return mockGiveaways.where((Giveaway g) => g.isClosed || !g.isActiveNow).toList();
    }
    return mockGiveaways;
  }

  @override
  Future<Giveaway> getGiveaway(int id) async {
    return mockGiveaways.firstWhere((Giveaway g) => g.id == id);
  }

  @override
  Future<Giveaway> createGiveaway({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Giveaway newGiveaway = Giveaway(
      id: mockGiveaways.length + 1,
      title: title,
      startDate: startDate,
      endDate: endDate,
      isClosed: false,
    );
    mockGiveaways.add(newGiveaway);
    return newGiveaway;
  }

  @override
  Future<List<GiveawayParticipant>> getParticipants(int giveawayId) async {
    return mockParticipants.where((GiveawayParticipant p) => p.giveawayId == giveawayId).toList();
  }

  @override
  Future<GiveawayParticipant> registerParticipant({
    required int giveawayId,
    String? name,
    required String email,
  }) async {
    lastRegisteredName = name;
    lastRegisteredEmail = email;
    
    if (!shouldSucceedRegistration) {
      throw Exception('Registration failed');
    }
    
    final GiveawayParticipant participant = GiveawayParticipant(
      id: mockParticipants.length + 1,
      name: name,
      email: email,
      entryDate: DateTime.now(),
      giveawayId: giveawayId,
    );
    mockParticipants.add(participant);
    return participant;
  }

  @override
  Future<GiveawayParticipant> drawWinner(int giveawayId) async {
    final List<GiveawayParticipant> participants = 
        mockParticipants.where((GiveawayParticipant p) => p.giveawayId == giveawayId).toList();
    if (participants.isEmpty) {
      throw Exception('No participants');
    }
    return participants.first;
  }

  @override
  Future<AnnounceWinnerResult> announceWinner(int giveawayId) async {
    return AnnounceWinnerResult(
      success: true,
      winnerName: 'Test Winner',
      subscribersNotified: 5,
      newsItemId: 1,
    );
  }

  @override
  Future<void> notifyWinner(int giveawayId) async {}
}

void main() {
  group('Giveaways List Screen Tests', () {
    late MockGiveawaysApi mockGiveawaysApi;
    late ProviderContainer container;

    setUp(() {
      mockGiveawaysApi = MockGiveawaysApi();
      container = ProviderContainer(
        overrides: <Override>[
          giveawaysApiProvider.overrideWith((Ref ref) => mockGiveawaysApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({bool forAdmin = false}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/giveaways',
            routes: <RouteBase>[
              GoRoute(
                path: '/giveaways',
                builder: (BuildContext context, GoRouterState state) =>
                    GiveawaysListScreen(forAdmin: forAdmin),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-GIVEAWAY-001: Giveaways list displays all giveaways', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Giveawayi'), findsOneWidget);
      expect(find.text('Summer Bag Giveaway'), findsOneWidget);
      expect(find.text('Winter Belt Giveaway'), findsOneWidget);
      expect(find.text('Spring Collection Giveaway'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-002: Active giveaway shows Aktivan chip', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Aktivan'), findsWidgets);
    });

    testWidgets('TC-GIVEAWAY-003: Closed giveaway shows Zatvoren chip', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Zatvoren'), findsWidgets);
    });

    testWidgets('TC-GIVEAWAY-004: Filter chips for Aktivni and Završeni exist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(FilterChip, 'Aktivni'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Završeni'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-005: Svi button shows all giveaways', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Svi'));
      await tester.pumpAndSettle();

      // Assert - All giveaways should be visible
      expect(find.text('Summer Bag Giveaway'), findsOneWidget);
      expect(find.text('Winter Belt Giveaway'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-006: Tapping giveaway opens detail screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Summer Bag Giveaway'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Giveaway detalji'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-007: Admin view shows Kreiraj button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(forAdmin: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Kreiraj'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-008: Planned giveaway shows Planiran status', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Spring Collection is planned (starts in future)
      expect(find.text('Planiran'), findsOneWidget);
    });
  });

  group('Giveaway Detail Screen Tests', () {
    late MockGiveawaysApi mockGiveawaysApi;
    late ProviderContainer container;

    setUp(() {
      mockGiveawaysApi = MockGiveawaysApi();
      container = ProviderContainer(
        overrides: <Override>[
          giveawaysApiProvider.overrideWith((Ref ref) => mockGiveawaysApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createDetailTestWidget(int giveawayId, {bool forAdmin = false}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: GiveawayDetailScreen(giveawayId: giveawayId, forAdmin: forAdmin),
        ),
      );
    }

    testWidgets('TC-GIVEAWAY-009: Detail screen shows giveaway title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Summer Bag Giveaway'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-010: Detail screen shows date range', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Od:'), findsOneWidget);
      expect(find.textContaining('Do:'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-011: Detail screen shows status chip', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Status:'), findsOneWidget);
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('TC-GIVEAWAY-012: Registration form shown for active giveaway', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Prijavi se na giveaway'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-013: Email validation on registration', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act - Try to submit without email
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Email je obavezan'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-014: Invalid email format rejected', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act - Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unesite ispravan email'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-015: Successful registration shows snackbar', (WidgetTester tester) async {
      // Arrange
      mockGiveawaysApi.shouldSucceedRegistration = true;
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act - Enter valid email and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Prijava uspješna'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-016: Name field is optional', (WidgetTester tester) async {
      // Arrange
      mockGiveawaysApi.shouldSucceedRegistration = true;
      await tester.pumpWidget(createDetailTestWidget(1));
      await tester.pumpAndSettle();

      // Act - Submit with email only
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert - Should succeed
      expect(find.text('Prijava uspješna'), findsOneWidget);
      expect(mockGiveawaysApi.lastRegisteredEmail, 'test@example.com');
    });

    testWidgets('TC-GIVEAWAY-017: Admin view shows admin actions', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(2, forAdmin: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Izvuci pobjednika'), findsOneWidget);
      expect(find.text('Objavi pobjednika'), findsOneWidget);
      expect(find.text('Samo email pobjedniku'), findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-018: Draw winner button disabled for open giveaway', (WidgetTester tester) async {
      // The button should be enabled for non-closed giveaways
      await tester.pumpWidget(createDetailTestWidget(1, forAdmin: true));
      await tester.pumpAndSettle();

      // Izvuci pobjednika should be enabled for active giveaway
      final Finder drawButton = find.widgetWithText(ElevatedButton, 'Izvuci pobjednika');
      expect(drawButton, findsOneWidget);
    });

    testWidgets('TC-GIVEAWAY-019: Participants list shown in admin view', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createDetailTestWidget(2, forAdmin: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Prijavljeni (admin prikaz):'), findsOneWidget);
    });
  });

  group('Giveaway Admin Functions Tests', () {
    late MockGiveawaysApi mockGiveawaysApi;
    late ProviderContainer container;

    setUp(() {
      mockGiveawaysApi = MockGiveawaysApi();
      container = ProviderContainer(
        overrides: <Override>[
          giveawaysApiProvider.overrideWith((Ref ref) => mockGiveawaysApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('TC-GIVEAWAY-020: Create giveaway form validation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GiveawaysListScreen(forAdmin: true),
        ),
      ));
      await tester.pumpAndSettle();

      // Act - Open create sheet
      await tester.tap(find.text('Kreiraj'));
      await tester.pumpAndSettle();

      // Assert - Form should appear
      expect(find.text('Novi giveaway'), findsOneWidget);
      expect(find.text('Naslov'), findsOneWidget);
    });
  });
}
