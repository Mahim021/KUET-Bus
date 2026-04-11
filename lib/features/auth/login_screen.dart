import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/user_session.dart';
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
  final _firestore = FirestoreService();
  bool _isSubmitting = false;

  bool get _isEmailValid =>
      _emailController.text.trim().contains('@') &&
      _emailController.text.trim().isNotEmpty;

  bool get _isPasswordValid => _passwordController.text.length >= 6;

  bool get _canLogin => _isEmailValid && _isPasswordValid;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> _bootstrapProfile(User user) async {
    // Force token refresh so Firestore auth is ready before any reads/writes.
    await user.getIdToken(true);
    await _firestore.ensureStudentProfile(user);
  }

  void _navigateToHome(NavigatorState navigator) {
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _googleSignIn
          .signOut(); // clear cached account so picker always shows all accounts
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final result =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final user = result.user;
        if (user != null) {
          UserSession.instance.setFromGoogle(
            name: user.displayName ?? account.displayName ?? '',
            email: user.email ?? account.email,
            photoUrl: user.photoURL ?? account.photoUrl?.toString(),
          );
          try {
            await _bootstrapProfile(user);
          } catch (_) {
            // Profile bootstrap failure should not block login
          }
        }
        _navigateToHome(navigator);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    bool sent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: AppColors.bodyText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Enter your registered email and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!sent) ...
                    [
                      AuthField(
                        hint: 'Email Address',
                        icon: Icons.email_outlined,
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: emailCtrl.text.trim().contains('@')
                              ? () => setSheetState(() => sent = true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ]
                  else ...
                    [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.green.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Reset link sent! Check your inbox.',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              const SizedBox(height: 44),
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
                child: GestureDetector(
                  onTap: _showForgotPassword,
                  child: Text('Forgot Password?', style: AppTextStyles.linkBold),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canLogin
                      ? () async {
                          if (_isSubmitting) {
                            return;
                          }
                          setState(() => _isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          try {
                            final cred = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            final user = cred.user;
                            if (user != null) {
                              UserSession.instance.setFromEmail(email);
                              try {
                                await _bootstrapProfile(user);
                              } catch (_) {
                                // Profile bootstrap failure should not block login
                              }
                              _navigateToHome(navigator);
                            }
                          } on FirebaseAuthException catch (e) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(e.message ?? 'Login failed')),
                            );
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text('Login failed: $e')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('Log In',
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
                  onPressed: _isSubmitting ? null : _signInWithGoogle,
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
