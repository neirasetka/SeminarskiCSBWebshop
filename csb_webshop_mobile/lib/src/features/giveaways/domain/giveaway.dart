class Giveaway {
  const Giveaway({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isClosed,
    this.winnerParticipantId,
  });

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isClosed;
  final int? winnerParticipantId;

  bool get isActiveNow {
    final DateTime now = DateTime.now().toUtc();
    return !isClosed && startDate.isBefore(now) && endDate.isAfter(now);
  }

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    return Giveaway(
      id: json['Id'] as int,
      title: json['Title'] as String,
      startDate: DateTime.parse(json['StartDate'] as String).toUtc(),
      endDate: DateTime.parse(json['EndDate'] as String).toUtc(),
      isClosed: json['IsClosed'] as bool,
      winnerParticipantId: json['WinnerParticipantId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Id': id,
      'Title': title,
      'StartDate': startDate.toUtc().toIso8601String(),
      'EndDate': endDate.toUtc().toIso8601String(),
      'IsClosed': isClosed,
      'WinnerParticipantId': winnerParticipantId,
    };
  }
}

