import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/property_offer_model.dart';

class BuyerOfferService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerOfferService([Dio? dio, SecureStorageService? secureStorage])
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
  // SUBMIT OFFER (POST /api/v1/offers)
  // ============================================================

  Future<PropertyOfferModel> submitOffer({
    required String propertyId,
    required double offerAmount,
    String? buyerNotes,
    DateTime? expiresAt,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'propertyId': propertyId,
        'offerAmount': offerAmount,
        'buyerNotes': buyerNotes,
        'expiresAt': expiresAt?.toIso8601String(),
      };

      debugPrint('POST SUBMIT OFFER: ${ApiConstants.offers} with body: $body');
      final response = await _dio.post(
        ApiConstants.offers,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') && resData['data'] != null
            ? resData['data']
            : resData;
        return PropertyOfferModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to submit offer (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException submitting offer: $dioErr');
      throw Exception('Network error while submitting offer. Please check connection.');
    }
  }

  // ============================================================
  // GET MY OFFERS (GET /api/v1/offers/my)
  // ============================================================

  Future<List<PropertyOfferModel>> getMyOffers() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        ApiConstants.myOffers,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        final list = resData is Map && resData.containsKey('data') && resData['data'] is List
            ? resData['data'] as List
            : (resData is List ? resData : []);

        return list
            .map((item) => PropertyOfferModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to load offers (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException loading my offers: $dioErr');
      throw Exception('Network error while fetching offers.');
    }
  }

  // ============================================================
  // WITHDRAW OFFER (PUT /api/v1/offers/{offerId}/withdraw)
  // ============================================================

  Future<PropertyOfferModel> withdrawOffer(String offerId, {String? reason}) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.offers}/$offerId/withdraw';
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
        return PropertyOfferModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      final errorMsg = _parseErrorMessage(
        response.data,
        response.statusCode,
        'Failed to withdraw offer (HTTP ${response.statusCode})',
      );
      throw Exception(errorMsg);
    } on DioException catch (dioErr) {
      debugPrint('DioException withdrawing offer: $dioErr');
      throw Exception('Network error while withdrawing offer.');
    }
  }
}
