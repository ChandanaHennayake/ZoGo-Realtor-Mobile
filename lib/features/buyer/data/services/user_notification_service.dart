import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/user_notification_model.dart';

class UserNotificationService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  UserNotificationService([Dio? dio, SecureStorageService? secureStorage])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                validateStatus: (status) => status != null && status < 500,
              ),
            ),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please log in.');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserNotificationModel>> getNotifications({int limit = 50}) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.notifications}?limit=$limit';
      final response = await _dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final resData = response.data;
        final listData = resData is Map && resData.containsKey('data') && resData['data'] is List
            ? resData['data'] as List
            : (resData is List ? resData : []);

        return listData
            .map((item) => UserNotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      return [];
    } on DioException catch (dioErr) {
      debugPrint('DioException in getNotifications: $dioErr');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final headers = await _authHeaders();
      final url = ApiConstants.notificationsUnreadCount;
      final response = await _dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') ? resData['data'] : resData;
        if (data is Map && data.containsKey('unreadCount')) {
          return (data['unreadCount'] as num?)?.toInt() ?? 0;
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.notifications}/$id/read';
      final response = await _dio.put(url, options: Options(headers: headers));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final headers = await _authHeaders();
      final url = ApiConstants.notificationsReadAll;
      final response = await _dio.put(url, options: Options(headers: headers));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
