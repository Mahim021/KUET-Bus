import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final session = UserSession.instance;
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
                          child: ClipOval(
                            child: session.photoUrl != null
                                ? Image.network(
                                    session.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 50),
                                  )
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 50),
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
                            child: const Icon(Icons.edit_rounded,
                                size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      session.name.isNotEmpty ? session.name : 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.email.isNotEmpty ? session.email : '—',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: session.name.isNotEmpty ? session.name : '—',
                  ),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: session.email.isNotEmpty ? session.email : '—',
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '—',
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Department',
                    value: '—',
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
                    onTap: () => _showHelpSupport(context),
                  ),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About KUET Bus',
                    onTap: () => _showAboutApp(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      UserSession.instance.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
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

// ─── More-section helpers ────────────────────────────────────────────────────

void _showHelpSupport(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HelpSupportSheet(),
  );
}

void _showPrivacyPolicy(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PrivacyPolicySheet(),
  );
}

void _showAboutApp(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AboutSheet(),
  );
}

// ─── Bottom-sheet widgets ─────────────────────────────────────────────────────

class _ModalSheet extends StatelessWidget {
  const _ModalSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Help & Support ─────────────────────────────────────────────────

class _HelpSupportSheet extends StatelessWidget {
  const _HelpSupportSheet();

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return _ModalSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetTitle(
              icon: Icons.help_outline_rounded, title: 'Help & Support'),
          const SizedBox(height: 24),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'Email Us',
            value: 'support@kuetbus.ac.bd',
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Call Us',
            value: '+880-41-769468',
          ),
          const SizedBox(height: 24),
          Text(
            'FAQs',
            style: TextStyle(
              color: theme.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'How do I read the bus schedule?',
            answer:
                'Go to the Schedule tab to see all routes and departure times organised by shift.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            question: 'Can I track the bus live?',
            answer:
                'Yes! Open the Live Map tab to see real-time bus locations on the campus map.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            question: 'I forgot my password. What should I do?',
            answer:
                'On the login screen tap "Forgot Password?" and follow the instructions sent to your registered email.',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: theme.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceDeep,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.subText,
                  size: 20,
                ),
              ],
            ),
            if (_expanded) ...
              [
                const SizedBox(height: 8),
                Text(
                  widget.answer,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

// ── Privacy Policy ─────────────────────────────────────────────────

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  static const _sections = [
    _PolicySection(
      title: '1. Information We Collect',
      body:
          'We collect information you provide directly, such as your name, KUET student email address, roll number, and department when you register. When you use Google Sign-In, we receive your name, email, and profile photo from Google.',
    ),
    _PolicySection(
      title: '2. How We Use Your Information',
      body:
          'Your information is used solely to personalise your experience within the KUET Bus app — e.g. showing your name on the profile screen and matching you to the correct bus route for your campus.',
    ),
    _PolicySection(
      title: '3. Data Sharing',
      body:
          'We do not sell, trade, or otherwise transfer your personally identifiable information to outside parties. Data is shared only with service providers that assist in operating the app under strict confidentiality agreements.',
    ),
    _PolicySection(
      title: '4. Data Security',
      body:
          'We implement industry-standard security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
    ),
    _PolicySection(
      title: '5. Your Rights',
      body:
          'You may request deletion of your account and personal data at any time by contacting support@kuetbus.ac.bd.',
    ),
    _PolicySection(
      title: '6. Changes to This Policy',
      body:
          'We may update this Privacy Policy periodically. Continued use of the app after changes constitutes acceptance of the new policy.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.78;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const _SheetTitle(
              icon: Icons.privacy_tip_outlined, title: 'Privacy Policy'),
          const SizedBox(height: 6),
          Text(
            'Effective date: March 1, 2026',
            style: TextStyle(color: theme.subText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._sections.map((s) => _PolicyBlock(section: s)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;
}

class _PolicyBlock extends StatelessWidget {
  const _PolicyBlock({required this.section});
  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              color: theme.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.body,
            style: TextStyle(
              color: theme.subText,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── About KUET Bus ─────────────────────────────────────────────────

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return _ModalSheet(
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
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            'KUET Bus',
            style: TextStyle(
              color: theme.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0 (build 1)',
            style: TextStyle(color: theme.subText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Text(
            'Your campus commute, simplified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.subText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: theme.border),
          const SizedBox(height: 12),
          _AboutRow(label: 'Developed by', value: 'KUET CSE Department'),
          const SizedBox(height: 10),
          _AboutRow(label: 'University', value: 'Khulna University of Engineering & Technology'),
          const SizedBox(height: 10),
          _AboutRow(label: 'Contact', value: 'support@kuetbus.ac.bd'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: theme.subText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Existing helper widgets ──────────────────────────────────────────────────

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
