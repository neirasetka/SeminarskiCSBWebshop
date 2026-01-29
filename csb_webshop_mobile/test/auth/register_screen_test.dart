import 'package:csb_webshop_mobile/src/features/auth/data/auth_api.dart';
import 'package:csb_webshop_mobile/src/features/auth/domain/auth_session.dart';
import 'package:csb_webshop_mobile/src/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mock AuthApi for testing registration
class MockAuthApi extends AuthApi {
  bool shouldSucceed = true;
  String? lastFirstName;
  String? lastLastName;
  String? lastEmail;
  String? lastUsername;
  String? lastPassword;
  String? lastPhone;

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    String? phone,
  }) async {
    lastFirstName = firstName;
    lastLastName = lastName;
    lastEmail = email;
    lastUsername = username;
    lastPassword = password;
    lastPhone = phone;

    if (shouldSucceed) {
      return AuthSession(
        token: 'test-token',
        userId: 1,
        username: username,
        roles: <String>['Buyer'],
      );
    } else {
      throw Exception('Registration failed: Username already exists');
    }
  }

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
  Future<void> logout() async {}
}

void main() {
  group('RegisterScreen Tests', () {
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

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/register',
            routes: <RouteBase>[
              GoRoute(
                path: '/register',
                builder: (BuildContext context, GoRouterState state) =>
                    const RegisterScreen(),
              ),
              GoRoute(
                path: '/login',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('Login Screen')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('TC-REG-001: Register screen displays all required fields', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Kreirajte račun'), findsOneWidget);
      expect(find.text('Ime'), findsOneWidget);
      expect(find.text('Prezime'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Telefon (opcionalno)'), findsOneWidget);
      expect(find.text('Korisničko ime'), findsOneWidget);
      expect(find.text('Lozinka'), findsOneWidget);
      expect(find.text('Potvrdite lozinku'), findsOneWidget);
      expect(find.text('Registriraj se'), findsOneWidget);
    });

    testWidgets('TC-REG-002: Shows validation error for empty first name', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Submit without filling first name
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ime je obavezno'), findsOneWidget);
    });

    testWidgets('TC-REG-003: Shows validation error for empty last name', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill only first name
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Prezime je obavezno'), findsOneWidget);
    });

    testWidgets('TC-REG-004: Shows validation error for invalid email format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill with invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'invalid-email');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unesite ispravnu email adresu'), findsOneWidget);
    });

    testWidgets('TC-REG-005: Shows validation error for short username', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill with short username
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      await tester.enterText(find.byType(TextFormField).at(4), 'ab'); // username
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Korisničko ime mora imati najmanje 3 znaka'), findsOneWidget);
    });

    testWidgets('TC-REG-006: Shows validation error for short password', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill with short password
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
      await tester.enterText(find.byType(TextFormField).at(5), '12345'); // password
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lozinka mora imati najmanje 6 znakova'), findsOneWidget);
    });

    testWidgets('TC-REG-007: Shows validation error for password mismatch', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill with mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.enterText(find.byType(TextFormField).at(6), 'differentpassword');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lozinke se ne podudaraju'), findsOneWidget);
    });

    testWidgets('TC-REG-008: Successful registration with valid data', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill all required fields
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      await tester.enterText(find.byType(TextFormField).at(3), '+387123456'); // phone
      await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.enterText(find.byType(TextFormField).at(6), 'password123');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert - Should redirect to login
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('TC-REG-009: Shows error snackbar on registration failure', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = false;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill all fields and submit
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.enterText(find.byType(TextFormField).at(6), 'password123');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert - Error snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TC-REG-010: Password visibility toggle works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap password visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
    });

    testWidgets('TC-REG-011: Navigate to login screen from register', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Prijavite se'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('TC-REG-012: Back button navigates to login', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('TC-REG-013: Phone field is optional', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Fill all required fields but not phone
      await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
      await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
      await tester.enterText(find.byType(TextFormField).at(2), 'marko@test.com');
      // Skip phone field (index 3)
      await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
      await tester.enterText(find.byType(TextFormField).at(5), 'password123');
      await tester.enterText(find.byType(TextFormField).at(6), 'password123');
      await tester.tap(find.text('Registriraj se'));
      await tester.pumpAndSettle();

      // Assert - Should succeed without phone
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('TC-REG-014: Valid email formats are accepted', (WidgetTester tester) async {
      // Arrange
      mockAuthApi.shouldSucceed = true;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test various valid email formats
      final List<String> validEmails = <String>[
        'test@example.com',
        'user.name@domain.com',
        'user-name@domain.co.uk',
        'user_name@sub.domain.com',
      ];

      for (final String email in validEmails) {
        // Clear and refill
        await tester.enterText(find.byType(TextFormField).at(0), 'Marko');
        await tester.enterText(find.byType(TextFormField).at(1), 'Markovic');
        await tester.enterText(find.byType(TextFormField).at(2), email);
        await tester.enterText(find.byType(TextFormField).at(4), 'marko123');
        await tester.enterText(find.byType(TextFormField).at(5), 'password123');
        await tester.enterText(find.byType(TextFormField).at(6), 'password123');
        await tester.tap(find.text('Registriraj se'));
        await tester.pump();

        // Should not show email validation error
        expect(find.text('Unesite ispravnu email adresu'), findsNothing);
      }
    });
  });
}
