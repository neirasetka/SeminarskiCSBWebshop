class NotificationModel {
  final int notificationID;
  final int userID;
  final String type;
  final String title;
  final String message;
  final int? relatedEntityID;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationID,
    required this.userID,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityID,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationID: json['notificationID'] ?? json['NotificationID'] ?? 0,
      userID: json['userID'] ?? json['UserID'] ?? 0,
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      relatedEntityID: json['relatedEntityID'] ?? json['RelatedEntityID'],
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['CreatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
