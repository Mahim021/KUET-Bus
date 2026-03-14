import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../auth/login_screen.dart';
import '../main/main_shell.dart';
import 'widgets/loading_dots.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              user == null ? const LoginScreen() : const MainShell(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Center content: icon + title + subtitle
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bus icon
                    const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.white,
                      size: 90,
                    ),
                    const SizedBox(height: 28),
                    // App name
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'KUET ',
                            style: AppTextStyles.splashTitle,
                          ),
                          TextSpan(
                            text: 'Bus',
                            style: AppTextStyles.splashTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tagline
                    const Text(
                      'REACH AND RIDE',
                      style: AppTextStyles.splashSubtitle,
                    ),
                  ],
                ),
              ),
            ),
            // Bottom loading dots
            const Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: LoadingDots(),
            ),
          ],
        ),
      ),
    );
  }
}
