import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth/google_login_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<LoginResponse> login(
    LoginRequest request,
  ) async {
    final json = await _apiClient.post(
      ApiConstants.login,
      body: request.toJson(),
    );

    return LoginResponse.fromJson(json);
  }

  Future<LoginResponse> googleLogin(
    GoogleLoginRequest request,
  ) async {
    final json = await _apiClient.post(
      ApiConstants.googleLogin,
      body: request.toJson(),
    );

    return LoginResponse.fromJson(json);
  }
}