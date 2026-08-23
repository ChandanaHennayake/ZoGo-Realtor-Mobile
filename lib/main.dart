
import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/auth/presentation/screens/splash_screen.dart';


void main() {
  runApp(const ZoGoApp());
}

class ZoGoApp extends StatelessWidget {
  const ZoGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZoGo Realtor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C6D4),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}