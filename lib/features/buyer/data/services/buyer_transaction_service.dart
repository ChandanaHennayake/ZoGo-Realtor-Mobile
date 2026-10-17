import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/property_transaction_model.dart';

class BuyerTransactionService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerTransactionService([Dio? dio, SecureStorageService? secureStorage])
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

  Future<PropertyTransactionModel?> getPropertyTransaction(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.transactions}/property/$propertyId';
      final response = await _dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') && resData['data'] != null
            ? resData['data']
            : resData;
        return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      if (response.statusCode == 404) {
        return null;
      }

      return null;
    } on DioException catch (dioErr) {
      debugPrint('DioException loading property transaction: $dioErr');
      return null;
    }
  }

  Future<PropertyTransactionModel?> getTransactionDetails(String transactionId) async {
    try {
      final headers = await _authHeaders();
      final url = '${ApiConstants.transactions}/$transactionId';
      final response = await _dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final resData = response.data;
        final data = resData is Map && resData.containsKey('data') && resData['data'] != null
            ? resData['data']
            : resData;
        return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
      }

      return null;
    } on DioException catch (dioErr) {
      debugPrint('DioException loading transaction details: $dioErr');
      return null;
    }
  }
}
