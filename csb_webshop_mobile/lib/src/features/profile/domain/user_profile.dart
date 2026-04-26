class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;

  String get fullName {
    final String a = firstName.trim();
    final String b = lastName.trim();
    if (a.isEmpty && b.isEmpty) {
      final String u = username.trim();
      if (u.isNotEmpty) return u;
      return email.trim();
    }
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a $b';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final String? avatarUrl = (json['AvatarUrl'] ?? json['avatarUrl'])
        ?.toString();
    final Object? imageData = json['Image'] ?? json['image'];
    final String? avatarFromImage = imageData is String && imageData.isNotEmpty
        ? 'data:image/png;base64,$imageData'
        : null;

    return UserProfile(
      id: _toInt(
        json['UserID'] ??
            json['userID'] ??
            json['userId'] ??
            json['id'] ??
            json['ID'] ??
            0,
      ),
      username: (json['UserName'] ?? json['username'] ?? '').toString(),
      firstName: (json['Name'] ?? json['FirstName'] ?? json['firstName'] ?? '')
          .toString(),
      lastName: (json['Surname'] ?? json['LastName'] ?? json['lastName'] ?? '')
          .toString(),
      email: (json['Email'] ?? json['email'] ?? '').toString(),
      phone: (json['Phone'] ?? json['phone'])?.toString(),
      avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl : avatarFromImage,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'Name': firstName,
      'Surname': lastName,
      if (phone != null) 'Phone': phone,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      username: username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
