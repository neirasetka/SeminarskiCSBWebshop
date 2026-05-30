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
      notificationID: json['notificationID'] ?? 0,
      userID: json['userID'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedEntityID: json['relatedEntityID'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
