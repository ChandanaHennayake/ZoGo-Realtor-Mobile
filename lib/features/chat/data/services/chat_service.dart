import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/chat_message.dart';

class ChatService {
  ChatService();

  static String buildConversationId(String propertyId, String buyerId) {
    return 'chat_${propertyId}_$buyerId';
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final key = 'messages_$conversationId';
      final jsonStr = await _storageSecureRead(key);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String propertyId,
    required String propertyTitle,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String recipientId,
    required String recipientName,
    required String text,
  }) async {
    final existing = await getMessages(conversationId);
    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      recipientId: recipientId,
      recipientName: recipientName,
      message: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    final updated = List<ChatMessage>.from(existing)..add(newMessage);
    final jsonStr = jsonEncode(updated.map((m) => m.toJson()).toList());
    await _storageSecureWrite('messages_$conversationId', jsonStr);

    // Also update conversation metadata
    await _recordConversationMetadata(
      conversationId: conversationId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      lastMessage: text.trim(),
      lastMessageTime: DateTime.now(),
      participantId: recipientId,
      participantName: recipientName,
      participantRole: senderRole == 'agent' ? 'buyer' : 'agent',
    );
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final convListKey = 'user_conversations';
      final existingRaw = await _storageSecureRead(convListKey);
      if (existingRaw != null && existingRaw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(existingRaw);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  Future<void> seedInitialGreetingIfEmpty({
    required String conversationId,
    required String propertyId,
    required String propertyTitle,
    required String agentId,
    required String agentName,
    required String buyerId,
    required String buyerName,
    String? recipientRole,
  }) async {
    final existing = await getMessages(conversationId);
    if (existing.isEmpty) {
      final isSeller = (recipientRole ?? '').toLowerCase() == 'seller';
      final greeting = ChatMessage(
        id: 'msg_greet_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        senderId: agentId.isNotEmpty ? agentId : 'agent_default',
        senderName: agentName.isNotEmpty ? agentName : 'Assigned ZoGo Agent',
        senderRole: 'agent',
        recipientId: buyerId,
        recipientName: buyerName,
        message: isSeller
            ? 'Hello $buyerName! Feel free to ask questions regarding "$propertyTitle", listing review, or coordinating with potential buyers.'
            : 'Hello $buyerName! Thank you for showing interest in "$propertyTitle". Feel free to ask questions or discuss visit arrangements here.',
        timestamp: DateTime.now(),
        isRead: true,
      );

      final updated = [greeting];
      await _storageSecureWrite('messages_$conversationId', jsonEncode(updated.map((m) => m.toJson()).toList()));
    }
  }

  Future<void> _recordConversationMetadata({
    required String conversationId,
    required String propertyId,
    required String propertyTitle,
    required String lastMessage,
    required DateTime lastMessageTime,
    required String participantId,
    required String participantName,
    required String participantRole,
  }) async {
    try {
      final convListKey = 'user_conversations';
      final existingRaw = await _storageSecureRead(convListKey);
      List<dynamic> list = [];
      if (existingRaw != null && existingRaw.isNotEmpty) {
        try {
          list = jsonDecode(existingRaw) as List;
        } catch (_) {}
      }

      list.removeWhere((item) => item['conversationId'] == conversationId);
      list.insert(0, {
        'conversationId': conversationId,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'participantId': participantId,
        'participantName': participantName,
        'participantRole': participantRole,
      });

      await _storageSecureWrite(convListKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error updating conversation metadata: $e');
    }
  }

  // Internal persistent + memory storage
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final Map<String, String> _inMemoryChatFallback = {};

  Future<String?> _storageSecureRead(String key) async {
    try {
      final val = await _secureStorage.read(key: key);
      if (val != null && val.isNotEmpty) return val;
      return _inMemoryChatFallback[key];
    } catch (_) {
      return _inMemoryChatFallback[key];
    }
  }

  Future<void> _storageSecureWrite(String key, String value) async {
    _inMemoryChatFallback[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }
}
