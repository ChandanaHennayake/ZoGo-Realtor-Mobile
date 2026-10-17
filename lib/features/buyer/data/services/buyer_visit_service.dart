import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/property_visit_model.dart';

class BuyerVisitService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerVisitService([Dio? dio, SecureStorageService? secureStorage])
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

  String _parseErrorMessage(dynamic data, int? statusCode, String fallback) {
    if (data == null) return fallback;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString().trim();
      }
      if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
        return data['error'].toString().trim();
      }
      if (data['errors'] != null && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return (data['errors'] as List).join(', ');
      }
    }
    return fallback;
  }

  // ============================================================
  // SCHEDULE VISIT (POST /api/v1/visits)
  // ============================================================

  Future<PropertyVisitModel> scheduleVisit({
    required String propertyId,
    required DateTime scheduledAt,
    required String timeSlot,
    String? buyerNotes,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'propertyId': propertyId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'timeSlot': timeSlot,
        'buyerNotes': buyerNotes,
      };

      debugPrint('POST SCHEDULE VISIT: ${ApiConstants.visits} with body: $body');
      final response = await _dio.post(
        ApiConstants.visits,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') && resData['data'] != null
            ? resData['data']
            : resData;
        return PropertyVisitModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to schedule property visit (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException scheduling visit: $dioErr');
      throw Exception('Network error while scheduling visit. Please check connection.');
    }
  }

  // ============================================================
  // GET MY VISITS (GET /api/v1/visits/my)
  // ============================================================

  Future<List<PropertyVisitModel>> getMyVisits() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        ApiConstants.myVisits,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        final list = resData is Map && resData.containsKey('data') && resData['data'] is List
            ? resData['data'] as List
            : (resData is List ? resData : []);

        return list
            .map((item) => PropertyVisitModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to load visits (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException loading my visits: $dioErr');
      throw Exception('Network error while fetching visits.');
    }
  }

  // ============================================================
  // CANCEL VISIT (PUT /api/v1/visits/{visitId}/cancel)
  // ============================================================

  Future<PropertyVisitModel> cancelVisit(String visitId, {String? reason}) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.visits}/$visitId/cancel';
      final response = await _dio.put(
        url,
        data: {'reason': reason},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') && resData['data'] != null
            ? resData['data']
            : resData;
        return PropertyVisitModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to cancel visit (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException cancelling visit: $dioErr');
      throw Exception('Network error while cancelling visit.');
    }
  }
}
