class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.type,
    required this.segment,
    this.launchDate,
    this.productName,
    this.price,
    this.color,
  });

  final int id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final AnnouncementType type;
  final String segment;
  final DateTime? launchDate;
  final String? productName;
  final double? price;
  final String? color;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final String? typeValue = json['type'] as String?;
    final String segment = json['segment'] as String? ?? '';
    final String? publishedAtRaw = (json['publishedAtUtc'] ?? json['publishedAt']) as String?;
    return Announcement(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      publishedAt: publishedAtRaw != null ? DateTime.parse(publishedAtRaw) : DateTime.now(),
      type: AnnouncementTypeExtension.fromSource(type: typeValue, segment: segment),
      segment: segment,
      launchDate: json['launchDate'] != null ? DateTime.tryParse(json['launchDate'] as String) : null,
      productName: json['productName'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'publishedAt': publishedAt.toIso8601String(),
      'type': type.name,
      'segment': segment,
      if (launchDate != null) 'launchDate': launchDate!.toIso8601String(),
      if (productName != null) 'productName': productName,
      if (price != null) 'price': price,
      if (color != null) 'color': color,
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

  static AnnouncementType fromSegment(String? segment) {
    switch (segment?.toLowerCase()) {
      case 'newcollectionsubscribers':
        return AnnouncementType.announcement;
      case 'giveawaysubscribers':
        return AnnouncementType.info;
      case 'allsubscribers':
      default:
        return AnnouncementType.update;
    }
  }

  static AnnouncementType fromSource({String? type, String? segment}) {
    if (type != null && type.isNotEmpty) {
      return fromString(type);
    }
    return fromSegment(segment);
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

