import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../core/services/firestore_service.dart';
import '../main/main_shell.dart';

class ProfileReviewScreen extends StatefulWidget {
  const ProfileReviewScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  State<ProfileReviewScreen> createState() => _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends State<ProfileReviewScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final String _kuetId;
  late final String _deptCode;
  late final String _batch;
  final _bloodGroupController = TextEditingController();
  final _hometownController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firestore = FirestoreService();
  bool _isSubmitting = false;

  static final _kuetEmailRegex =
      RegExp(r'^[A-Za-z]+(\d{7})@stud\.kuet\.ac\.bd$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);

    final match = _kuetEmailRegex.firstMatch(widget.email.trim());
    _kuetId = match?.group(1) ?? '';
    _batch = _kuetId.length >= 2 ? '20${_kuetId.substring(0, 2)}' : '';
    _deptCode = _kuetId.length >= 4 ? _kuetId.substring(2, 4) : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bloodGroupController.dispose();
    _hometownController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _kuetId.isNotEmpty &&
        _batch.isNotEmpty &&
        _deptCode.isNotEmpty;
  }

  Future<void> _completeSignup() async {
    if (_isSubmitting || !_canSubmit) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim();
      if (!_kuetEmailRegex.hasMatch(email)) {
        throw FirebaseAuthException(code: 'invalid-email');
      }

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: widget.password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-created');
      }

      await user.updateDisplayName(_nameController.text.trim());

      // Immutable identity fields are derived from the KUET email.
      await _firestore.ensureStudentProfile(
        user,
        name: _nameController.text.trim(),
      );

      await _firestore.updateStudentFields(user.uid, {
        'bloodGroup': _optional(_bloodGroupController.text),
        'hometown': _optional(_hometownController.text),
        'phoneNumber': _optional(_phoneController.text),
        'updatedAt': DateTime.now(),
      });

      if (!mounted) {
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Use KUET student email: lastname+7 digits@stud.kuet.ac.bd')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Signup failed')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('Full Name', _nameController, false, TextInputType.name),
      ('Email Address', _emailController, true, TextInputType.emailAddress),
      ('Blood Group', _bloodGroupController, false, TextInputType.text),
      ('Hometown', _hometownController, false, TextInputType.text),
      ('Phone Number', _phoneController, false, TextInputType.phone),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios,
              color: AppColors.bodyText, size: 20),
        ),
        title: const Text(
          'Review Your Profile',
          style: TextStyle(
              color: AppColors.bodyText,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Information Verified',
              style: TextStyle(
                  color: AppColors.bodyText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete the fields below before creating\nyour account and profile.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSubtitle,
            ),
            const SizedBox(height: 28),
            ...fields.map(
              (field) => _ReviewField(
                label: field.$1,
                controller: field.$2,
                readOnly: field.$3,
                keyboardType: field.$4,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KUET Identity (from email)',
                    style: TextStyle(
                      color: AppColors.bodyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('KUET ID: $_kuetId',
                      style: const TextStyle(
                          color: AppColors.subText, fontSize: 13)),
                  Text('Batch: $_batch',
                      style: const TextStyle(
                          color: AppColors.subText, fontSize: 13)),
                  Text('Dept Code: $_deptCode',
                      style: const TextStyle(
                          color: AppColors.subText, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSubmit ? _completeSignup : null,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Confirm & Continue',
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline,
                              color: AppColors.white, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text("Something's wrong? Edit details",
                  style: AppTextStyles.authSubtitle),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({
    required this.label,
    required this.controller,
    required this.readOnly,
    required this.keyboardType,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.authSubtitle),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 15, color: AppColors.bodyText),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
