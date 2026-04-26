import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/user_session.dart';
import '../../models/student.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  Student? _student;
  bool _loading = true;
  bool _uploadingImage = false;

  int _photoVersion = 0; // incremented after each upload to bust widget cache

  bool _pushNotifications = true;
  bool _departureReminders = true;
  bool _vibrationAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final student = await _firestore.fetchStudent(user.uid);
      // If Firestore has no photo but we saved one locally, use the local one
      Student? resolved = student;
      if (student != null && (student.photoUrl == null || student.photoUrl!.isEmpty)) {
        final prefs = await SharedPreferences.getInstance();
        final localUrl = prefs.getString('local_photo_url_${user.uid}');
        if (localUrl != null) {
          resolved = Student(
            uid: student.uid,
            name: student.name,
            email: student.email,
            kuetId: student.kuetId,
            department: student.department,
            batch: student.batch,
            role: student.role,
            bloodGroup: student.bloodGroup,
            hometown: student.hometown,
            phoneNumber: student.phoneNumber,
            photoUrl: localUrl,
            photoPath: student.photoPath,
            createdAt: student.createdAt,
            updatedAt: student.updatedAt,
          );
          UserSession.instance.photoUrl = localUrl;
        }
      } else if (student?.photoUrl != null) {
        UserSession.instance.photoUrl = student!.photoUrl;
      }
      if (!mounted) return;
      setState(() {
        _student = resolved;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _departureReminders = prefs.getBool('departure_reminders') ?? true;
      _vibrationAlerts = prefs.getBool('vibration_alerts') ?? false;
    });
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _pickProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final file = File(picked.path);
      final storagePath = '${user.uid}.jpg';
      final supabase = Supabase.instance.client;

      // Delete existing file first so we only need INSERT (not UPDATE) RLS.
      // Ignore errors — file may not exist yet on first upload.
      try {
        await supabase.storage.from('avatars').remove([storagePath]);
      } catch (_) {}

      // Upload fresh (retry up to 3 times for transient network failures).
      Exception? lastError;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await supabase.storage.from('avatars').upload(
                storagePath,
                file,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          lastError = null;
          break;
        } on Exception catch (e) {
          lastError = e;
          if (attempt < 3) await Future.delayed(Duration(seconds: attempt));
        }
      }
      if (lastError != null) throw lastError;

      // Store the clean URL (no timestamp) so restarts always load correctly.
      // Cache-busting in the same session is handled by _photoVersion below.
      final url = supabase.storage.from('avatars').getPublicUrl(storagePath);

      // Evict Flutter's in-memory image cache for this URL so the new image
      // shows immediately without needing a timestamp in the stored URL.
      imageCache.evict(NetworkImage(url));

      // Save URL to Firestore; fall back to SharedPreferences if rules deny.
      await user.getIdToken(true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
              {
                'photoUrl': url,
                'photoPath': storagePath,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_photo_url_${user.uid}', url);
      }

      UserSession.instance.photoUrl = url;

      final current = _student;
      final updated = Student(
        uid: user.uid,
        name: current?.name ?? user.displayName ?? 'Student',
        email: current?.email ?? user.email ?? '',
        kuetId: current?.kuetId ?? '',
        department: current?.department ?? 'Not provided',
        batch: current?.batch ?? '',
        role: current?.role ?? 'student',
        bloodGroup: current?.bloodGroup,
        hometown: current?.hometown,
        phoneNumber: current?.phoneNumber,
        photoUrl: url,
        photoPath: storagePath,
        createdAt: current?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _student = updated;
          _photoVersion++;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  void _showEditProfile() {
    final student = _student;
    if (student == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        student: student,
        onSaved: (updated) async {
          await _firestore.upsertStudent(updated);
          if (mounted) setState(() => _student = updated);
        },
      ),
    );
  }

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final student = _student;

    final name = student?.name ?? user?.displayName ?? 'Student';
    final kuetId = student?.kuetId ?? 'N/A';
    final department = student?.department ?? 'Not provided';
    final batch = student?.batch ?? '';
    final email = student?.email ?? user?.email ?? 'Not set';
    final phone = student?.phoneNumber ?? 'Not set';
    final bloodGroup = student?.bloodGroup ?? 'Not set';
    final hometown = student?.hometown ?? 'Not set';
    final departmentText =
        batch.isEmpty ? department : '$department, $batch Batch';
    final photoUrl = student?.photoUrl;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header banner ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white54, width: 3),
                            ),
                            child: ClipOval(
                              child: _uploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : photoUrl != null
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          key: ValueKey('${photoUrl}_$_photoVersion'),
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showEditProfile,
                          child: const Icon(Icons.edit_outlined,
                              color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KUET ID: $kuetId',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        departmentText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Account Info ───────────────────────────────────────────
              _Section(
                title: 'Account Info',
                children: [
                  _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email),
                  _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phone),
                  _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Department',
                      value: departmentText),
                  _InfoTile(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood Group',
                      value: bloodGroup),
                  _InfoTile(
                      icon: Icons.home_outlined,
                      label: 'Hometown',
                      value: hometown),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: student != null ? _showEditProfile : null,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // ── Preferences ────────────────────────────────────────────
              _Section(
                title: 'Preferences',
                children: [
                  _DarkModeToggleTile(),
                  _PrefToggleTile(
                    icon: Icons.notifications_active_outlined,
                    label: 'Push Notifications',
                    value: _pushNotifications,
                    onChanged: (v) {
                      setState(() => _pushNotifications = v);
                      _setPreference('push_notifications', v);
                    },
                  ),
                  _PrefToggleTile(
                    icon: Icons.access_time_outlined,
                    label: 'Departure Reminders',
                    value: _departureReminders,
                    onChanged: (v) {
                      setState(() => _departureReminders = v);
                      _setPreference('departure_reminders', v);
                    },
                  ),
                  _PrefToggleTile(
                    icon: Icons.vibration_rounded,
                    label: 'Vibration Alerts',
                    value: _vibrationAlerts,
                    onChanged: (v) {
                      setState(() => _vibrationAlerts = v);
                      _setPreference('vibration_alerts', v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── More ───────────────────────────────────────────────────
              _Section(
                title: 'More',
                children: [
                  _ActionTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => _showInfo('Help & Support',
                        'Contact the KUET Bus admin for route, timing, or account issues.'),
                  ),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _showInfo('Privacy Policy',
                        'Your account details are stored in Firebase for KUET Bus access and profile display.'),
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About KUET Bus',
                    onTap: () => _showInfo('About KUET Bus',
                        'KUET Bus provides notices, live bus tracking, and schedules for campus transport.'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Student student;
  final Future<void> Function(Student) onSaved;

  const _EditProfileSheet({required this.student, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bloodCtrl;
  late final TextEditingController _hometownCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _phoneCtrl =
        TextEditingController(text: widget.student.phoneNumber ?? '');
    _bloodCtrl =
        TextEditingController(text: widget.student.bloodGroup ?? '');
    _hometownCtrl =
        TextEditingController(text: widget.student.hometown ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bloodCtrl.dispose();
    _hometownCtrl.dispose();
    super.dispose();
  }

  String? _blank(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    setState(() => _saving = true);

    final updated = Student(
      uid: widget.student.uid,
      name: name,
      email: widget.student.email,
      kuetId: widget.student.kuetId,
      department: widget.student.department,
      batch: widget.student.batch,
      role: widget.student.role,
      bloodGroup: _blank(_bloodCtrl.text),
      hometown: _blank(_hometownCtrl.text),
      phoneNumber: _blank(_phoneCtrl.text),
      photoUrl: widget.student.photoUrl,
      photoPath: widget.student.photoPath,
      createdAt: widget.student.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.onSaved(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile',
              style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _EditField(
                label: 'Full Name',
                controller: _nameCtrl,
                theme: theme,
                keyboardType: TextInputType.name),
            _EditField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                theme: theme,
                keyboardType: TextInputType.phone),
            _EditField(
                label: 'Blood Group',
                controller: _bloodCtrl,
                theme: theme),
            _EditField(
                label: 'Hometown',
                controller: _hometownCtrl,
                theme: theme),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {

  final String label;
  final TextEditingController controller;
  final AppThemeData theme;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.theme,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: theme.subText,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: theme.surfaceDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(color: theme.text, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section container ────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(18),
              border: theme.isDark ? Border.all(color: theme.border) : null,
              boxShadow: theme.isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Info tile (read-only) ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.surfaceDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.primaryAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: theme.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preference toggle tile (externally controlled) ────────────────────────────

class _PrefToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.surfaceDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.primaryAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.primaryAccent,
            activeTrackColor: theme.primaryAccent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.surfaceDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.subText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.label, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Dark mode toggle ──────────────────────────────────────────────────────────

class _DarkModeToggleTile extends StatelessWidget {
  const _DarkModeToggleTile();

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final notifier = AppThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.surfaceDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              theme.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              size: 18,
              color: theme.primaryAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: theme.isDark,
            onChanged: (_) => notifier.toggle(),
            activeThumbColor: theme.primaryAccent,
            activeTrackColor: theme.primaryAccent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
