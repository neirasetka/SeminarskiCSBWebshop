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
    return GiveawayParticipant(
      id: json['Id'] as int,
      name: json['Name'] as String?,
      emailOrMasked: json['Email'] as String? ?? '',
      entryDate: DateTime.parse(json['EntryDate'] as String).toUtc(),
      giveawayId: json['GiveawayId'] as int,
      isPublic: false,
    );
  }

  factory GiveawayParticipant.fromPublicJson(Map<String, dynamic> json) {
    return GiveawayParticipant(
      id: json['Id'] as int,
      name: json['Name'] as String?,
      emailOrMasked: json['MaskedEmail'] as String? ?? '',
      entryDate: DateTime.parse(json['EntryDate'] as String).toUtc(),
      giveawayId: json['GiveawayId'] as int,
      isPublic: true,
    );
  }
}

