import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zogo_realtor/core/cache/app_cache_service.dart';
import 'package:zogo_realtor/core/network/api_exception.dart';
import 'package:zogo_realtor/core/network/connectivity_service.dart';
import 'package:zogo_realtor/core/widgets/connectivity_banner_wrapper.dart';
import 'package:zogo_realtor/data/models/auth/login_request.dart';
import 'package:zogo_realtor/data/models/auth/login_response.dart';
import 'package:zogo_realtor/data/repositories/auth_repository.dart';
import 'package:zogo_realtor/data/services/auth_api_service.dart';
import 'package:zogo_realtor/data/services/google_auth_service.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/auth/presentation/viewmodels/login_view_model.dart';

// Fake implementations for testing LoginViewModel
class FakeAuthApiService extends Fake implements AuthApiService {}
class FakeGoogleAuthService extends Fake implements GoogleAuthService {}
class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<void> saveUserSession(LoginResponse response) async {}
}

class FakeAuthRepositoryFails extends Fake implements AuthRepository {
  final String errorMessage;
  final int statusCode;

  FakeAuthRepositoryFails({required this.errorMessage, this.statusCode = 401});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    throw ApiException(
      statusCode: statusCode,
      message: errorMessage,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppCacheService Tests', () {
    late AppCacheService cache;

    setUp(() {
      cache = AppCacheService.instance;
      cache.clear();
    });

    test('put and get returns cached value', () {
      cache.put<String>('user_name', 'ZoGo User', ttl: const Duration(minutes: 5));
      expect(cache.contains('user_name'), isTrue);
      expect(cache.get<String>('user_name'), equals('ZoGo User'));
    });

    test('get returns null after expiry', () async {
      cache.put<String>('temp_key', 'temp_val', ttl: const Duration(milliseconds: 10));
      await Future.delayed(const Duration(milliseconds: 25));
      expect(cache.get<String>('temp_key'), isNull);
      expect(cache.contains('temp_key'), isFalse);
    });

    test('invalidate removes specific key', () {
      cache.put<int>('count', 42);
      expect(cache.get<int>('count'), 42);
      cache.invalidate('count');
      expect(cache.get<int>('count'), isNull);
    });

    test('invalidatePrefix removes matching keys', () {
      cache.put('prop_1', 'House');
      cache.put('prop_2', 'Villa');
      cache.put('user_1', 'John');

      cache.invalidatePrefix('prop_');
      expect(cache.get('prop_1'), isNull);
      expect(cache.get('prop_2'), isNull);
      expect(cache.get('user_1'), equals('John'));
    });
  });

  group('Connectivity & Banner Tests', () {
    testWidgets('Shows offline banner when offline, then restores banner when online', (tester) async {
      final connectivity = ConnectivityService.instance;
      connectivity.stopMonitoring(); // Stop background interval timer for test stability

      await tester.pumpWidget(
        MaterialApp(
          home: ConnectivityBannerWrapper(
            child: const Scaffold(body: Center(child: Text('Main Screen'))),
          ),
        ),
      );

      expect(find.text('Main Screen'), findsOneWidget);
      expect(find.byKey(const ValueKey('offline_banner')), findsNothing);

      // Simulate losing internet connection
      connectivity.notifyOffline();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('offline_banner')), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Simulate internet restored
      connectivity.notifyOnline();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('offline_banner')), findsNothing);
      expect(find.text('Internet Connection Restored'), findsOneWidget);

      // Advance clock so the restored banner auto-dismisses
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('LoginViewModel Exact Error Messaging Tests', () {
    test('Propagates exact password error message from ApiException', () async {
      const expectedMessage = 'Incorrect password. Please verify and try again.';
      final fakeRepo = FakeAuthRepositoryFails(errorMessage: expectedMessage);
      final vm = LoginViewModel(fakeRepo, FakeSecureStorageService(), FakeGoogleAuthService());

      final result = await vm.login(email: 'user@zogo.lk', password: 'wrong_password');

      expect(result, isFalse);
      expect(vm.errorMessage, equals(expectedMessage));

      // Test clearError
      vm.clearError();
      expect(vm.errorMessage, isNull);
    });

    test('Propagates exact no-account error message', () async {
      const expectedMessage = 'No account found with this email address. Please check your email or register.';
      final fakeRepo = FakeAuthRepositoryFails(errorMessage: expectedMessage);
      final vm = LoginViewModel(fakeRepo, FakeSecureStorageService(), FakeGoogleAuthService());

      final result = await vm.login(email: 'unknown@zogo.lk', password: 'any');

      expect(result, isFalse);
      expect(vm.errorMessage, equals(expectedMessage));
    });
  });
}
