import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/auth/login_response.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _firstNameKey = 'user_first_name';
  static const _lastNameKey = 'user_last_name';
  static const _emailKey = 'user_email';
  static const _rolesKey = 'user_roles';
  static const _tokenExpiryKey = 'access_token_expires_at';

  final FlutterSecureStorage _storage;

  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );

    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<void> saveUserSession(LoginResponse response) async {
    await saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    await _storage.write(key: _userIdKey, value: response.userId);
    await _storage.write(key: _firstNameKey, value: response.firstName);
    await _storage.write(key: _lastNameKey, value: response.lastName);
    await _storage.write(key: _emailKey, value: response.email);
    await _storage.write(key: _rolesKey, value: jsonEncode(response.roles));
    await _storage.write(
      key: _tokenExpiryKey,
      value: response.accessTokenExpiresAt.toIso8601String(),
    );
  }

  Future<List<String>> getUserRoles() async {
    final rolesStr = await _storage.read(key: _rolesKey);
    if (rolesStr != null && rolesStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(rolesStr);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveUserRoles(List<String> roles) async {
    await _storage.write(key: _rolesKey, value: jsonEncode(roles));
  }

  Future<Map<String, String>> getUserProfile() async {
    final userId = await _storage.read(key: _userIdKey) ?? '';
    final firstName = await _storage.read(key: _firstNameKey) ?? '';
    final lastName = await _storage.read(key: _lastNameKey) ?? '';
    final email = await _storage.read(key: _emailKey) ?? '';
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr != null) {
      try {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          final refresh = await getRefreshToken();
          return refresh != null && refresh.isNotEmpty;
        }
      } catch (_) {}
    }
    return true;
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}