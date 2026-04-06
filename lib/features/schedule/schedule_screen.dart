import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../live_map/live_map_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;
  const ScheduleScreen({super.key, this.initialDate});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _searchController = TextEditingController();
  late final List<DateTime> _recentDates;
  late DateTime _selectedDate;
  late final DateTime _today;
  bool _useRamadanSchedule = false;

  static const _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Ramadan 2026: approx Mar 1 – Mar 30 (adjust as needed)
  static bool _isRamadan(DateTime d) {
    final y = d.year;
    if (y == 2026) return d.month == 3 && d.day >= 1 && d.day <= 30;
    return false;
  }

  // Returns map of section title -> list of entries for the given date
  Map<String, List<_ScheduleEntry>> _schedulesForDate(DateTime date) {
    // Friday: no service regardless of Ramadan
    if (date.weekday == DateTime.friday) return {};

    final isSaturday = date.weekday == DateTime.saturday;

    if (_useRamadanSchedule) {
      if (isSaturday) {
        return {
          'Morning': [
            const _ScheduleEntry(time:'09:30', period:'AM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari, 12:30 PM — Directly back'),
            const _ScheduleEntry(time:'09:30', period:'AM', route:'Campus → Town', routeNo:6, busNo:'Special-1', remarks:'Shibbari, 12:30 PM — Round residential area (9:30 AM)'),
          ],
        };
      }
      // Ramadan Sun–Thu (from official Ramadan notice)
      return {
        'Morning': [
          const _ScheduleEntry(time:'07:00', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 7:50 AM — Via Royel Mor-Shibbari back'),
          const _ScheduleEntry(time:'07:00', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Normal-1', remarks:'Moylapota 7:50 AM — Via Moylapota-Shibbari-Sonadanga-Notun Rasta back'),
          const _ScheduleEntry(time:'07:00', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 8:10 AM — Will round residential area (7:00 AM)'),
          const _ScheduleEntry(time:'07:50', period:'AM', route:'Campus → Town', routeNo:3, busNo:'Normal-1', remarks:'Fultola Bazar 8:20 AM — Via Pother Bazar-Afilgate-Shiromoni Bazar back'),
          const _ScheduleEntry(time:'07:50', period:'AM', route:'Campus → Town', routeNo:5, busNo:'Normal-1', remarks:'Royel Mor 8:30 AM — Will round residential area (7:25 AM)'),
          const _ScheduleEntry(time:'07:50', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Normal-1', remarks:'Moylapota 8:05 AM — Via Nirala-Gollamari-Sonadanga-Notun Rasta back'),
          const _ScheduleEntry(time:'07:45', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Normal-1', remarks:'Moylapota 8:30 AM — Via Moylapota-Shibbari-Sonadanga-Notun Rasta back'),
          const _ScheduleEntry(time:'07:15', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Special-1', remarks:'Rupsa 8:05 AM — Via Royel Mor-Shibbari back'),
          const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Special-1(AC)', remarks:'Moylapota 8:10 AM — Via Nirala-Gollamari-Sonadanga-Shibbari-Boyra Bazar-College Mor-Notun Rasta back'),
          const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Special-1(AC)', remarks:'Rupsa 8:10 AM — Via Moylapota-Nirala-Gollamari-Sonadanga-Boyra Bazar-Notun Rasta back'),
        ],
        'Noon': [
          const _ScheduleEntry(time:'12:50', period:'PM', route:'Campus → Town', routeNo:2, busNo:'Normal-1', remarks:'Sonadanga 1:40 PM — Via Notun Rasta-Boyra Bazar back'),
          const _ScheduleEntry(time:'12:50', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 1:40 PM — Directly there and back'),
          const _ScheduleEntry(time:'12:50', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Special-1', remarks:'Rupsa 2:00 PM — Via City College Mor-Shibbari-Gollamari-Moylapota back'),
          const _ScheduleEntry(time:'12:50', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Special-1(AC)', remarks:'Rupsa 2:00 PM — Via Goalkhali-Abu Nasser Hospital-Boyra Bazar-Sonadanga-Gollamari-Moylapota'),
        ],
        'Afternoon': [
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 4:30 PM — Directly there and back'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 5:00 PM — Via Notun Rasta-Boyra Bazar-Sonadanga'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 5:00 PM — Campus-Shibbari-Royel Mor-Rupsa'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:3, busNo:'Normal-1', remarks:'Fultola Bazar 4:30 PM — Via Shiromoni Bazar-Afilgate-Pother Bazar'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1', remarks:'Shibbari 5:00 PM — Via Notun Rasta-Boyra Bazar-Shibbari-Sonadanga-Gollamari-Ferighat'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1(AC)', remarks:'Shibbari 5:00 PM — Via Notun Rasta-Sonadanga-Shibbari-Sonadanga-Gollamari-Ferighat'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Special-1(AC)', remarks:'Rupsa 5:00 PM — Via Moylapota-Nirala-Moylapota-Rupsa'),
          const _ScheduleEntry(time:'03:35', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1(AC)', remarks:'Shibbari 5:00 PM — Via Moylapota-Nirala-Gollamari-Sonadanga-Boyra Bazar-Notun Rasta'),
        ],
      };
    }

    if (isSaturday) {
      return {
        'Morning': [
          const _ScheduleEntry(time:'09:30', period:'AM', route:'Campus → Town', routeNo:6, busNo:'Normal-2', remarks:'Shibbari 12:30 PM — Directly Ferighat & Sonadanga-Ferighat'),
          const _ScheduleEntry(time:'09:30', period:'AM', route:'Campus → Town', routeNo:6, busNo:'Special-1', remarks:'Shibbari 12:30 PM — Round residential area to Ferighat'),
        ],
      };
    }

    // Sun–Thu regular weekday
    return {
      'Morning': [
        const _ScheduleEntry(time:'06:30', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 7:10 AM — Back via Royalmore & Ferighat'),
        const _ScheduleEntry(time:'06:30', period:'AM', route:'Campus → Town', routeNo:7, busNo:'Normal-1', remarks:'Gollamari 7:10 AM — Back via Moylapota, Shibbari, Sonadanga, Notun Rasta'),
        const _ScheduleEntry(time:'07:00', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 8:00 AM — Will round residential area (7:00 AM)'),
        const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Normal-1', remarks:'Moylapota 8:00 AM — Back via Nirala-Gollamari-Sonadanga-Notun Rasta'),
        const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:2, busNo:'Normal-1', remarks:'Sonadanga 8:10 AM — Back via Boyra Bazar-Notun Rasta'),
        const _ScheduleEntry(time:'07:25', period:'AM', route:'Campus → Town', routeNo:5, busNo:'Normal-1', remarks:'Royel Mor 8:00 AM — Back via Shibbari, Joragate, Alamnagar, Platinum Mor, Notunrasta'),
        const _ScheduleEntry(time:'07:25', period:'AM', route:'Campus → Town', routeNo:3, busNo:'Normal-1', remarks:'Fultala Bazar 8:10 AM — Back via Pother Bazar-Afilgate-Shiromoni Bazar'),
        const _ScheduleEntry(time:'07:15', period:'AM', route:'Campus → Town', routeNo:7, busNo:'Special-1', remarks:'Gollamari 8:05 AM — Back via Moylapota, Shivbari, Sonadanga, Notun Rasta'),
        const _ScheduleEntry(time:'07:15', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Special-1', remarks:'Rupsa 8:05 AM — Back via Royal Mor and Shivbari'),
        const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:8, busNo:'Special-1(AC)', remarks:'Moylapota 8:10 AM — Back via Nirala-Gollamari-Sonadanga-Shibbari-Boira Bazar-College Mor-Notun Rasta'),
        const _ScheduleEntry(time:'07:20', period:'AM', route:'Campus → Town', routeNo:4, busNo:'Special-1(AC)', remarks:'Rupsa 8:10 AM — Back via Royal Mor and Shivbari'),
      ],
      'Noon': [
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 2:05 PM — Will go and Back Ferighat'),
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:2, busNo:'Normal-1', remarks:'Sonadanga 2:05 PM — Back via Notun Rasta-Boira Bazar'),
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Normal-1', remarks:'Rupsa 2:00 PM — Will go and Back directly'),
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Special-1', remarks:'Rupsa 2:20 PM — Back via Moilapota-Powerhouse Mor (2:30)'),
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:7, busNo:'Special-1', remarks:'Gollamari 2:25 PM — Back via Boira Bazar-Sonadanga-Moilapota'),
        const _ScheduleEntry(time:'01:15', period:'PM', route:'Campus → Town', routeNo:4, busNo:'Special-1(AC)', remarks:'Rupsa 2:20 PM — Back via Goalkhali-Abu Naser-Boira Bazar-College Mor-Shibbari-Sonadanga-Gollamari-Moilapota'),
      ],
      'Afternoon': [
        const _ScheduleEntry(time:'04:00', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-2', remarks:'Shibbari 4:30 PM — Will go and back directly'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 7:00 PM — Will go and back Ferighat'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-2', remarks:'Shibbari 7:30 PM — Will go Rupsha'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-2', remarks:'Shibbari 6:30 PM — Notun Rasta-Boira Bazar-Gollamari-Moylapota-Ferighat'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 6:30 PM — Ferighat via Notunrasta, Platinum More, Alamnagar, Joragate'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:3, busNo:'Normal-1', remarks:'Fultala Bazar 6:30 PM — Via Shiromoni-Afil Gate-Pother Bazar'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1', remarks:'Shibbari 8:30 PM — Notun Rasta-Boira Bazar-Sonadanga-Gollamari-Nirala-Moylapota-Ferighat'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1', remarks:'Shibbari 7:30 PM — Powerhouse Mor-MoilaPota-Rupsha'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1(AC)', remarks:'Shibbari 6:30 PM — Back via Notun Rasta-Boira Bazar-Sonadanga-Shibbari-Sonadanga-Gollamari-Nirala'),
        const _ScheduleEntry(time:'05:10', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Special-1(AC)', remarks:'Shibbari 7:30 PM — Back go Rupsha via Power house mor-Moylapota'),
      ],
      'Night': [
        const _ScheduleEntry(time:'07:00', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-2', remarks:'Shibbari 9:00 PM — Started from KUET Mosque-Ferighat'),
        const _ScheduleEntry(time:'07:00', period:'PM', route:'Campus → Town', routeNo:6, busNo:'Normal-1', remarks:'Shibbari 8:30 PM — Via Notun Rasta-Sonadanga-Nirala-Moylapota-Ferighat'),
      ],
    };
  }

  final _activeBuses = [
    _ActiveBus(
      busNo: '04',
      driver: 'Drabir',
      route: 'Campus → Town',
      eta: '5 min',
      status: 'On route',
    ),
    _ActiveBus(
      busNo: '07',
      driver: 'Torsa',
      route: 'Campus → Phulbari',
      eta: '12 min',
      status: 'On route',
    ),
    _ActiveBus(
      busNo: '02',
      driver: 'Shetu',
      route: 'Town → Campus',
      eta: '2 min',
      status: 'Arriving',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _useRamadanSchedule = _isRamadan(today);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    _selectedDate = widget.initialDate != null
        ? DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          )
        : normalizedToday;
    final startDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).subtract(const Duration(days: 4));
    _today = DateTime(
      normalizedToday.year,
      normalizedToday.month,
      normalizedToday.day,
    );
    _recentDates = List.generate(
      5,
      (index) => startDate.add(Duration(days: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRouteLegend,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.route_rounded, size: 20),
        label: const Text(
          'Route Guide',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                    hintStyle: TextStyle(color: theme.subText, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.subText,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent dates',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _recentDates.length; i++) ...[
                            _buildRecentDateBadge(theme, _recentDates[i]),
                            if (i < _recentDates.length - 1)
                              const SizedBox(width: 10),
                          ],
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 84,
                            child: _buildCalendarButton(theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_weekdayLabels[_selectedDate.weekday - 1]}, ${_monthLabels[_selectedDate.month - 1]} ${_selectedDate.day}',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildScheduleToggle(theme),
            ),
            const SizedBox(height: 16),
            // Schedule list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _SectionHeader(title: 'Active buses'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activeBuses.length,
                      separatorBuilder: (_, spacingIndex) {
                        spacingIndex;
                        return const SizedBox(width: 12);
                      },
                      itemBuilder: (context, index) => _buildActiveBusCard(
                        AppThemeData.of(context),
                        _activeBuses[index],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_useRamadanSchedule)
                    _RamadanBanner(isDark: AppThemeData.of(context).isDark),
                  ...() {
                    final sections = _schedulesForDate(_selectedDate);
                    if (sections.isEmpty) {
                      return [_NoServiceCard(isDark: AppThemeData.of(context).isDark)];
                    }
                    final widgets = <Widget>[];
                    for (final entry in sections.entries) {
                      widgets.add(_SectionHeader(title: entry.key));
                      widgets.add(const SizedBox(height: 12));
                      for (final s in entry.value) {
                        widgets.add(_ScheduleCard(entry: s));
                      }
                      widgets.add(const SizedBox(height: 24));
                    }
                    return widgets;
                  }(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() => _selectedDate = normalized);
  }

  Widget _buildRecentDateBadge(AppThemeData theme, DateTime date) {
    final isSelected =
        _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    final label = _weekdayLabels[date.weekday - 1];
    final dayNumber = date.day.toString().padLeft(2, '0');
    final monthLabel = _monthLabels[date.month - 1];
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white70 : theme.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              monthLabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : theme.subText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBusCard(AppThemeData theme, _ActiveBus bus) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapScreen(
            busNo: bus.busNo,
            driver: bus.driver,
            route: bus.route,
            eta: bus.eta,
            status: bus.status,
          ),
        ),
      ),
      child: Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: theme.isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_bus, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus ${bus.busNo}',
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    bus.status,
                    style: TextStyle(
                      color: theme.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(bus.route, style: TextStyle(color: theme.subText, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Driver ${bus.driver}',
            style: TextStyle(color: theme.subText, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.access_time_filled, size: 16, color: theme.subText),
              const SizedBox(width: 4),
              Text(
                '${bus.eta} ETA',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showRouteLegend() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RouteLegendSheet(),
    );
  }

  Widget _buildScheduleToggle(AppThemeData theme) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: theme.surfaceDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useRamadanSchedule = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: !_useRamadanSchedule ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: !_useRamadanSchedule ? Colors.white : theme.subText,
                      ),
                      const SizedBox(width: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: !_useRamadanSchedule ? Colors.white : theme.subText,
                          fontSize: 13,
                          fontWeight: !_useRamadanSchedule ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: const Text('Normal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useRamadanSchedule = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: _useRamadanSchedule ? const Color(0xFF7C3626) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '☽',
                        style: TextStyle(
                          fontSize: 13,
                          color: _useRamadanSchedule ? Colors.white : theme.subText,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: _useRamadanSchedule ? Colors.white : theme.subText,
                          fontSize: 13,
                          fontWeight: _useRamadanSchedule ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: const Text('Ramadan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcademicCalendar() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AcademicCalendarPicker(initialDate: _selectedDate),
    );
    if (pickedDate != null) {
      _selectDate(pickedDate);
    }
  }

  void _revertToToday() {
    _selectDate(_today);
  }

  Widget _buildCalendarButton(AppThemeData theme) {
    final isTodaySelected =
        _selectedDate.year == _today.year &&
        _selectedDate.month == _today.month &&
        _selectedDate.day == _today.day;
    final detailText = isTodaySelected
        ? 'Academic calendar'
        : '${_weekdayLabels[_selectedDate.weekday - 1]} ${_selectedDate.day.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showAcademicCalendar,
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic calendar',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailText,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!isTodaySelected) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _revertToToday,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: theme.subText),
                  ),
                ),
              ],
            ],
          ),
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

class _RamadanBanner extends StatelessWidget {
  final bool isDark;
  const _RamadanBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B2D1F).withAlpha(isDark ? 60 : 30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B2D1F).withAlpha(120)),
      ),
      child: Row(
        children: [
          const Text('☽', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ramadan Schedule — Special timings are in effect',
              style: TextStyle(
                color: isDark ? const Color(0xFFE8A87C) : const Color(0xFF6B2D1F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoServiceCard extends StatelessWidget {
  final bool isDark;
  const _NoServiceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_bus_outlined, size: 48, color: theme.subText),
          const SizedBox(height: 16),
          Text(
            'No Service Today',
            style: TextStyle(
              color: theme.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KUET bus service is not available on Fridays.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.subText, fontSize: 13),
          ),
        ],
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Route ${widget.entry.routeNo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 13,
                      color: theme.subText,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.entry.busNo,
                        style: TextStyle(color: theme.subText, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.entry.remarks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.remarks,
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _alerted = !_alerted),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _alerted ? AppColors.primary : theme.surfaceDeep,
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

class _ActiveBus {
  final String busNo;
  final String driver;
  final String route;
  final String eta;
  final String status;

  const _ActiveBus({
    required this.busNo,
    required this.driver,
    required this.route,
    required this.eta,
    required this.status,
  });
}

class _AcademicCalendarPicker extends StatelessWidget {
  final DateTime initialDate;
  const _AcademicCalendarPicker({required this.initialDate});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final firstDate = DateTime(initialDate.year - 1, 1, 1);
    final lastDate = DateTime(initialDate.year + 1, 12, 31);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Academic calendar',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: theme.subText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Browse the KUET academic calendar and tap any date to jump to that day’s schedule.',
            style: TextStyle(color: theme.subText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          CalendarDatePicker(
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            onDateChanged: (value) => Navigator.of(context).pop(value),
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
  final int routeNo;
  final String busNo;
  final String remarks;

  const _ScheduleEntry({
    required this.time,
    required this.period,
    required this.route,
    required this.routeNo,
    required this.busNo,
    this.remarks = '',
  });
}

// ── Route legend ──────────────────────────────────────────────────────────────

class _RouteInfo {
  final int number;
  final String name;
  final String stop;

  const _RouteInfo({
    required this.number,
    required this.name,
    required this.stop,
  });
}

const _kCampusToTownRoutes = [
  _RouteInfo(number: 1, name: 'Khalishpur',  stop: 'Khalishpur'),
  _RouteInfo(number: 2, name: 'Shonadanga',  stop: 'Shonadanga'),
  _RouteInfo(number: 3, name: 'Phultola',    stop: 'Phultola / Fultala Bazar'),
  _RouteInfo(number: 4, name: 'Rupsha',      stop: 'Rupsha'),
  _RouteInfo(number: 5, name: 'Royel Mor',   stop: 'Royel Mor / Dakbangla'),
  _RouteInfo(number: 6, name: 'Shibbari',    stop: 'Shibbari / Ferighat'),
  _RouteInfo(number: 7, name: 'Gollamari',   stop: 'Gollamari'),
  _RouteInfo(number: 8, name: 'Moylapota',   stop: 'Moylapota'),
];

const _kTownToCampusRoutes = [
  _RouteInfo(number: 9,  name: 'Shibbari',   stop: 'Shibbari'),
  _RouteInfo(number: 10, name: 'Shonadanga', stop: 'Sonadanga'),
  _RouteInfo(number: 11, name: 'Phultola',   stop: 'Phultola'),
];

class _RouteLegendSheet extends StatelessWidget {
  const _RouteLegendSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final theme = AppThemeData.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
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
                'Route Guide',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'KUET bus routes and their corridors',
                style: TextStyle(color: theme.subText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _DirectionSection(
                label: 'Campus  \u2192  Town',
                icon: Icons.arrow_forward_rounded,
                routes: _kCampusToTownRoutes,
              ),
              const SizedBox(height: 16),
              _DirectionSection(
                label: 'Town  \u2192  Campus',
                icon: Icons.arrow_back_rounded,
                routes: _kTownToCampusRoutes,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _RouteRow extends StatelessWidget {
  final _RouteInfo route;
  const _RouteRow({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${route.number}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      route.stop,
                      style: TextStyle(color: theme.subText, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<_RouteInfo> routes;
  const _DirectionSection({
    required this.label,
    required this.icon,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...routes.map((r) => _RouteRow(route: r)),
      ],
    );
  }
}
