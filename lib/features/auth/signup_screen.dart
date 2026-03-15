import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import 'widgets/auth_field.dart';
import 'profile_review_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreed = false;

  // Accepts only: <lastname><7 digit kuet roll>@stud.kuet.ac.bd
  static final _kuetEmailRegex =
      RegExp(r'^[A-Za-z]+\d{7}@stud\.kuet\.ac\.bd$');

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;
  bool get _isEmailValid =>
      _kuetEmailRegex.hasMatch(_emailController.text.trim());
  bool get _showEmailError =>
      _emailController.text.trim().isNotEmpty && !_isEmailValid;
  bool get _isPasswordValid => _passwordController.text.length >= 6;
  bool get _isConfirmValid =>
      _confirmController.text == _passwordController.text &&
      _confirmController.text.isNotEmpty;

  bool get _canSignUp =>
      _isNameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _isConfirmValid &&
      _agreed;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileReviewScreen(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppColors.bodyText),
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AppColors.bodyText),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: AppColors.primary, size: 38),
                    ),
                    const SizedBox(height: 14),
                    Text('KUET Bus', style: AppTextStyles.authAppTitle),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Create Account', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              Text('Join the KUET Bus transportation community.',
                  style: AppTextStyles.authSubtitle),
              const SizedBox(height: 24),
              AuthField(
                label: 'FULL NAME',
                hint: 'Enter your name',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                onChanged: (_) => _rebuild(),
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'EMAIL ADDRESS',
                hint: 'alam2107023@stud.kuet.ac.bd',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                onChanged: (_) => _rebuild(),
              ),
              if (_showEmailError) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Use your KUET student email (e.g. alam2107023@stud.kuet.ac.bd)',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AuthField(
                label: 'PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                controller: _passwordController,
                onChanged: (_) => _rebuild(),
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'CONFIRM PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                controller: _confirmController,
                onChanged: (_) => _rebuild(),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _agreed
                              ? AppColors.primary
                              : AppColors.checkboxBorder,
                          width: 2,
                        ),
                        color: _agreed ? AppColors.primary : Colors.transparent,
                      ),
                      child: _agreed
                          ? const Icon(Icons.check,
                              size: 14, color: AppColors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(color: AppColors.subText, fontSize: 13),
                        children: [
                          TextSpan(text: 'By signing up, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.bodyText,
                                fontSize: 13),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.bodyText,
                                fontSize: 13),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canSignUp ? _onSignUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign Up',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: AppColors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.bodySmall),
                        TextSpan(text: 'Log In', style: AppTextStyles.linkBold),
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
