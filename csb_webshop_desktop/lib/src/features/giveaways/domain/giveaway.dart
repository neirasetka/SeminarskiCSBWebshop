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
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final String lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
    }

    DateTime toDateTimeUtc(dynamic value) {
      if (value is DateTime) return value.toUtc();
      if (value is String) return DateTime.parse(value).toUtc();
      throw ArgumentError('Invalid date value: $value');
    }

    final int id = toInt(json['Id'] ?? json['id']) ?? 0;
    final String title = (json['Title'] ?? json['title'] ?? '').toString();
    final DateTime start = toDateTimeUtc(json['StartDate'] ?? json['startDate']);
    final DateTime end = toDateTimeUtc(json['EndDate'] ?? json['endDate']);
    final bool closed = toBool(json['IsClosed'] ?? json['isClosed']);
    final int? winnerId = toInt(json['WinnerParticipantId'] ?? json['winnerParticipantId']);

    return Giveaway(
      id: id,
      title: title,
      startDate: start,
      endDate: end,
      isClosed: closed,
      winnerParticipantId: winnerId,
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

