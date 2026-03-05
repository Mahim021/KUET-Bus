import 'package:flutter/material.dart';
import '../main/main_shell.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeatherCard(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'FEATURED NOTICES'),
              const SizedBox(height: 12),
              _buildNoticesCarousel(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'QUICK ACTIONS'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.surfaceDeep,
              shape: BoxShape.circle,
              border: Border.all(color: theme.border),
            ),
            child: Icon(Icons.person_rounded,
                size: 28, color: theme.subText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome, ',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'Alex!',
                        style: TextStyle(
                          color: theme.primaryAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'KUET ID: 1907001',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x14000000),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.notifications_none_rounded,
                    size: 22, color: theme.text),
              ),
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = AppThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          if (title == 'FEATURED NOTICES')
            GestureDetector(
              onTap: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: theme.primaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoticesCarousel(BuildContext context) {
    final theme = AppThemeData.of(context);
    final notices = [
      _NoticeData(
        tag: 'ALERT',
        tagColor: const Color(0xFFE53935),
        title: 'Route A Delay',
        subtitle:
            'Bus is currently 10 mins behind schedule due to traffic at Fulbarigate.',
        gradient: [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
      ),
      _NoticeData(
        tag: 'EVENT',
        tagColor: const Color(0xFF1565C0),
        title: 'Holiday Schedule',
        subtitle: 'Special vehicle arrangement starting from 8:00 AM.',
        gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      ),
      _NoticeData(
        tag: 'INFO',
        tagColor: const Color(0xFF6B7280),
        title: 'New Route Added',
        subtitle: 'Route C now covers Boyra junction from next Monday.',
        gradient: [const Color(0xFF455A64), const Color(0xFF78909C)],
      ),
    ];

    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: notices.length,
        itemBuilder: (context, i) {
          final n = notices[i];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: n.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.directions_bus_rounded,
                          color: Colors.white54, size: 64),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: n.tagColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              n.tag,
                              style: TextStyle(
                                color: n.tagColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.subtitle,
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Column(
      children: [
        // Live Bus Location — full width
        GestureDetector(
          onTap: () {
            final shell =
                context.findAncestorStateOfType<MainShellState>();
            shell?.navigateTo(2);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Bus Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track your bus in real-time',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Today's Schedule + Emergency
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final shell =
                      context.findAncestorStateOfType<MainShellState>();
                  shell?.navigateTo(1);
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.surfaceDeep,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            size: 22, color: theme.subText),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Today's\nSchedule",
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check trip timings',
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Emergency Helpdesk'),
                      content: const Text(
                          'Call KUET transport office:\n+880-41-769468'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.wifi_tethering_rounded,
                            size: 22, color: Color(0xFFE53935)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Emergency',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact helpdesk',
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- sub-widgets ----------

class _WeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wb_cloudy_rounded,
                color: Color(0xFFFFB300), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '28°C  •  Partly Cloudy',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Khulna, Bangladesh',
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '10:30 AM',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TODAY, 24 OCT',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoticeData {
  final String tag;
  final Color tagColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _NoticeData({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
