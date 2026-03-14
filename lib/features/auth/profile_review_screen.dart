import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../core/services/firestore_service.dart';
import '../../models/student.dart';
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
  late final TextEditingController _kuetIdController;
  late final TextEditingController _departmentController;
  late final TextEditingController _batchController;
  final _bloodGroupController = TextEditingController();
  final _hometownController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firestore = FirestoreService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    final localPart = widget.email.split('@').first;
    final kuetId = _extractKuetId(localPart);
    _kuetIdController = TextEditingController(text: kuetId);
    _departmentController = TextEditingController();
    _batchController = TextEditingController(text: _deriveBatch(kuetId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _kuetIdController.dispose();
    _departmentController.dispose();
    _batchController.dispose();
    _bloodGroupController.dispose();
    _hometownController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _extractKuetId(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match?.group(0) ?? '';
  }

  String _deriveBatch(String kuetId) {
    if (kuetId.length < 2) {
      return '';
    }
    return '20${kuetId.substring(0, 2)}';
  }

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _kuetIdController.text.trim().isNotEmpty &&
        _departmentController.text.trim().isNotEmpty &&
        _batchController.text.trim().isNotEmpty;
  }

  Future<void> _completeSignup() async {
    if (_isSubmitting || !_canSubmit) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: widget.password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-created');
      }

      await user.updateDisplayName(_nameController.text.trim());
      final student = Student(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        kuetId: _kuetIdController.text.trim(),
        department: _departmentController.text.trim(),
        batch: _batchController.text.trim(),
        bloodGroup: _optional(_bloodGroupController.text),
        hometown: _optional(_hometownController.text),
        phoneNumber: _optional(_phoneController.text),
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.upsertStudent(student);

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
      ('KUET ID', _kuetIdController, false, TextInputType.number),
      ('Department', _departmentController, false, TextInputType.text),
      ('Batch', _batchController, false, TextInputType.text),
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
