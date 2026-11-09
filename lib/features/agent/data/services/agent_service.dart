import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../models/agent_dashboard_model.dart';
import '../../models/agent_property_model.dart';
import '../../models/agent_territory_property_model.dart';
import '../../../buyer/models/property_visit_model.dart';

class AgentService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  AgentService([Dio? dio, SecureStorageService? secureStorage])
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
  // DASHBOARD
  // ============================================================
  Future<AgentDashboardModel> getDashboard() async {
    try {
      final headers = await _authHeaders();
      debugPrint('GET AGENT DASHBOARD: ${_dio.options.baseUrl}${ApiConstants.agentDashboard}');

      final response = await _dio.get(
        ApiConstants.agentDashboard,
        options: Options(headers: headers),
      );

      debugPrint('AGENT DASHBOARD STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null && data['data'] is Map) {
          return AgentDashboardModel.fromJson(Map<String, dynamic>.from(data['data'] as Map));
        } else if (data is Map<String, dynamic>) {
          return AgentDashboardModel.fromJson(data);
        }
      }
      return AgentDashboardModel.empty();
    } catch (e) {
      debugPrint('GET AGENT DASHBOARD ERROR: $e');
      return AgentDashboardModel.empty();
    }
  }

  // ============================================================
  // INTERESTED PROPERTIES
  // ============================================================
  Future<List<AgentPropertyItem>> getInterestedProperties() async {
    try {
      final headers = await _authHeaders();
      debugPrint('GET AGENT INTERESTED: ${_dio.options.baseUrl}${ApiConstants.agentInterestedProperties}');

      final response = await _dio.get(
        ApiConstants.agentInterestedProperties,
        options: Options(headers: headers),
      );

      debugPrint('AGENT INTERESTED STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        }

        return items
            .map((e) => AgentPropertyItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET AGENT INTERESTED ERROR: $e');
      return [];
    }
  }

  // ============================================================
  // PENDING VISITS
  // ============================================================
  Future<List<AgentPropertyItem>> getPendingVisits() async {
    try {
      final headers = await _authHeaders();
      debugPrint('GET AGENT VISITS: ${_dio.options.baseUrl}${ApiConstants.agentPendingVisits}');

      final response = await _dio.get(
        ApiConstants.agentPendingVisits,
        options: Options(headers: headers),
      );

      debugPrint('AGENT VISITS STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        }

        return items
            .map((e) => AgentPropertyItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET AGENT VISITS ERROR: $e');
      return [];
    }
  }

  // ============================================================
  // PENDING DOCUMENTS
  // ============================================================
  Future<List<AgentPropertyItem>> getPendingDocuments() async {
    try {
      final headers = await _authHeaders();
      debugPrint('GET AGENT DOCUMENTS: ${_dio.options.baseUrl}${ApiConstants.agentPendingDocuments}');

      final response = await _dio.get(
        ApiConstants.agentPendingDocuments,
        options: Options(headers: headers),
      );

      debugPrint('AGENT DOCUMENTS STATUS: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        }

        return items
            .map((e) => AgentPropertyItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET AGENT DOCUMENTS ERROR: $e');
      return [];
    }
  }

  // ============================================================
  // MARK VISITED (PUT /api/v1/agent/properties/{propertyId}/visit)
  // ============================================================
  Future<bool> markVisited(String propertyId, {String? buyerId}) async {
    try {
      final headers = await _authHeaders();
      final url = ApiConstants.agentMarkVisited(propertyId);
      final body = buyerId != null ? {'buyerId': buyerId} : null;

      debugPrint('PUT MARK VISITED: ${_dio.options.baseUrl}$url, payload: $body');

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      debugPrint('MARK VISITED STATUS: ${response.statusCode}, DATA: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('MARK VISITED ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // MARK AS SOLD
  // ============================================================
  Future<bool> markSold(String propertyId, {String? buyerId}) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/property-interactions/$propertyId/sold';
      final body = buyerId != null ? {'buyerId': buyerId} : null;

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('MARK SOLD ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // REJECT INQUIRY
  // ============================================================
  Future<bool> rejectInquiry(String propertyId, {String? buyerId, required String reason}) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/buyer/property-interactions/$propertyId/reject';
      final body = {'buyerId': buyerId, 'reason': reason};

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('REJECT INQUIRY ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // CONFIRM / APPROVE VISIT
  // ============================================================
  Future<bool> confirmVisit(String visitId, {String? notes}) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/visits/$visitId/confirm';
      final body = {'notes': notes};

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('CONFIRM VISIT ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // COMPLETE VISIT
  // ============================================================
  Future<bool> completeVisit(String visitId, {String? notes}) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/visits/$visitId/complete';
      final body = {if (notes != null && notes.isNotEmpty) 'notes': notes};

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('COMPLETE VISIT ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // REJECT VISIT
  // ============================================================
  Future<bool> rejectVisit(String visitId, {required String reason}) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/visits/$visitId/reject';
      final body = {'reason': reason};

      final response = await _dio.put(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('REJECT VISIT ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE DOCUMENT STATUS (VERIFY / REJECT)
  // ============================================================
  Future<bool> updateDocumentStatus(
    String propertyId,
    String documentId,
    int status, {
    String? rejectionReason,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = '/api/v1/properties/$propertyId/documents/$documentId/status';
      final body = {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      };

      final response = await _dio.patch(
        url,
        data: body,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('UPDATE DOCUMENT STATUS ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // TERRITORY PROPERTIES
  // ============================================================
  Future<List<AgentTerritoryPropertyItem>> getTerritoryProperties({
    int? districtId,
    int? propertyTypeId,
    int? listingTypeId,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      if (districtId != null && districtId > 0) queryParams['districtId'] = districtId;
      if (propertyTypeId != null && propertyTypeId > 0) queryParams['propertyTypeId'] = propertyTypeId;
      if (listingTypeId != null && listingTypeId > 0) queryParams['listingTypeId'] = listingTypeId;
      if (minPrice != null && minPrice > 0) queryParams['minPrice'] = minPrice;
      if (maxPrice != null && maxPrice > 0) queryParams['maxPrice'] = maxPrice;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['searchQuery'] = searchQuery.trim();
      }

      final response = await _dio.get(
        ApiConstants.agentTerritoryProperties,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map && data['data'] != null) {
          final inner = data['data'];
          if (inner is Map && inner['items'] is List) {
            items = inner['items'] as List;
          } else if (inner is List) {
            items = inner;
          }
        } else if (data is List) {
          items = data;
        }

        return items
            .map((e) => AgentTerritoryPropertyItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET TERRITORY PROPERTIES ERROR: $e');
      return [];
    }
  }

  // ============================================================
  // AGENT VISITS (CALENDAR)
  // ============================================================
  Future<List<PropertyVisitModel>> getAgentVisits() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        ApiConstants.agentVisits,
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
            .map((e) => PropertyVisitModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET AGENT VISITS ERROR: $e');
      return [];
    }
  }

  void dispose() {
    _dio.close();
  }
}
