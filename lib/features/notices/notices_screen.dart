import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../../models/notice.dart';

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

  final _firestore = FirestoreService();

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
              child: StreamBuilder<List<Notice>>(
                stream: _firestore.watchNotices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading notices: ${snapshot.error}',
                        style: TextStyle(color: theme.subText),
                      ),
                    );
                  }
                  final data = snapshot.data ?? [];
                  final items = data.map(_toNoticeItem).toList();
                  final alerts = items.where((n) => n.tag == 'ALERT').toList();
                  final events = items.where((n) => n.tag == 'EVENT').toList();
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _NoticeList(notices: items),
                      _NoticeList(notices: alerts),
                      _NoticeList(notices: events),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NoticeItem _toNoticeItem(Notice notice) {
    final tag = notice.tag.toUpperCase();
    final tagColor = _tagColor(tag);
    return _NoticeItem(
      tag: tag,
      tagColor: tagColor,
      tagBg: _tagBackground(tag),
      title: notice.title,
      body: notice.body,
      time: _formatTime(notice.createdAt ?? notice.updatedAt),
      icon: _tagIcon(tag),
      iconColor: tagColor,
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
        return const Color(0xFF059669);
    }
  }

  Color _tagBackground(String tag) {
    switch (tag) {
      case 'ALERT':
        return const Color(0xFFFEF2F2);
      case 'EVENT':
        return const Color(0xFFEFF6FF);
      case 'INFO':
      default:
        return const Color(0xFFECFDF5);
    }
  }

  IconData _tagIcon(String tag) {
    switch (tag) {
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'EVENT':
        return Icons.event_rounded;
      case 'INFO':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return 'Just now';
    }
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} days ago';
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
        border: theme.isDark ? Border.all(color: theme.border) : null,
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
