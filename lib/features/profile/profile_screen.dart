import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../../models/student.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FutureBuilder<Student?>(
            future: user == null
                ? Future.value(null)
                : firestore.fetchStudent(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildProfileContent(context, theme, snapshot.data, user);
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildProfileContent(
    BuildContext context, AppThemeData theme, Student? student, User? user) {
  final name = student?.name ?? user?.displayName ?? 'Student';
  final kuetId = student?.kuetId ?? 'N/A';
  final department = student?.department ?? 'Not provided';
  final batch = student?.batch ?? '';
  final email = student?.email ?? user?.email ?? 'Not set';
  final phone = student?.phoneNumber ?? 'Not set';
  final departmentText =
      batch.isEmpty ? department : '$department, $batch Batch';

  return SingleChildScrollView(
    child: Column(
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 3),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 50),
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
                      child: const Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'KUET ID: $kuetId',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        // Profile info section
        _Section(
          title: 'Account Info',
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Department',
              value: departmentText,
            ),
          ],
        ),

        const SizedBox(height: 16),
        _Section(
          title: 'Preferences',
          children: [
            _DarkModeToggleTile(),
            _ToggleTile(
              icon: Icons.notifications_active_outlined,
              label: 'Push Notifications',
              initialValue: true,
            ),
            _ToggleTile(
              icon: Icons.access_time_outlined,
              label: 'Departure Reminders',
              initialValue: true,
            ),
            _ToggleTile(
              icon: Icons.vibration_rounded,
              label: 'Vibration Alerts',
              initialValue: false,
            ),
          ],
        ),

        const SizedBox(height: 16),
        _Section(
          title: 'More',
          children: [
            _ActionTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => _showInfo(context, 'Help & Support',
                  'Contact the KUET Bus admin for route, timing, or account issues.'),
            ),
            _ActionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showInfo(context, 'Privacy Policy',
                  'Your account details are stored in Firebase for KUET Bus access and profile display.'),
            ),
            _ActionTile(
              icon: Icons.info_outline_rounded,
              label: 'About KUET Bus',
              onTap: () => _showInfo(context, 'About KUET Bus',
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
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

Future<void> _logout(BuildContext context) async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
  if (!context.mounted) {
    return;
  }
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

void _showInfo(BuildContext context, String title, String body) {
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initialValue;
  const _ToggleTile(
      {required this.icon, required this.label, required this.initialValue});

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

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
            child: Icon(widget.icon, size: 18, color: theme.primaryAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
            activeThumbColor: theme.primaryAccent,
          ),
        ],
      ),
    );
  }
}

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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.label, size: 20),
          ],
        ),
      ),
    );
  }
}

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
              theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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
                fontWeight: FontWeight.w500,
              ),
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
