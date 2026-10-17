class ChatMessage {
  final String id;
  final String conversationId;
  final String propertyId;
  final String propertyTitle;
  final String senderId;
  final String senderName;
  final String senderRole; // 'agent' or 'buyer'
  final String recipientId;
  final String recipientName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.propertyId,
    required this.propertyTitle,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.recipientId,
    required this.recipientName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'buyer',
      recipientId: json['recipientId']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    bool? isRead,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      recipientId: recipientId,
      recipientName: recipientName,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
