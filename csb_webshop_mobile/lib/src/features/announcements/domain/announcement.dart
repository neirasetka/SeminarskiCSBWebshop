class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.type,
  });

  final int id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final AnnouncementType type;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      type: AnnouncementTypeExtension.fromString(json['type'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'publishedAt': publishedAt.toIso8601String(),
      'type': type.name,
    };
  }
}

enum AnnouncementType { announcement, update, info }

extension AnnouncementTypeExtension on AnnouncementType {
  static AnnouncementType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'announcement':
        return AnnouncementType.announcement;
      case 'update':
        return AnnouncementType.update;
      case 'info':
      default:
        return AnnouncementType.info;
    }
  }

  String get displayLabel {
    switch (this) {
      case AnnouncementType.announcement:
        return 'Najava';
      case AnnouncementType.update:
        return 'Update';
      case AnnouncementType.info:
        return 'Obavijest';
    }
  }
}

