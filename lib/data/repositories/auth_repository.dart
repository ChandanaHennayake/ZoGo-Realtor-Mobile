import 'package:zogo_realtor/data/models/auth/register_request.dart';
import 'package:zogo_realtor/data/models/auth/register_response.dart';

import '../models/auth/google_login_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _authApiService;

  AuthRepository(this._authApiService);

  Future<LoginResponse> login(
    LoginRequest request,
  ) {
    return _authApiService.login(request);
  }

  Future<LoginResponse> googleLogin(
    GoogleLoginRequest request,
  ) {
    return _authApiService.googleLogin(request);
  }


    Future<RegisterResponse> register(
    RegisterRequest request,
  ) {
    return _authApiService.register(request);
  }
}