import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/cache/app_cache_service.dart';
import '../../../../core/network/connectivity_service.dart';
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'buyer_properties_p${pageNumber}_s${pageSize}_q${searchQuery ?? ""}_pt${propertyTypeId ?? ""}_lt${listingTypeId ?? ""}';
    if (!forceRefresh && pageNumber == 1) {
      final cached = AppCacheService.instance.get<List<BuyerPropertyListItem>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

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

          if (pageNumber == 1 && items.isNotEmpty) {
            AppCacheService.instance.put(cacheKey, items, ttl: const Duration(minutes: 5));
          }
          ConnectivityService.instance.notifyOnline();
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
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        ConnectivityService.instance.notifyOffline();
      }
      final cached = AppCacheService.instance.get<List<BuyerPropertyListItem>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('[BuyerPropertyService] Returning cached properties due to network error');
        return cached;
      }
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

  Future<BuyerPropertyDetails> getBuyerPropertyDetails(String propertyId, {bool forceRefresh = false}) async {
    final cacheKey = 'buyer_property_details_$propertyId';
    if (!forceRefresh) {
      final cached = AppCacheService.instance.get<BuyerPropertyDetails>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

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
          final d = response.data as Map<String, dynamic>;
          rawMap = d['data'] is Map ? Map<String, dynamic>.from(d['data'] as Map) : d;
        } else {
          rawMap = Map<String, dynamic>.from(response.data as Map);
        }

        // Fetch parallel details: Media, Features, Amenities, ApartmentDetails, Financials, Legal
        final subResults = await Future.wait([
          _dio.get('/api/v1/properties/$propertyId/media', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/features', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/amenities', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/apartment-details', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/financials', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
          _dio.get('/api/v1/properties/$propertyId/legal-details', options: Options(headers: headers)).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404)),
        ]);

        List<Map<String, dynamic>> mediaList = [];
        if (subResults[0].statusCode == 200 && subResults[0].data != null) {
          final d = subResults[0].data;
          final list = d is Map && d['data'] is List ? d['data'] as List : (d is List ? d : []);
          mediaList = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }

        List<Map<String, dynamic>> featuresList = [];
        if (subResults[1].statusCode == 200 && subResults[1].data != null) {
          final d = subResults[1].data;
          final list = d is Map && d['data'] is List ? d['data'] as List : (d is List ? d : []);
          featuresList = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }

        List<Map<String, dynamic>> amenitiesList = [];
        if (subResults[2].statusCode == 200 && subResults[2].data != null) {
          final d = subResults[2].data;
          final list = d is Map && d['data'] is List ? d['data'] as List : (d is List ? d : []);
          amenitiesList = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }

        Map<String, dynamic>? apartmentDetails;
        if (subResults[3].statusCode == 200 && subResults[3].data != null) {
          final d = subResults[3].data;
          if (d is Map<String, dynamic>) {
            apartmentDetails = d['data'] is Map ? Map<String, dynamic>.from(d['data']) : d;
          } else if (d is Map) {
            apartmentDetails = Map<String, dynamic>.from(d);
          }
        }

        Map<String, dynamic>? financials;
        if (subResults[4].statusCode == 200 && subResults[4].data != null) {
          final d = subResults[4].data;
          if (d is Map<String, dynamic>) {
            financials = d['data'] is Map ? Map<String, dynamic>.from(d['data']) : d;
          } else if (d is Map) {
            financials = Map<String, dynamic>.from(d);
          }
        }

        Map<String, dynamic>? legalDetails;
        if (subResults[5].statusCode == 200 && subResults[5].data != null) {
          final d = subResults[5].data;
          if (d is Map<String, dynamic>) {
            legalDetails = d['data'] is Map ? Map<String, dynamic>.from(d['data']) : d;
          } else if (d is Map) {
            legalDetails = Map<String, dynamic>.from(d);
          }
        }

        final result = BuyerPropertyDetails.fromJson(
          rawMap,
          extraMedia: mediaList.isNotEmpty ? mediaList : null,
          extraFeatures: featuresList.isNotEmpty ? featuresList : null,
          extraAmenities: amenitiesList.isNotEmpty ? amenitiesList : null,
          extraApartmentDetails: apartmentDetails,
          extraFinancials: financials,
          extraLegalDetails: legalDetails,
        );

        AppCacheService.instance.put(cacheKey, result, ttl: AppCacheService.detailsTtl);
        ConnectivityService.instance.notifyOnline();
        return result;
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load property details (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        ConnectivityService.instance.notifyOffline();
      }
      final cached = AppCacheService.instance.get<BuyerPropertyDetails>(cacheKey);
      if (cached != null) {
        return cached;
      }
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

  // ============================================================
  // MASTER DATA ENDPOINTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPropertyTypes() async {
    const cacheKey = 'master_property_types';
    final cached = AppCacheService.instance.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final headers = await _authHeaders();
      final res = await _dio.get('/api/v1/common/property-types', options: Options(headers: headers));
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is Map && res.data['data'] is List
            ? res.data['data'] as List
            : (res.data is List ? res.data as List : []);
        final result = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        if (result.isNotEmpty) {
          AppCacheService.instance.put(cacheKey, result, ttl: AppCacheService.masterDataTtl);
          ConnectivityService.instance.notifyOnline();
        }
        return result;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getListingTypes() async {
    const cacheKey = 'master_listing_types';
    final cached = AppCacheService.instance.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final headers = await _authHeaders();
      final res = await _dio.get('/api/v1/common/listing-types', options: Options(headers: headers));
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is Map && res.data['data'] is List
            ? res.data['data'] as List
            : (res.data is List ? res.data as List : []);
        final result = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        if (result.isNotEmpty) {
          AppCacheService.instance.put(cacheKey, result, ttl: AppCacheService.masterDataTtl);
          ConnectivityService.instance.notifyOnline();
        }
        return result;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPropertyAgent(String propertyId) async {
    final cacheKey = 'property_agent_$propertyId';
    final cached = AppCacheService.instance.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/properties/$propertyId/agent';
      final res = await _dio.get(url, options: Options(headers: headers));
      if (res.statusCode == 200 && res.data != null) {
        if (res.data is Map && res.data['data'] is Map) {
          final result = Map<String, dynamic>.from(res.data['data'] as Map);
          AppCacheService.instance.put(cacheKey, result, ttl: const Duration(minutes: 15));
          ConnectivityService.instance.notifyOnline();
          return result;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }
}
