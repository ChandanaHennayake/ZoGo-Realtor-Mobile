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

  // ============================================================
  // INITIATE TRANSACTION (POST /api/v1/transactions)
  // ============================================================
  Future<PropertyTransactionModel> initiateTransaction({
    required String propertyId,
    String? offerId,
    required String buyerId,
    String? agentId,
    required double agreedPrice,
    double commissionRate = 0.03,
    String? notes,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'propertyId': propertyId,
      if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
      'buyerId': buyerId,
      if (agentId != null && agentId.isNotEmpty) 'agentId': agentId,
      'agreedPrice': agreedPrice,
      'commissionRate': commissionRate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.post(
      ApiConstants.transactions,
      data: body,
      options: Options(headers: headers),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resData = response.data;
      final data = resData is Map && resData.containsKey('data') && resData['data'] != null
          ? resData['data']
          : resData;
      return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('Failed to initiate transaction: ${response.statusCode}');
  }

  // ============================================================
  // VERIFY TITLE DEED (PUT /api/v1/transactions/{id}/verify-title)
  // ============================================================
  Future<PropertyTransactionModel> verifyTitle(
    String transactionId, {
    required String titleDeedReference,
    required String notaryName,
    String? notes,
  }) async {
    final headers = await _authHeaders();
    final url = '${ApiConstants.transactions}/$transactionId/verify-title';
    final body = {
      'titleDeedReference': titleDeedReference,
      'notaryName': notaryName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.put(url, data: body, options: Options(headers: headers));

    if (response.statusCode == 200) {
      final resData = response.data;
      final data = resData is Map && resData.containsKey('data') && resData['data'] != null
          ? resData['data']
          : resData;
      return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('Failed to verify title: ${response.statusCode}');
  }

  // ============================================================
  // SIGN DEED OF TRANSFER (PUT /api/v1/transactions/{id}/sign-deed)
  // ============================================================
  Future<PropertyTransactionModel> signDeed(
    String transactionId, {
    String? notes,
  }) async {
    final headers = await _authHeaders();
    final url = '${ApiConstants.transactions}/$transactionId/sign-deed';
    final body = {
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.put(url, data: body, options: Options(headers: headers));

    if (response.statusCode == 200) {
      final resData = response.data;
      final data = resData is Map && resData.containsKey('data') && resData['data'] != null
          ? resData['data']
          : resData;
      return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('Failed to sign deed: ${response.statusCode}');
  }

  // ============================================================
  // SETTLE TRANSACTION & MARK SOLD (PUT /api/v1/transactions/{id}/settle)
  // ============================================================
  Future<PropertyTransactionModel> settleTransaction(
    String transactionId, {
    String? closingNotes,
  }) async {
    final headers = await _authHeaders();
    final url = '${ApiConstants.transactions}/$transactionId/settle';
    final body = {
      if (closingNotes != null && closingNotes.isNotEmpty) 'closingNotes': closingNotes,
    };

    final response = await _dio.put(url, data: body, options: Options(headers: headers));

    if (response.statusCode == 200) {
      final resData = response.data;
      final data = resData is Map && resData.containsKey('data') && resData['data'] != null
          ? resData['data']
          : resData;
      return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('Failed to settle transaction: ${response.statusCode}');
  }

  // ============================================================
  // CANCEL TRANSACTION (PUT /api/v1/transactions/{id}/cancel)
  // ============================================================
  Future<PropertyTransactionModel> cancelTransaction(
    String transactionId, {
    required String reason,
  }) async {
    final headers = await _authHeaders();
    final url = '${ApiConstants.transactions}/$transactionId/cancel';
    final body = {'reason': reason};

    final response = await _dio.put(url, data: body, options: Options(headers: headers));

    if (response.statusCode == 200) {
      final resData = response.data;
      final data = resData is Map && resData.containsKey('data') && resData['data'] != null
          ? resData['data']
          : resData;
      return PropertyTransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
    }
    throw Exception('Failed to cancel transaction: ${response.statusCode}');
  }

  // ============================================================
  // GET ALL TRANSACTIONS (GET /api/v1/admin/transactions)
  // ============================================================
  Future<List<PropertyTransactionModel>> getAllTransactions({
    int? status,
    int pageNumber = 1,
    int pageSize = 50,
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
        ApiConstants.adminTransactions,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        final list = resData is Map && resData.containsKey('data') && resData['data'] is List
            ? resData['data'] as List
            : (resData is List ? resData : []);

        return list
            .map((item) => PropertyTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading all transactions: $e');
      return [];
    }
  }
}
