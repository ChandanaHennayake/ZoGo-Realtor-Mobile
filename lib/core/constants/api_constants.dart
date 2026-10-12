class ApiConstants {
  static const String baseUrl = 'http://172.20.10.5:5000';

  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String googleLogin = '/api/Auth/google';

  // Buyer endpoints
  static const String buyerProperties = '/api/v1/buyer/properties';
  static const String buyerFavorites = '/api/v1/buyer/favorites';
  static const String buyerInterests = '/api/v1/buyer/property-interests';
  static const String buyerInteractions = '/api/v1/buyer/property-interactions';

  // Agent endpoints
  static const String agentDashboard = '/api/v1/agent/dashboard';
  static const String agentInterestedProperties = '/api/v1/agent/properties/interested';
  static const String agentPendingVisits = '/api/v1/agent/visits/pending';
  static const String agentPendingDocuments = '/api/v1/agent/documents/pending';
  static String agentMarkVisited(String propertyId) =>
      '/api/v1/agent/properties/$propertyId/visit';
}