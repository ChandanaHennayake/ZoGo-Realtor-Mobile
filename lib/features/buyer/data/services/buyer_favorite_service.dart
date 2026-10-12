import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/buyer_property_list_item.dart';
import '../../models/favorite_status.dart';

class BuyerFavoriteService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerFavoriteService([Dio? dio, SecureStorageService? secureStorage])
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
  // ADD FAVORITE (POST /api/v1/buyer/favorites/{propertyId})
  // ============================================================

  Future<bool> addFavorite(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/favorites/$propertyId';
      debugPrint('ADD FAVORITE: ${_dio.options.baseUrl}$url');

      final response = await _dio.post(
        url,
        options: Options(headers: headers),
      );

      debugPrint('ADD FAVORITE STATUS: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to add favorite (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to add favorite: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // REMOVE FAVORITE (DELETE /api/v1/buyer/favorites/{propertyId})
  // ============================================================

  Future<bool> removeFavorite(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/favorites/$propertyId';
      debugPrint('REMOVE FAVORITE: ${_dio.options.baseUrl}$url');

      final response = await _dio.delete(
        url,
        options: Options(headers: headers),
      );

      debugPrint('REMOVE FAVORITE STATUS: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to remove favorite (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to remove favorite: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // GET FAVORITES (GET /api/v1/buyer/favorites)
  // ============================================================

  Future<List<BuyerPropertyListItem>> getFavorites() async {
    try {
      final headers = await _authHeaders();
      const url = '/api/v1/buyer/favorites';
      debugPrint('GET FAVORITES: ${_dio.options.baseUrl}$url');

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic listData = response.data;

        if (listData is Map) {
          if (listData['data'] is List) {
            listData = listData['data'];
          } else if (listData['items'] is List) {
            listData = listData['items'];
          }
        }

        if (listData is List) {
          return listData
              .whereType<Map>()
              .map((raw) => BuyerPropertyListItem.fromJson(
                    Map<String, dynamic>.from(raw),
                  ).copyWith(isFavorite: true))
              .toList();
        }

        return [];
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load favorites',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load favorites: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // CHECK FAVORITE (GET /api/v1/buyer/favorites/{propertyId})
  // ============================================================

  Future<FavoriteStatus> checkFavorite(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/favorites/$propertyId';
      debugPrint('CHECK FAVORITE: ${_dio.options.baseUrl}$url');

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        return FavoriteStatus.fromJson(propertyId, response.data);
      }

      // If dedicated endpoint is 404, fallback to checking list
      if (response.statusCode == 404) {
        final allFavs = await getFavorites();
        final isFav = allFavs.any((f) => f.propertyId.toLowerCase() == propertyId.toLowerCase());
        return FavoriteStatus(propertyId: propertyId, isFavorite: isFav);
      }

      return FavoriteStatus(propertyId: propertyId, isFavorite: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final allFavs = await getFavorites();
          final isFav = allFavs.any((f) => f.propertyId.toLowerCase() == propertyId.toLowerCase());
          return FavoriteStatus(propertyId: propertyId, isFavorite: isFav);
        } catch (_) {
          return FavoriteStatus(propertyId: propertyId, isFavorite: false);
        }
      }
      return FavoriteStatus(propertyId: propertyId, isFavorite: false);
    } catch (_) {
      return FavoriteStatus(propertyId: propertyId, isFavorite: false);
    }
  }

  void dispose() {
    _dio.close();
  }
}
