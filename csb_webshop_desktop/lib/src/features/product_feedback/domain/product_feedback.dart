class ProductRate {
  const ProductRate({
    required this.id,
    required this.userId,
    required this.rating,
    this.bagId,
    this.beltId,
  });

  final int id;
  final int userId;
  final int rating;
  final int? bagId;
  final int? beltId;

  factory ProductRate.fromJson(Map<String, dynamic> json) {
    return ProductRate(
      id: _readInt(json, 'RateID', 'rateID', 'id') ?? 0,
      userId: _readInt(json, 'UserID', 'userID', 'userId') ?? 0,
      rating: _readInt(json, 'Rating', 'rating') ?? 0,
      bagId: _readInt(json, 'BagID', 'bagID', 'bagId'),
      beltId: _readInt(json, 'BeltID', 'beltID', 'beltId'),
    );
  }
}

class ProductReview {
  const ProductReview({
    required this.id,
    required this.comment,
    required this.date,
    required this.userId,
    this.userDisplayName,
    this.status = ReviewModerationStatus.pending,
    this.bagId,
    this.beltId,
  });

  final int id;
  final String comment;
  final DateTime date;
  final int userId;
  final String? userDisplayName;
  final ReviewModerationStatus status;
  final int? bagId;
  final int? beltId;

  String get productLabel {
    if (bagId != null) return 'Torba #$bagId';
    if (beltId != null) return 'Kaiš #$beltId';
    return 'Proizvod';
  }

  String get statusBadgeKey {
    switch (status) {
      case ReviewModerationStatus.approved:
        return 'Approved';
      case ReviewModerationStatus.rejected:
        return 'Rejected';
      case ReviewModerationStatus.pending:
        return 'Pending';
    }
  }

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final dynamic userJson = json['User'] ?? json['user'] ?? json['Users'] ?? json['users'];
    String? displayName;
    if (userJson is Map<String, dynamic>) {
      final String name = (userJson['Name'] ?? userJson['name'] ?? '').toString().trim();
      final String surname = (userJson['Surname'] ?? userJson['surname'] ?? '').toString().trim();
      final String combined = '$name $surname'.trim();
      if (combined.isNotEmpty) {
        displayName = combined;
      } else {
        displayName = (userJson['UserName'] ?? userJson['userName'] ?? '').toString().trim();
        if (displayName.isEmpty) displayName = null;
      }
    }

    final String? dateRaw = (json['Date'] ?? json['date'])?.toString();
    return ProductReview(
      id: _readInt(json, 'ReviewID', 'reviewID', 'id') ?? 0,
      comment: (json['Comment'] ?? json['comment'] ?? '').toString(),
      date: dateRaw != null ? DateTime.tryParse(dateRaw) ?? DateTime.now() : DateTime.now(),
      userId: _readInt(json, 'UserID', 'userID', 'userId') ?? 0,
      userDisplayName: displayName,
      status: _parseReviewStatus(json['Status'] ?? json['status']),
      bagId: _readInt(json, 'BagID', 'bagID', 'bagId'),
      beltId: _readInt(json, 'BeltID', 'beltID', 'beltId'),
    );
  }
}

enum ReviewModerationStatus { pending, approved, rejected }

ReviewModerationStatus _parseReviewStatus(dynamic raw) {
  if (raw == null) return ReviewModerationStatus.pending;
  if (raw is int) {
    switch (raw) {
      case 1:
        return ReviewModerationStatus.approved;
      case 2:
        return ReviewModerationStatus.rejected;
      default:
        return ReviewModerationStatus.pending;
    }
  }
  final String normalized = raw.toString().trim().toLowerCase();
  if (normalized == 'approved') return ReviewModerationStatus.approved;
  if (normalized == 'rejected') return ReviewModerationStatus.rejected;
  return ReviewModerationStatus.pending;
}

int reviewStatusToQueryValue(String statusKey) {
  switch (statusKey) {
    case 'Approved':
      return 1;
    case 'Rejected':
      return 2;
    default:
      return 0;
  }
}

int? _readInt(Map<String, dynamic> json, String k1, String k2, [String? k3]) {
  final dynamic raw = json[k1] ?? json[k2] ?? (k3 != null ? json[k3] : null);
  if (raw == null) return null;
  if (raw is int) return raw;
  return int.tryParse(raw.toString());
}
