import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0;
  final _searchController = TextEditingController();

  final _days = ['MON\n12', 'TUE\n13', 'WED\n14', 'THU\n15', 'FRI\n16'];

  final _morningSchedules = [
    _ScheduleEntry(
        time: '07:30', period: 'AM', route: 'Campus → Town', busNo: '04 (Drabir)'),
    _ScheduleEntry(
        time: '08:15', period: 'AM', route: 'Campus → Phulbari', busNo: '07 (Torsa)'),
    _ScheduleEntry(
        time: '09:00', period: 'AM', route: 'Town → Campus', busNo: '01 (Rupsa)'),
  ];

  final _afternoonSchedules = [
    _ScheduleEntry(
        time: '01:45', period: 'PM', route: 'Town → Campus', busNo: '02 (Shetu)'),
    _ScheduleEntry(
        time: '05:30', period: 'PM', route: 'Campus → City Circle', busNo: '11 (Kapotakkho)'),
    _ScheduleEntry(
        time: '06:00', period: 'PM', route: 'Campus → Kalishpur', busNo: '05 (Padma)'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: theme.text, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Bus Schedule',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                  boxShadow: theme.isDark
                      ? null
                      : [
                          const BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search route or bus no...',
                    hintStyle:
                        TextStyle(color: theme.subText, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: theme.subText, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Date picker
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 8),
                itemCount: _days.length,
                itemBuilder: (context, i) {
                  final parts = _days[i].split('\n');
                  final isSelected = _selectedDayIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? null
                            : Border.all(color: theme.border),
                        boxShadow: isSelected
                            ? null
                            : theme.isDark
                                ? null
                                : [
                                    const BoxShadow(
                                      color: Color(0x08000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            parts[0],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white70
                                  : theme.subText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parts[1],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Schedule list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _SectionHeader(title: 'Morning Departures'),
                  const SizedBox(height: 12),
                  ..._morningSchedules.map((s) => _ScheduleCard(entry: s)),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Afternoon Departures'),
                  const SizedBox(height: 12),
                  ..._afternoonSchedules.map((s) => _ScheduleCard(entry: s)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Text(
      title,
      style: TextStyle(
        color: theme.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final _ScheduleEntry entry;
  const _ScheduleCard({required this.entry});

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _alerted = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Time box
          Container(
            width: 70,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.entry.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.entry.period,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry.route,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        size: 14, color: theme.subText),
                    const SizedBox(width: 4),
                    Text(
                      'Bus No: ${widget.entry.busNo}',
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _alerted = !_alerted),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _alerted
                    ? AppColors.primary
                    : theme.surfaceDeep,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _alerted
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: _alerted ? Colors.white : theme.subText,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEntry {
  final String time;
  final String period;
  final String route;
  final String busNo;

  const _ScheduleEntry({
    required this.time,
    required this.period,
    required this.route,
    required this.busNo,
  });
}
