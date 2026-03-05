import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../main/main_shell.dart';
import 'widgets/auth_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool get _isEmailValid =>
      _emailController.text.trim().contains('@') &&
      _emailController.text.trim().isNotEmpty;

  bool get _isPasswordValid => _passwordController.text.length >= 6;

  bool get _canLogin => _isEmailValid && _isPasswordValid;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // clear cached account so picker always shows all accounts
      final account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back_ios,
                    size: 20, color: AppColors.bodyText),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: AppColors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text('KUET Bus', style: AppTextStyles.authAppTitle),
                    const SizedBox(height: 6),
                    Text('Your campus commute, simplified.',
                        style: AppTextStyles.authSubtitle),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text('Log In', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 24),
              AuthField(
                hint: 'Email Address',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _rebuild(),
              ),
              const SizedBox(height: 14),
              AuthField(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                controller: _passwordController,
                onChanged: (_) => _rebuild(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Forgot Password?', style: AppTextStyles.linkBold),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canLogin
                      ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MainShell()),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Log In',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR CONTINUE WITH',
                        style: AppTextStyles.dividerLabel),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text('Google',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bodyText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.bodySmall),
                        TextSpan(
                            text: 'Sign Up', style: AppTextStyles.linkBold),
                      ],
                    ),
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
