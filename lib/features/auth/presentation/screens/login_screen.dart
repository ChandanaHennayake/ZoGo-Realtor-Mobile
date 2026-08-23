import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/auth_api_service.dart';
import '../../../../data/services/google_auth_service.dart';
import '../viewmodels/login_view_model.dart';

// Keep your existing HomeScreen import if the path is different.
import '../../../home/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final ApiClient _apiClient;
  late final LoginViewModel _loginViewModel;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // API
    // ------------------------------------------------------------

    _apiClient = ApiClient();

    final authApiService = AuthApiService(
      _apiClient,
    );

    // ------------------------------------------------------------
    // Repository
    // ------------------------------------------------------------

    final authRepository = AuthRepository(
      authApiService,
    );

    // ------------------------------------------------------------
    // Secure Storage
    // ------------------------------------------------------------

    final secureStorage = SecureStorageService();

    // ------------------------------------------------------------
    // Google Authentication
    // ------------------------------------------------------------

    final googleAuthService = GoogleAuthService();

    // ------------------------------------------------------------
    // ViewModel
    // ------------------------------------------------------------

    _loginViewModel = LoginViewModel(
      authRepository,
      secureStorage,
      googleAuthService,
    );

    _loginViewModel.addListener(
      _onLoginStateChanged,
    );
  }

  void _onLoginStateChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _loginViewModel.removeListener(
      _onLoginStateChanged,
    );

    _emailController.dispose();
    _passwordController.dispose();

    _loginViewModel.dispose();

    _apiClient.dispose();

    super.dispose();
  }

  // ============================================================
  // EMAIL / PASSWORD LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await _loginViewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );

      return;
    }

    _showError(
      _loginViewModel.errorMessage ??
          'Login failed. Please try again.',
    );
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> _googleLogin() async {
    FocusScope.of(context).unfocus();

    final success = await _loginViewModel.googleLogin();

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );

      return;
    }

    _showError(
      _loginViewModel.errorMessage ??
          'Google login failed. Please try again.',
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  void _forgotPassword() {
    // We will connect this to the API later.
    _showError(
      'Forgot password will be available soon.',
    );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  void _goToRegister() {
    Navigator.of(context).pushNamed(
      '/register',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loginViewModel.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 30),

                // --------------------------------------------------
                // Logo / Header
                // --------------------------------------------------

                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/zogo_app_icon.png',
                        width: 90,
                        height: 90,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to continue to ZoGo Realtor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --------------------------------------------------
                // Email
                // --------------------------------------------------

                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,

                  decoration: InputDecoration(
                    hintText: 'Enter your email',

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0E0E0),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00AFC1),
                        width: 2,
                      ),
                    ),

                    filled: true,

                    fillColor: const Color(0xFFF8FAFA),
                  ),

                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Please enter your email';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(email)) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------
                // Password
                // --------------------------------------------------

                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  textInputAction: TextInputAction.done,

                  enabled: !isLoading,

                  onFieldSubmitted: (_) {
                    if (!isLoading) {
                      _login();
                    }
                  },

                  decoration: InputDecoration(
                    hintText: 'Enter your password',

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },

                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0E0E0),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00AFC1),
                        width: 2,
                      ),
                    ),

                    filled: true,

                    fillColor: const Color(0xFFF8FAFA),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // Forgot Password
                // --------------------------------------------------

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : _forgotPassword,

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF00AFC1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // Login Button
                // --------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : _login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF00AFC1),

                      foregroundColor: Colors.white,

                      disabledBackgroundColor:
                          const Color(0xFF9DDDE2),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      elevation: 0,
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,

                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign In',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // Divider
                // --------------------------------------------------

                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Color(0xFFE5E5E5),
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),

                      child: Text(
                        'OR',

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Divider(
                        color: Color(0xFFE5E5E5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --------------------------------------------------
                // Google Login
                // --------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : _googleLogin,

                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                      ),

                      backgroundColor: Colors.white,
                    ),

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Icon(
                          Icons.g_mobiledata,
                          size: 28,
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'Continue with Google',

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --------------------------------------------------
                // Register
                // --------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Text(
                      "Don't have an account?",

                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),

                    TextButton(
                      onPressed:
                          isLoading
                              ? null
                              : _goToRegister,

                      child: const Text(
                        'Create Account',

                        style: TextStyle(
                          color: Color(0xFF00AFC1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}