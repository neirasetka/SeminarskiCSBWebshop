import 'package:jwt_decoder/jwt_decoder.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresUtc,
    this.userId,
    this.username,
    this.roles = const <String>[],
  });

  final String token;
  final DateTime expiresUtc;
  final int? userId;
  final String? username;
  final List<String> roles;

  bool get isExpired => DateTime.now().isAfter(expiresUtc);

  bool hasAnyRole(Iterable<String> requiredRoles) {
    if (requiredRoles.isEmpty) return true;
    final Set<String> normalized = roles.map((String r) => r.toLowerCase()).toSet();
    return requiredRoles.any((String role) => normalized.contains(role.toLowerCase()));
  }

  AuthSession copyWith({
    String? token,
    DateTime? expiresUtc,
    int? userId,
    String? username,
    List<String>? roles,
  }) {
    return AuthSession(
      token: token ?? this.token,
      expiresUtc: expiresUtc ?? this.expiresUtc,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      roles: roles ?? this.roles,
    );
  }

  factory AuthSession.fromTokenResponse(Map<String, dynamic> json) {
    final String token = (json['Token'] ?? json['token'] ?? '').toString();
    if (token.isEmpty) {
      throw ArgumentError('Token response did not contain a token.');
    }
    final String? expiresString = (json['ExpiresUtc'] ?? json['expiresUtc'])?.toString();
    final DateTime expiresUtc = expiresString != null
        ? DateTime.tryParse(expiresString)?.toUtc() ?? JwtDecoder.getExpirationDate(token)
        : JwtDecoder.getExpirationDate(token);
    final Map<String, dynamic>? userJson = json['User'] as Map<String, dynamic>?;
    final int? userId = _readInt(userJson?['UserID'] ?? userJson?['ID'] ?? userJson?['id']);
    final String? username = userJson?['UserName']?.toString();
    return AuthSession(
      token: token,
      expiresUtc: expiresUtc,
      userId: userId ?? _readInt(_decodeClaim(token, <String>['nameid', 'sub', 'NameIdentifier'])),
      username: username ?? _decodeClaim(token, <String>['unique_name', 'name'])?.toString(),
      roles: _rolesFromToken(token),
    );
  }

  factory AuthSession.fromStoredToken(String token) {
    return AuthSession(
      token: token,
      expiresUtc: JwtDecoder.getExpirationDate(token),
      userId: _readInt(_decodeClaim(token, const <String>['nameid', 'sub', 'NameIdentifier'])),
      username: _decodeClaim(token, const <String>['unique_name', 'name'])?.toString(),
      roles: _rolesFromToken(token),
    );
  }

  static List<String> _rolesFromToken(String token) {
    final Map<String, dynamic> decoded = JwtDecoder.decode(token);
    final List<String> possibleKeys = <String>[
      'role',
      'roles',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role',
    ];
    final List<String> roles = <String>[];
    for (final String key in possibleKeys) {
      final Object? value = decoded[key];
      if (value == null) continue;
      if (value is Iterable) {
        roles.addAll(value.map((e) => e.toString()));
      } else {
        roles.add(value.toString());
      }
    }
    return roles.where((String r) => r.isNotEmpty).toSet().toList();
  }

  static Object? _decodeClaim(String token, List<String> keys) {
    final Map<String, dynamic> decoded = JwtDecoder.decode(token);
    for (final String key in keys) {
      if (decoded.containsKey(key)) return decoded[key];
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

