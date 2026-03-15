import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../core/services/firestore_service.dart';
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

  static final _kuetEmailRegex =
      RegExp(r'^[A-Za-z]+\d{7}@stud\.kuet\.ac\.bd$');

  bool get _isEmailValid =>
      _kuetEmailRegex.hasMatch(_emailController.text.trim());

  bool get _isPasswordValid => _passwordController.text.length >= 6;

  bool get _canLogin => _isEmailValid && _isPasswordValid;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> _bootstrapProfile(User user) {
    return _firestore.ensureStudentProfile(user);
  }

  Future<bool> _enforceKuetEmail(User? user) async {
    final email = (user?.email ?? '').trim();
    if (!_kuetEmailRegex.hasMatch(email)) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      return false;
    }
    return true;
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
          final ok = await _enforceKuetEmail(user);
          if (!ok) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                    content: Text(
                        'Only KUET student emails are allowed (lastname+7 digits@stud.kuet.ac.bd).')),
              );
            }
            return;
          }
          await _bootstrapProfile(user);
        }
        try {
          final token = await user?.getIdToken();
          // ignore: avoid_print
          print(
              'Google login uid=${user?.uid} token=${token?.substring(0, 20)}...');
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Signed in: ${user?.uid}')),
            );
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to get token: $e');
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
                            if (!_kuetEmailRegex.hasMatch(email)) {
                              throw FirebaseAuthException(code: 'invalid-email');
                            }
                            final cred = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            if (cred.user != null) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final ok = await _enforceKuetEmail(user);
                                if (!ok) {
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Only KUET student emails are allowed (lastname+7 digits@stud.kuet.ac.bd).')),
                                  );
                                  return;
                                }
                                await _bootstrapProfile(user);
                              }
                              try {
                                final token = await user?.getIdToken();
                                // ignore: avoid_print
                                print(
                                    'Login successful uid=${user?.uid} token=${token?.substring(0, 20)}...');
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Signed in: ${user?.uid}')),
                                  );
                                }
                              } catch (e) {
                                // ignore: avoid_print
                                print('Failed to get token: $e');
                              }
                              _navigateToHome(navigator);
                            }
                          } on FirebaseAuthException catch (e) {
                            if (!mounted) {
                              return;
                            }
                            if (e.code == 'invalid-email') {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Use KUET student email: lastname+7 digits@stud.kuet.ac.bd'),
                                ),
                              );
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
