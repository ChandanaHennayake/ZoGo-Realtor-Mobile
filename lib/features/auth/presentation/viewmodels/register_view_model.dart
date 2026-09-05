import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/models/auth/register_request.dart';
import '../../../../data/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  RegisterViewModel(
    this._authRepository,
    this._secureStorage,
  );

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response = await _authRepository.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          password: password,
        ),
      );

      // Registration API does not return access/refresh tokens.
      // Therefore we do NOT save tokens here.
      //
      // User will be redirected to LoginScreen after
      // successful registration.

      debugPrint(
        'Registered user: ${response.userId}',
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}