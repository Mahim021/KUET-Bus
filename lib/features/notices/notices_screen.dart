import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final _notices = [
    _NoticeItem(
      tag: 'ALERT',
      tagColor: Color(0xFFE53935),
      tagBg: Color(0xFFFEF2F2),
      title: 'Route A Delay',
      body:
          'Bus is currently 10 mins behind schedule due to heavy traffic at Fulbarigate intersection.',
      time: '2 min ago',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFE53935),
    ),
    _NoticeItem(
      tag: 'EVENT',
      tagColor: Color(0xFF1565C0),
      tagBg: Color(0xFFEFF6FF),
      title: 'Holiday Schedule',
      body:
          'Special vehicle arrangement starting from 8:00 AM on national holiday. All routes will operate.',
      time: '1 hr ago',
      icon: Icons.event_rounded,
      iconColor: Color(0xFF1565C0),
    ),
    _NoticeItem(
      tag: 'INFO',
      tagColor: Color(0xFF059669),
      tagBg: Color(0xFFECFDF5),
      title: 'New Route Added',
      body:
          'Route C now covers Boyra junction starting from next Monday. Check schedule for details.',
      time: '3 hr ago',
      icon: Icons.info_outline_rounded,
      iconColor: Color(0xFF059669),
    ),
    _NoticeItem(
      tag: 'ALERT',
      tagColor: Color(0xFFE53935),
      tagBg: Color(0xFFFEF2F2),
      title: 'Bus No. 5 Cancelled',
      body:
          'Due to maintenance, Bus No. 5 (Padma) is cancelled today. Alternate arrangements via Bus No. 3.',
      time: '5 hr ago',
      icon: Icons.cancel_rounded,
      iconColor: Color(0xFFE53935),
    ),
    _NoticeItem(
      tag: 'INFO',
      tagColor: Color(0xFF059669),
      tagBg: Color(0xFFECFDF5),
      title: 'Pick-up Point Moved',
      body:
          'The Fulbarigate pick-up point has been temporarily relocated 200m ahead due to road construction.',
      time: 'Yesterday',
      icon: Icons.location_on_rounded,
      iconColor: Color(0xFF059669),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notices',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x10000000),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.filter_list_rounded,
                        color: theme.subText, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: theme.surfaceDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.subText,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Alerts'),
                    Tab(text: 'Events'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NoticeList(notices: _notices),
                  _NoticeList(
                      notices: _notices
                          .where((n) => n.tag == 'ALERT')
                          .toList()),
                  _NoticeList(
                      notices: _notices
                          .where((n) => n.tag == 'EVENT')
                          .toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeList extends StatelessWidget {
  final List<_NoticeItem> notices;
  const _NoticeList({required this.notices});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    if (notices.isEmpty) {
      return Center(
        child: Text(
          'No notices available',
          style: TextStyle(color: theme.subText, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: notices.length,
      itemBuilder: (context, i) => _NoticeCard(item: notices[i]),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final _NoticeItem item;
  const _NoticeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: theme.isDark
            ? Border.all(color: theme.border)
            : null,
        boxShadow: theme.isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.tagBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: TextStyle(
                          color: item.tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.time,
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 13,
                    height: 1.4,
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

class _NoticeItem {
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;

  const _NoticeItem({
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}
