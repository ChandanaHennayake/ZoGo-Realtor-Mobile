import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/admin_property_model.dart';

class AdminPropertyService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  AdminPropertyService([Dio? dio, SecureStorageService? secureStorage])
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

  // ============================================================
  // GET PROPERTIES QUEUE
  // ============================================================
  Future<List<AdminPropertySummaryModel>> getProperties({
    int? status,
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        ApiConstants.adminProperties,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        }

        return items
            .map((e) => AdminPropertySummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET ADMIN PROPERTIES ERROR: $e');
      return [];
    }
  }

  // ============================================================
  // GET REVIEW DETAILS
  // ============================================================
  Future<AdminPropertyReviewDetailsModel?> getPropertyReviewDetails(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        ApiConstants.adminPropertyReview(propertyId),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          return AdminPropertyReviewDetailsModel.fromJson(
            Map<String, dynamic>.from(data['data'] as Map),
          );
        } else if (data is Map) {
          return AdminPropertyReviewDetailsModel.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('GET PROPERTY REVIEW DETAILS ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // START REVIEW
  // ============================================================
  Future<bool> startReview(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.put(
        ApiConstants.adminPropertyStartReview(propertyId),
        options: Options(headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('START REVIEW ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // APPROVE & PUBLISH
  // ============================================================
  Future<bool> approveProperty(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.put(
        ApiConstants.adminPropertyApprove(propertyId),
        options: Options(headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('APPROVE PROPERTY ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // REQUEST CHANGES
  // ============================================================
  Future<bool> requestChanges(
    String propertyId, {
    required String adminNotes,
    List<String>? requestedChanges,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'adminNotes': adminNotes,
        if (requestedChanges != null && requestedChanges.isNotEmpty)
          'requestedChanges': requestedChanges,
      };

      final response = await _dio.put(
        ApiConstants.adminPropertyRequestChanges(propertyId),
        data: body,
        options: Options(headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('REQUEST CHANGES ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // REJECT
  // ============================================================
  Future<bool> rejectProperty(String propertyId, {required String reason}) async {
    try {
      final headers = await _authHeaders();
      final body = {'rejectionReason': reason};

      final response = await _dio.put(
        ApiConstants.adminPropertyReject(propertyId),
        data: body,
        options: Options(headers: headers),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('REJECT PROPERTY ERROR: $e');
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}
