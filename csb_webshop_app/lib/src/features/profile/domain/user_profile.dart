class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      firstName: (json['firstName'] ?? json['ime'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['prezime'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

