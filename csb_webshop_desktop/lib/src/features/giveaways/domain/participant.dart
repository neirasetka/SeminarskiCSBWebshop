class GiveawayParticipant {
  const GiveawayParticipant({
    required this.id,
    this.name,
    required this.emailOrMasked,
    required this.entryDate,
    required this.giveawayId,
    this.isPublic = false,
  });

  final int id;
  final String? name;
  final String emailOrMasked;
  final DateTime entryDate;
  final int giveawayId;
  final bool isPublic;

  factory GiveawayParticipant.fromAdminJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    DateTime toDateTimeUtc(dynamic value) {
      if (value is DateTime) return value.toUtc();
      if (value is String) return DateTime.parse(value).toUtc();
      throw ArgumentError('Invalid date value: $value');
    }

    return GiveawayParticipant(
      id: toInt(json['Id'] ?? json['id']) ?? 0,
      name: (json['Name'] ?? json['name']) as String?,
      emailOrMasked: (json['Email'] ?? json['email'] ?? '') as String,
      entryDate: toDateTimeUtc(json['EntryDate'] ?? json['entryDate']),
      giveawayId: toInt(json['GiveawayId'] ?? json['giveawayId']) ?? 0,
      isPublic: false,
    );
  }

  factory GiveawayParticipant.fromPublicJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    DateTime toDateTimeUtc(dynamic value) {
      if (value is DateTime) return value.toUtc();
      if (value is String) return DateTime.parse(value).toUtc();
      throw ArgumentError('Invalid date value: $value');
    }

    return GiveawayParticipant(
      id: toInt(json['Id'] ?? json['id']) ?? 0,
      name: (json['Name'] ?? json['name']) as String?,
      emailOrMasked: (json['MaskedEmail'] ?? json['maskedEmail'] ?? '') as String,
      entryDate: toDateTimeUtc(json['EntryDate'] ?? json['entryDate']),
      giveawayId: toInt(json['GiveawayId'] ?? json['giveawayId']) ?? 0,
      isPublic: true,
    );
  }
}

