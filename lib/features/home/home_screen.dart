import 'package:flutter/material.dart';
import 'dart:async';
import '../main/main_shell.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/notice.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/user_session.dart';
import '../../core/services/weather_service.dart';
import '../live_map/live_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: StreamBuilder<List<Notice>>(
          stream: FirestoreService().watchNotices(),
          builder: (context, snapshot) {
            final notices = snapshot.data ?? const <Notice>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildSectionHeader(context, 'FEATURED NOTICES'),
                  const SizedBox(height: 8),
                  _buildNoticesCarousel(context, notices),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WeatherCard(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = AppThemeData.of(context);
    final session = UserSession.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.findAncestorStateOfType<MainShellState>()?.navigateTo(4),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.surfaceDeep,
                shape: BoxShape.circle,
                border: Border.all(color: theme.border),
              ),
              child: session.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        session.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.person_rounded,
                            size: 28, color: theme.subText),
                      ),
                    )
                  : Icon(Icons.person_rounded,
                      size: 28, color: theme.subText),
            ),
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
                        text: session.name.split(' ').first,
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
                Text(
                  session.email,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                context.findAncestorStateOfType<MainShellState>()?.navigateTo(3),
            child: Stack(
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
          ),
        ],
      ),
    );
  }

  _NoticeData _mapNotice(Notice notice) {
    final tag = notice.tag.toUpperCase();
    final tagColor = _tagColor(tag);
    return _NoticeData(
      tag: tag,
      tagColor: tagColor,
      title: notice.title,
      subtitle: notice.body,
      gradient: _tagGradient(tag),
    );
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'ALERT':
        return const Color(0xFFE53935);
      case 'EVENT':
        return const Color(0xFF1565C0);
      case 'INFO':
      default:
        return const Color(0xFF6B7280);
    }
  }

  List<Color> _tagGradient(String tag) {
    switch (tag) {
      case 'ALERT':
        return [const Color(0xFFD32F2F), const Color(0xFFF06292)];
      case 'EVENT':
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case 'INFO':
      default:
        return [const Color(0xFF455A64), const Color(0xFF78909C)];
    }
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
              onTap: () {
                final shell = context.findAncestorStateOfType<MainShellState>();
                shell?.navigateToNotices();
              },
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

  Widget _buildNoticesCarousel(BuildContext context, List<Notice> notices) {
    final theme = AppThemeData.of(context);
    final featured = notices.take(3).map(_mapNotice).toList();

    if (featured.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'No notices have been published yet.',
          style: TextStyle(
            color: theme.subText,
            fontSize: 14,
          ),
        ),
      );
    }

    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: featured.length,
        itemBuilder: (context, i) {
          final n = featured[i];
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveMapScreen()),
            );
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
                Expanded(
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

class _WeatherCard extends StatefulWidget {
  const _WeatherCard();

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  final _service = WeatherService();
  Timer? _clockTimer;
  Timer? _refreshTimer;

  DateTime _now = DateTime.now();
  WeatherSnapshot? _weather;
  bool _loading = true;

  // Fixed location for now. We can switch to device location later if needed.
  static const _kKhulnaLat = 22.8456;
  static const _kKhulnaLon = 89.5403;

  @override
  void initState() {
    super.initState();

    // Keep the clock fresh without rebuilding every second.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });

    _fetchWeather();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchWeather();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snapshot = await _service.fetchCurrentWeather(
        latitude: _kKhulnaLat,
        longitude: _kKhulnaLon,
      );
      if (!mounted) return;
      setState(() {
        _weather = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour12}:${_two(dt.minute)} $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    final mon = months[dt.month - 1];
    return '${dt.day} $mon';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final weather = _weather;

    final desc = weather?.summary ?? (_loading ? 'Loading...' : 'Unavailable');
    final temp = weather?.temperatureC;
    final tempText = temp == null ? '--°C' : '${temp.round()}°C';
    final icon = weather?.icon ?? Icons.wb_cloudy_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              color: theme.surfaceDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFFB300), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tempText  •  $desc',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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
                _formatTime(_now),
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TODAY, ${_formatDate(_now)}',
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
