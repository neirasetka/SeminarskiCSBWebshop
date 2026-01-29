import 'package:csb_webshop_mobile/src/features/auth/application/auth_controller.dart';
import 'package:csb_webshop_mobile/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_mobile/src/features/auth/domain/auth_session.dart';
import 'package:csb_webshop_mobile/src/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock AuthApi for testing
class MockAuthApi extends AuthApi {
  bool shouldSucceed = true;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<AuthSession> login({required String username, required String password}) async {
    lastUsername = username;
    lastPassword = password;
    if (shouldSucceed) {
      return AuthSession(
        token: 'test-token',
        userId: 1,
        username: username,
        roles: <String>['Buyer'],
      );
    } else {
      throw Exception('Invalid credentials');
    }
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

void main() {
  group('LoginScreen Tests', () {
    late MockAuthApi mockAuthApi;
    late ProviderContainer container;

    setUp(() {
      mockAuthApi = MockAuthApi();
      container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWith((Ref ref) => mockAuthApi),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({bool embedded = false}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/login',
            routes: <RouteBase>[
              GoRoute(
                path: '/login',
                builder: (BuildContext context, GoRouterState state) =>
                    LoginScreen(embedded: embedded),
              ),
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Home')),
              ),
              GoRoute(
                path: '/register',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Register')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-AUTH-001: Login screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dobrodošli nazad'), findsOneWidget);
      expect(find.text('Korisničko ime'), findsOneWidget);
      expect(find.text('Lozinka'), findsOneWidget);
      expect(find.text('Prijavi se'), findsOneWidget);
      expect(find.text('Nemate račun?'), findsOneWidget);
      expect(find.text('Registrirajte se'), findsOneWidget);
    });

    testWidgets('TC-AUTH-002: Shows validation error for empty username', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Leave username empty and tap login
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unesite korisničko ime'), findsOneWidget);
    });

    testWidgets('TC-AUTH-003: Shows validation error for empty password', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter username but leave password empty
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unesite lozinku'), findsOneWidget);
    });

    testWidgets('TC-AUTH-004: Successful login with valid credentials', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(mockAuthApi.lastUsername, 'testuser');
      expect(mockAuthApi.lastPassword, 'password123');
    });

    testWidgets('TC-AUTH-005: Shows error snackbar for invalid credentials', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = false;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'wronguser');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert - SnackBar should appear with error
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TC-AUTH-006: Password visibility toggle works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially password is obscured
      final TextFormField passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(passwordField.obscureText, isTrue);

      // Act - Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Assert - Password should be visible now
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('TC-AUTH-007: Navigate to register screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Registrirajte se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('TC-AUTH-008: Shows loading indicator during login', (WidgetTester tester) async {
      // Arrange - Create a delayed mock
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill in credentials and tap login
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Prijavi se'));
      
      // Pump once without settling to catch loading state
      await tester.pump();

      // Assert - Should show loading indicator (CircularProgressIndicator inside button)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('TC-AUTH-009: Embedded mode hides back button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(embedded: true));
      await tester.pumpAndSettle();

      // Assert - No AppBar in embedded mode
      expect(find.text('Natrag na početnu'), findsNothing);
    });

    testWidgets('TC-AUTH-010: Login form trims whitespace from username', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, '  testuser  ');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();

      // Assert
      expect(mockAuthApi.lastUsername, 'testuser');
    });
  });
}
