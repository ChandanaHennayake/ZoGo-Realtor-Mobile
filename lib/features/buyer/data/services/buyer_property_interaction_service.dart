import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/buyer_property_interaction.dart';

class BuyerPropertyInteractionService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerPropertyInteractionService([Dio? dio, SecureStorageService? secureStorage])
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

  String _parseErrorMessage(dynamic data, int? statusCode, String fallback) {
    if (data == null) return fallback;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString().trim();
      }
      if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
        return data['title'].toString().trim();
      }
      if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
        return data['error'].toString().trim();
      }
    }
    return fallback;
  }

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

  // ============================================================
  // GET INTERACTION (GET /api/v1/buyer/property-interactions/{propertyId})
  // ============================================================

  Future<BuyerPropertyInteraction?> getInteraction(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/property-interactions/$propertyId';
      debugPrint('GET BUYER INTERACTION: ${_dio.options.baseUrl}$url');

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      debugPrint('GET INTERACTION STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return BuyerPropertyInteraction.fromJson(response.data as Map<String, dynamic>);
        } else if (response.data is Map) {
          return BuyerPropertyInteraction.fromJson(Map<String, dynamic>.from(response.data as Map));
        }
      }

      if (response.statusCode == 404) {
        return null;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      debugPrint('GET INTERACTION DIO ERROR: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('GET INTERACTION ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // SET / UPDATE INTERACTION (PUT /api/v1/buyer/property-interactions/{propertyId})
  // ============================================================

  Future<BuyerPropertyInteraction> setInteraction(String propertyId, int status) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/property-interactions/$propertyId';
      final payload = {'status': status};

      debugPrint('PUT BUYER INTERACTION: ${_dio.options.baseUrl}$url, payload: $payload');

      Response response = await _dio.put(
        url,
        data: payload,
        options: Options(headers: headers),
      );

      if (response.statusCode == 405 || response.statusCode == 404) {
        debugPrint('PUT failed with ${response.statusCode}, trying POST /api/v1/buyer/property-interactions/$propertyId');
        response = await _dio.post(
          url,
          data: payload,
          options: Options(headers: headers),
        );
      }

      debugPrint('SET INTERACTION STATUS: ${response.statusCode}, DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          return BuyerPropertyInteraction.fromJson(Map<String, dynamic>.from(response.data as Map));
        }
        return BuyerPropertyInteraction(
          propertyId: propertyId,
          currentStatus: status,
          currentStatusName: BuyerPropertyInteraction.resolveStatusName(status),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to update property interaction (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to update interaction: ${e.message}',
        ),
      );
    }
  }

  void dispose() {
    _dio.close();
  }
}
