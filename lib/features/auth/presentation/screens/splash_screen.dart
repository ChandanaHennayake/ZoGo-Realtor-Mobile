import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zogo_realtor/core/constants/api_constants.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/auth/presentation/screens/get_started_screen.dart';
import 'package:zogo_realtor/features/home/presentation/screens/home_screen.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final isLoggedIn = await _secureStorage.isLoggedIn();
      if (isLoggedIn && mounted) {
        final roles = await _secureStorage.getUserRoles();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              roles: roles,
              onActivateSeller: _activateSeller,
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // In case of storage reading error, fallback to GetStarted
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const GetStartedScreen(),
      ),
    );
  }

  Future<bool> _activateSeller() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    try {
      final sellerService = SellerService(
        dio,
        _secureStorage,
      );

      final success = await sellerService.activateSeller();
      if (success) {
        final currentRoles = await _secureStorage.getUserRoles();
        if (!currentRoles.contains('SEL')) {
          await _secureStorage.saveUserRoles([...currentRoles, 'SEL']);
        }
      }
      return success;
    } finally {
      dio.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full splash image
          Image.asset(
            'assets/images/splash_background.jpg',
            fit: BoxFit.cover,
          ),

          // Loading indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 45,
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF00C6D4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}