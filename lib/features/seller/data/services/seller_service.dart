import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zogo_realtor/core/constants/api_constants.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';

class SellerService {
  SellerService([Dio? dio, SecureStorageService? secureStorage])
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

  final Dio _dio;
  final SecureStorageService _secureStorage;

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

  // ============================================================
  // SELLER ACTIVATION
  // ============================================================

  Future<bool> activateSeller() async {
    debugPrint('========== SELLER ACTIVATION START ==========');

    try {
      final accessToken = await _secureStorage.getAccessToken();

      debugPrint('TOKEN EXISTS: ${accessToken != null}');
      debugPrint('TOKEN LENGTH: ${accessToken?.length ?? 0}');
      debugPrint('BASE URL: ${_dio.options.baseUrl}');

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('ERROR: NO ACCESS TOKEN');
        throw Exception('Authentication token not found.');
      }

      const url = '/api/v1/seller/activate';

      debugPrint('CALLING: ${_dio.options.baseUrl}$url');

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE: ${response.data}');
      debugPrint('========== SELLER ACTIVATION SUCCESS ==========');

      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('========== SELLER ACTIVATION ERROR ==========');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');
      debugPrint('==============================================');

      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Seller activation failed',
        ),
      );
    } catch (e) {
      debugPrint('SELLER UNKNOWN ERROR: $e');
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // CREATE PROPERTY (POST /api/v1/properties)
  // ============================================================

  Future<Map<String, dynamic>> createProperty(
    Map<String, dynamic> propertyData,
  ) async {
    debugPrint('========== CREATE PROPERTY START ==========');

    try {
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      const url = '/api/v1/properties';
      debugPrint('POST URL: ${_dio.options.baseUrl}$url');
      debugPrint('PAYLOAD: $propertyData');

      final response = await _dio.post(
        url,
        data: propertyData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('CREATE PROPERTY STATUS: ${response.statusCode}');
      debugPrint('CREATE PROPERTY RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to create property (${response.statusCode})',
        ),
      );
    } on DioException catch (e) {
      debugPrint('CREATE PROPERTY DIO ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');

      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Network error: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('CREATE PROPERTY UNKNOWN ERROR: $e');
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // PROPERTY FEATURES (POST /api/v1/properties/{propertyId}/features)
  // ============================================================

  Future<Map<String, dynamic>> addPropertyFeature(
    String propertyId,
    int featureId,
  ) async {
    debugPrint('========== ADD PROPERTY FEATURE START ==========');
    debugPrint('Property ID: $propertyId, Feature ID: $featureId');

    try {
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/features';
      final payload = {'featureId': featureId};

      debugPrint('POST URL: ${_dio.options.baseUrl}$url');
      debugPrint('PAYLOAD: $payload');

      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('ADD FEATURE STATUS: ${response.statusCode}');
      debugPrint('ADD FEATURE RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to add feature ($featureId)',
        ),
      );
    } on DioException catch (e) {
      debugPrint('ADD FEATURE DIO ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');

      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to add feature: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('ADD FEATURE UNKNOWN ERROR: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> addPropertyFeatures(
    String propertyId,
    List<int> featureIds,
  ) async {
    for (final featureId in featureIds) {
      await addPropertyFeature(propertyId, featureId);
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyFeatures(
    String propertyId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/features';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load property features',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Network error: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // PROPERTY AMENITIES (POST /api/v1/properties/{propertyId}/amenities)
  // ============================================================

  Future<Map<String, dynamic>> addPropertyAmenity(
    String propertyId,
    int amenityId,
  ) async {
    debugPrint('========== ADD PROPERTY AMENITY START ==========');
    debugPrint('Property ID: $propertyId, Amenity ID: $amenityId');

    try {
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/amenities';
      final payload = {'amenityId': amenityId};

      debugPrint('POST URL: ${_dio.options.baseUrl}$url');
      debugPrint('PAYLOAD: $payload');

      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('ADD AMENITY STATUS: ${response.statusCode}');
      debugPrint('ADD AMENITY RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to add amenity ($amenityId)',
        ),
      );
    } on DioException catch (e) {
      debugPrint('ADD AMENITY DIO ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');

      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to add amenity: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('ADD AMENITY UNKNOWN ERROR: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> addPropertyAmenities(
    String propertyId,
    List<int> amenityIds,
  ) async {
    for (final amenityId in amenityIds) {
      await addPropertyAmenity(propertyId, amenityId);
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyAmenities(
    String propertyId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/amenities';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load property amenities',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Network error: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // PROPERTY FINANCIALS (POST & GET /api/v1/properties/{propertyId}/financials)
  // ============================================================

  Future<Map<String, dynamic>> savePropertyFinancials(
    String propertyId,
    Map<String, dynamic> financialsData,
  ) async {
    debugPrint('========== SAVE PROPERTY FINANCIALS START ==========');
    debugPrint('Property ID: $propertyId');
    debugPrint('PAYLOAD: $financialsData');

    try {
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/financials';

      final response = await _dio.post(
        url,
        data: financialsData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('SAVE FINANCIALS STATUS: ${response.statusCode}');
      debugPrint('SAVE FINANCIALS RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to save property financials',
        ),
      );
    } on DioException catch (e) {
      debugPrint('SAVE FINANCIALS DIO ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('DATA: ${e.response?.data}');

      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to save financials: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('SAVE FINANCIALS UNKNOWN ERROR: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getPropertyFinancials(
    String propertyId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/financials';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load property financials',
        ),
      );
    }
  }

  // ============================================================
  // PROPERTY LEGAL DETAILS (POST, PUT, GET /api/v1/properties/{propertyId}/legal-details)
  // ============================================================

  Future<Map<String, dynamic>> savePropertyLegalDetails(
    String propertyId,
    Map<String, dynamic> legalData,
  ) async {
    debugPrint('========== SAVE LEGAL DETAILS START ==========');
    debugPrint('Property ID: $propertyId, Payload: $legalData');

    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/legal-details';

      Response response;
      try {
        response = await _dio.post(
          url,
          data: legalData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
      } on DioException catch (dioErr) {
        final errorMsg = _parseErrorMessage(
          dioErr.response?.data,
          dioErr.response?.statusCode,
          '',
        ).toLowerCase();

        if (dioErr.response?.statusCode == 400 &&
                errorMsg.contains('already exist') ||
            dioErr.response?.statusCode == 409) {
          debugPrint('Legal details already exist, calling PUT to update');
          response = await _dio.put(
            url,
            data: legalData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );
        } else {
          rethrow;
        }
      }

      debugPrint('SAVE LEGAL STATUS: ${response.statusCode}');
      debugPrint('SAVE LEGAL RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to save property legal details',
        ),
      );
    } on DioException catch (e) {
      debugPrint('SAVE LEGAL DETAILS DIO ERROR: ${e.message}');
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to save legal details: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('SAVE LEGAL DETAILS ERROR: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getPropertyLegalDetails(
    String propertyId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/legal-details';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load property legal details',
        ),
      );
    }
  }

  // ============================================================
  // PROPERTY MEDIA (POST, GET, DELETE /api/v1/properties/{propertyId}/media)
  // ============================================================

  Future<Map<String, dynamic>> uploadPropertyMedia(
    String propertyId, {
    required String filePath,
    required int mediaType, // 1: Image, 2: Video
    required int displayOrder,
    required bool isCover,
    void Function(int, int)? onSendProgress,
  }) async {
    debugPrint('========== UPLOAD PROPERTY MEDIA START ==========');
    debugPrint('Property ID: $propertyId, Path: $filePath, MediaType: $mediaType');

    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      final formData = FormData.fromMap({
        'File': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'MediaType': mediaType,
        'DisplayOrder': displayOrder,
        'IsCover': isCover,
      });

      final url = '/api/v1/properties/$propertyId/media';

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('UPLOAD MEDIA STATUS: ${response.statusCode}');
      debugPrint('UPLOAD MEDIA RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'status': 'success'};
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to upload media',
        ),
      );
    } on DioException catch (e) {
      debugPrint('UPLOAD MEDIA DIO ERROR: ${e.message}');
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to upload media: ${e.message}',
        ),
      );
    } catch (e) {
      debugPrint('UPLOAD MEDIA ERROR: $e');
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyMedia(
    String propertyId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/media';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to load property media',
        ),
      );
    }
  }

  Future<void> deletePropertyMedia(
    String propertyId,
    String mediaId,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/media/$mediaId';
      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          _parseErrorMessage(
            response.data,
            response.statusCode,
            'Failed to delete media item',
          ),
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Network error: ${e.message}',
        ),
      );
    }
  }

  // ============================================================
  // PROPERTY GET BY ID, PUBLISH & UPDATE
  // ============================================================

  Future<Map<String, dynamic>> getPropertyById(String propertyId) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
      }

      throw Exception(
        _parseErrorMessage(
          response.data,
          response.statusCode,
          'Failed to load property details',
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
    }
  }

  Future<bool> publishProperty(String propertyId) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId/publish';
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to publish property: ${e.message}',
        ),
      );
    }
  }

  Future<bool> updateProperty(
    String propertyId,
    Map<String, dynamic> propertyData,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final url = '/api/v1/properties/$propertyId';
      final response = await _dio.put(
        url,
        data: propertyData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw Exception(
        _parseErrorMessage(
          e.response?.data,
          e.response?.statusCode,
          'Failed to update property: ${e.message}',
        ),
      );
    }
  }
}



