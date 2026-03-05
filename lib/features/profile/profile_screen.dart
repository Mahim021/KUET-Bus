import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                            border: Border.all(
                                color: Colors.white54, width: 3),
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
                    const Text(
                      'Alex Johnson',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'KUET ID: 1907001',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Computer Science & Engineering',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _StatCard(label: 'Trips Taken', value: '142'),
                    const SizedBox(width: 14),
                    _StatCard(label: 'Alerts Set', value: '8'),
                    const SizedBox(width: 14),
                    _StatCard(label: 'Routes Saved', value: '3'),
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
                    value: 'alex.johnson@kuet.ac.bd',
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '+880 1711-000001',
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Department',
                    value: 'CSE, 19th Batch',
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
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About KUET Bus',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: theme.isDark ? Border.all(color: theme.border) : null,
          boxShadow: theme.isDark ? null : const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.primaryAccent,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.subText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              boxShadow: theme.isDark ? null : const [
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
      {required this.icon,
      required this.label,
      required this.initialValue});

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
            Icon(Icons.chevron_right_rounded,
                color: theme.label, size: 20),
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
