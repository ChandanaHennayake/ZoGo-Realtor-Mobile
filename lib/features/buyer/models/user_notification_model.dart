class UserNotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const UserNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      referenceId: json['referenceId']?.toString(),
      referenceType: json['referenceType']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
