import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/models/auth/google_login_request.dart';
import '../../../../data/models/auth/login_request.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/google_auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  final GoogleAuthService _googleAuthService;

  LoginViewModel(
    this._authRepository,
    this._secureStorage,
    this._googleAuthService,
  );

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> googleLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken =
          await _googleAuthService.signInAndGetIdToken();

      if (idToken == null || idToken.isEmpty) {
        _errorMessage = 'Google sign-in was cancelled.';
        return false;
      }

      final response = await _authRepository.googleLogin(
        GoogleLoginRequest(
          idToken: idToken,
        ),
      );

      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}