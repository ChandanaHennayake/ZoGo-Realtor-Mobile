import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/auth_api_service.dart';
import '../viewmodels/register_view_model.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color accentPink = Color(0xFFFF2D7A);

  void _openRegister(BuildContext context) {
    final apiClient = ApiClient();

    final authApiService = AuthApiService(
      apiClient,
    );

    final authRepository = AuthRepository(
      authApiService,
    );

    final secureStorage = SecureStorageService();

    final registerViewModel = RegisterViewModel(
      authRepository,
      secureStorage,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          viewModel: registerViewModel,
        ),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              const Spacer(),

              // ZoGo Logo
              Image.asset(
                'assets/images/zogo_logo.png',
                width: 180,
              ),

              const SizedBox(height: 35),

              // Heading
              const Text(
                'Find your perfect place',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                'Discover properties, connect with trusted agents, '
                'and find a place you can call home.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF687386),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Get Started → Register
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _openRegister(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Already have an account → Login
              TextButton(
                onPressed: () {
                  _openLogin(context);
                },
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                    color: accentPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}