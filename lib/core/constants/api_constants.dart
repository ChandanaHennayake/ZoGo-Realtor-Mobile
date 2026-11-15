import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

class ApiConstants {
  static const String defaultBaseUrl = 'http://192.168.0.200:5000';
  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    try {
      final saved = await SecureStorageService().getServerUrl();
      if (saved != null && saved.trim().isNotEmpty) {
        _currentBaseUrl = saved.trim();
        debugPrint('ApiConstants: Active server URL -> $_currentBaseUrl');
      }
    } catch (e) {
      debugPrint('ApiConstants: Error loading server URL: $e');
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url.trim();
    try {
      await SecureStorageService().setServerUrl(_currentBaseUrl);
      debugPrint('ApiConstants: Updated server URL -> $_currentBaseUrl');
    } catch (e) {
      debugPrint('ApiConstants: Error saving server URL: $e');
    }
  }

  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String googleLogin = '/api/Auth/google';

  // Buyer endpoints
  static const String buyerProperties = '/api/v1/buyer/properties';
  static const String buyerFavorites = '/api/v1/buyer/favorites';
  static const String buyerInterests = '/api/v1/buyer/property-interests';
  static const String buyerInteractions = '/api/v1/buyer/property-interactions';
  static const String visits = '/api/v1/visits';
  static const String myVisits = '/api/v1/visits/my';
  static const String offers = '/api/v1/offers';
  static const String myOffers = '/api/v1/offers/my';
  static const String transactions = '/api/v1/transactions';
  static const String notifications = '/api/v1/notifications';
  static const String notificationsUnreadCount = '/api/v1/notifications/unread-count';
  static const String notificationsReadAll = '/api/v1/notifications/read-all';

  // Agent endpoints
  static const String agentDashboard = '/api/v1/agent/dashboard';
  static const String agentInterestedProperties = '/api/v1/agent/properties/interested';
  static const String agentPendingVisits = '/api/v1/agent/visits/pending';
  static const String agentPendingDocuments = '/api/v1/agent/documents/pending';
  static const String agentTerritoryProperties = '/api/v1/agent/territory/properties';
  static const String agentVisits = '/api/v1/visits/agent';
  static String agentMarkVisited(String propertyId) => '/api/v1/agent/properties/$propertyId/visit';
  static String agentMarkVisitRequested(String propertyId) => '/api/v1/agent/properties/$propertyId/visit-request';

  // Admin & Review endpoints
  static const String adminProperties = '/api/v1/admin/properties';
  static String adminPropertyReview(String id) => '/api/v1/admin/properties/$id';
  static String adminPropertyStartReview(String id) => '/api/v1/admin/properties/$id/start-review';
  static String adminPropertyApprove(String id) => '/api/v1/admin/properties/$id/approve';
  static String adminPropertyRequestChanges(String id) => '/api/v1/admin/properties/$id/request-changes';
  static String adminPropertyReject(String id) => '/api/v1/admin/properties/$id/reject';
  static const String adminTransactions = '/api/v1/admin/transactions';
  static const String adminCommissions = '/api/v1/admin/transactions/commissions';
}