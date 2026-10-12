import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/buyer_property_details.dart';
import '../../models/buyer_property_list_item.dart';

class BuyerPropertyService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  BuyerPropertyService([Dio? dio, SecureStorageService? secureStorage])
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
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final msgs = <String>[];
        for (final val in errors.values) {
          if (val is List) {
            msgs.addAll(val.map((e) => e.toString()));
          } else if (val != null) {
            msgs.add(val.toString());
          }
        }
        if (msgs.isNotEmpty) return msgs.join(', ');
      }
    }
    return fallback;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secureStorage.getAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET BUYER PROPERTIES (GET /api/v1/buyer/properties)
  // ============================================================

  Future<List<BuyerPropertyListItem>> getBuyerProperties({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchQuery,
    int? propertyTypeId,
    int? listingTypeId,
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        'propertyTypeId': ?propertyTypeId,
        'listingTypeId': ?listingTypeId,
      };

      const url = '/api/v1/buyer/properties';
      debugPrint('GET BUYER PROPERTIES: ${_dio.options.baseUrl}$url?pageNumber=$pageNumber&pageSize=$pageSize');

      Response response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      // Fallback: If buyer endpoint returns 404, try general properties
      if (response.statusCode == 404) {
        debugPrint('Falling back to /api/v1/properties for buyer browse');
        response = await _dio.get(
          '/api/v1/properties',
          queryParameters: queryParams,
          options: Options(headers: headers),
        );
      }

      if (response.statusCode == 200 && response.data != null) {
        dynamic listData = response.data;

        // Unpack ApiResponse wrapping
        if (listData is Map) {
          if (listData['data'] is List) {
            listData = listData['data'];
          } else if (listData['data'] is Map && listData['data']['items'] is List) {
            listData = listData['data']['items'];
          } else if (listData['items'] is List) {
            listData = listData['items'];
          }
        }

        if (listData is List) {
          final items = <BuyerPropertyListItem>[];
          for (final raw in listData) {
            if (raw is Map) {
              final item = BuyerPropertyListItem.fromJson(Map<String, dynamic>.from(raw));
              // Only properties with Status == 2 (Published) are returned
              if (item.status == 2 || item.status == 0) {
                items.add(item);
              }
            }
          }
          return items;
        }

        return [];
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load properties (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      debugPrint('GET BUYER PROPERTIES DIO ERROR: ${e.message}');
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load properties: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('GET BUYER PROPERTIES ERROR: $e');
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // GET PROPERTY DETAILS (GET /api/v1/buyer/properties/{propertyId})
  // ============================================================

  Future<BuyerPropertyDetails> getBuyerPropertyDetails(String propertyId) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/properties/$propertyId';
      debugPrint('GET BUYER PROPERTY DETAILS: ${_dio.options.baseUrl}$url');

      Response response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      // Fallback: If 404 on buyer route, try /api/v1/properties/{id}
      if (response.statusCode == 404) {
        debugPrint('Falling back to /api/v1/properties/$propertyId');
        response = await _dio.get(
          '/api/v1/properties/$propertyId',
          options: Options(headers: headers),
        );
      }

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> rawMap;
        if (response.data is Map<String, dynamic>) {
          rawMap = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          rawMap = Map<String, dynamic>.from(response.data as Map);
        } else {
          throw Exception('Invalid property details response format');
        }

        // Fetch media, features, amenities in parallel to ensure complete property view
        final subResults = await Future.wait([
          _dio.get('/api/v1/properties/$propertyId/media', options: Options(headers: headers)).catchError((_) => Response(requestOptions: RequestOptions(), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/features', options: Options(headers: headers)).catchError((_) => Response(requestOptions: RequestOptions(), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/amenities', options: Options(headers: headers)).catchError((_) => Response(requestOptions: RequestOptions(), statusCode: 404)),
        ]);

        List<Map<String, dynamic>> mediaList = [];
        if (subResults[0].statusCode == 200 && subResults[0].data is List) {
          mediaList = (subResults[0].data as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        List<Map<String, dynamic>> featuresList = [];
        if (subResults[1].statusCode == 200 && subResults[1].data is List) {
          featuresList = (subResults[1].data as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        List<Map<String, dynamic>> amenitiesList = [];
        if (subResults[2].statusCode == 200 && subResults[2].data is List) {
          amenitiesList = (subResults[2].data as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        return BuyerPropertyDetails.fromJson(
          rawMap,
          extraMedia: mediaList.isNotEmpty ? mediaList : null,
          extraFeatures: featuresList.isNotEmpty ? featuresList : null,
          extraAmenities: amenitiesList.isNotEmpty ? amenitiesList : null,
        );
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load property details (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load property details: ${e.message}',
        ),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void dispose() {
    _dio.close();
  }
}
