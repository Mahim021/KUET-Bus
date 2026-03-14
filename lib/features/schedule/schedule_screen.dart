import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/bus_schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0;
  final _searchController = TextEditingController();
  final _firestore = FirestoreService();

  final _days = ['MON\n12', 'TUE\n13', 'WED\n14', 'THU\n15', 'FRI\n16'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

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
                    hintStyle: TextStyle(color: theme.subText, fontSize: 14),
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
                        color: isSelected ? AppColors.primary : theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            isSelected ? null : Border.all(color: theme.border),
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
                              color:
                                  isSelected ? Colors.white70 : theme.subText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parts[1],
                            style: TextStyle(
                              color: isSelected ? Colors.white : theme.text,
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
              child: StreamBuilder<List<BusSchedule>>(
                stream: _firestore.watchSchedules(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading schedules: ${snapshot.error}',
                        style: TextStyle(color: theme.subText),
                      ),
                    );
                  }

                  final schedules = snapshot.data ?? const <BusSchedule>[];
                  return StreamBuilder<List<Bus>>(
                    stream: _firestore.watchBuses(),
                    builder: (context, busSnapshot) {
                      final buses = busSnapshot.data ?? const <Bus>[];
                      final busNameById = <String, String>{};
                      for (final bus in buses) {
                        final id = bus.id;
                        if (id == null || id.isEmpty) {
                          continue;
                        }
                        final label = bus.busName.trim().isNotEmpty
                            ? bus.busName.trim()
                            : bus.busNumber.trim();
                        if (label.isNotEmpty) {
                          busNameById[id] = label;
                        }
                      }

                      return StreamBuilder<List<BusRoute>>(
                        stream: _firestore.watchRoutes(),
                        builder: (context, routeSnapshot) {
                          final routes =
                              routeSnapshot.data ?? const <BusRoute>[];
                          final routeNameById = <String, String>{};
                          for (final route in routes) {
                            final id = route.id;
                            if (id == null || id.isEmpty) {
                              continue;
                            }
                            final label = route.routeName.trim();
                            if (label.isNotEmpty) {
                              routeNameById[id] = label;
                            }
                          }

                          final query =
                              _searchController.text.trim().toLowerCase();
                          final entries =
                              schedules.map((schedule) => _ScheduleEntry(
                                    time: schedule.time,
                                    period: schedule.period,
                                    route: routeNameById[schedule.routeId] ??
                                        schedule.routeId,
                                    busNo: busNameById[schedule.busId] ??
                                        schedule.busId,
                                  ))
                                  .where((entry) {
                            if (query.isEmpty) {
                              return true;
                            }
                            return entry.route.toLowerCase().contains(query) ||
                                entry.busNo.toLowerCase().contains(query);
                          }).toList();

                          final morning =
                              entries.where((e) => e.period == 'AM').toList();
                          final afternoon =
                              entries.where((e) => e.period == 'PM').toList();

                          if (entries.isEmpty) {
                            return Center(
                              child: Text(
                                'No schedules available',
                                style: TextStyle(
                                    color: theme.subText, fontSize: 15),
                              ),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _SectionHeader(title: 'Morning Departures'),
                              const SizedBox(height: 12),
                              ...morning.map((s) => _ScheduleCard(entry: s)),
                              const SizedBox(height: 24),
                              _SectionHeader(title: 'Afternoon Departures'),
                              const SizedBox(height: 12),
                              ...afternoon.map((s) => _ScheduleCard(entry: s)),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Note: schedule entries are built in the StreamBuilder so we can map IDs
  // to their display names (busName/routeName) while still falling back to IDs.
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
                      'Bus: ${widget.entry.busNo}',
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
