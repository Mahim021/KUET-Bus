import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/bus_schedule.dart';
import 'route_view_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;
  const ScheduleScreen({super.key, this.initialDate});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

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
          children: <Widget>[
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: theme.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search day, time, bus, route...',
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
            const SizedBox(height: 14),
            Expanded(child: _buildScheduleList()),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return StreamBuilder<List<BusSchedule>>(
      stream: _firestore.watchSchedules(),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<BusSchedule>> scheduleSnapshot,
      ) {
        return StreamBuilder<List<Bus>>(
          stream: _firestore.watchBuses(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Bus>> busSnapshot) {
            return StreamBuilder<List<BusRoute>>(
              stream: _firestore.watchRoutes(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<BusRoute>> routeSnapshot,
              ) {
                final bool isLoading = scheduleSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    busSnapshot.connectionState == ConnectionState.waiting ||
                    routeSnapshot.connectionState == ConnectionState.waiting;

                if (isLoading &&
                    !scheduleSnapshot.hasData &&
                    !busSnapshot.hasData &&
                    !routeSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (scheduleSnapshot.hasError) {
                  return const _ErrorCard(
                    message: 'Failed to load schedules from Firestore.',
                  );
                }
                if (busSnapshot.hasError) {
                  return const _ErrorCard(
                    message: 'Failed to load buses from Firestore.',
                  );
                }
                if (routeSnapshot.hasError) {
                  return const _ErrorCard(
                    message: 'Failed to load routes from Firestore.',
                  );
                }

                final List<BusSchedule> schedules =
                    scheduleSnapshot.data ?? const <BusSchedule>[];
                final List<Bus> buses = busSnapshot.data ?? const <Bus>[];
                final List<BusRoute> routes =
                    routeSnapshot.data ?? const <BusRoute>[];

                final Map<String, String> busLabelById = <String, String>{
                  for (final Bus bus in buses)
                    if (bus.id != null && bus.id!.isNotEmpty)
                      bus.id!: _busLabel(bus),
                };

                final Map<String, BusRoute> routeById = <String, BusRoute>{
                  for (final BusRoute route in routes)
                    if (route.id != null && route.id!.isNotEmpty)
                      route.id!: route,
                };

                final String query =
                    _searchController.text.trim().toLowerCase();

                final List<BusSchedule> filtered =
                    schedules.where((BusSchedule schedule) {
                  final BusRoute? route = routeById[schedule.routeId];
                  final String routeLabel = _routeLabel(route);
                  final String busLabel =
                      busLabelById[schedule.busId] ?? 'Unknown Bus';
                  final String dayIndex = _daysForSearch(schedule.daysOfWeek);

                  final String haystack = <String>[
                    schedule.time,
                    schedule.period,
                    routeLabel,
                    busLabel,
                    schedule.daysOfWeek.join(' '),
                    dayIndex,
                    schedule.isActive ? 'active yes' : 'active no',
                  ].join(' ').toLowerCase();

                  return query.isEmpty || haystack.contains(query);
                }).toList()
                      ..sort((BusSchedule a, BusSchedule b) {
                        final int aMinutes = _toMinutes(a.time, a.period);
                        final int bMinutes = _toMinutes(b.time, b.period);
                        return aMinutes.compareTo(bMinutes);
                      });

                if (filtered.isEmpty) {
                  return const _EmptyScheduleCard();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final BusSchedule schedule = filtered[index];
                    final BusRoute? route = routeById[schedule.routeId];
                    final String routeLabel = _routeLabel(route);
                    final String busLabel =
                        busLabelById[schedule.busId] ?? 'Unknown Bus';

                    return _FirestoreScheduleCard(
                      title: '${schedule.time} ${schedule.period}',
                      routeLabel: routeLabel,
                      busLabel: busLabel,
                      daysText: schedule.daysOfWeek.join(', '),
                      isActive: schedule.isActive,
                      onTap: () => _openScheduleRouteOnMap(schedule, route),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _busLabel(Bus bus) {
    final String name = bus.busName.trim();
    final String number = bus.busNumber.trim();
    if (name.isNotEmpty) {
      return name;
    }
    if (number.isNotEmpty) {
      return number;
    }
    return 'Unknown Bus';
  }

  String _routeLabel(BusRoute? route) {
    final String label = route?.routeName.trim() ?? '';
    if (label.isNotEmpty) {
      return label;
    }
    return 'Unknown Route';
  }

  String _daysForSearch(List<String> days) {
    final List<String> expanded = <String>[];
    for (final String day in days) {
      final String d = day.trim().toLowerCase();
      if (d.isEmpty) {
        continue;
      }
      expanded.add(d);
      switch (d) {
        case 'sun':
          expanded.add('sunday');
          break;
        case 'mon':
          expanded.add('monday');
          break;
        case 'tue':
          expanded.add('tuesday');
          break;
        case 'wed':
          expanded.add('wednesday');
          break;
        case 'thu':
          expanded.add('thursday');
          break;
        case 'fri':
          expanded.add('friday');
          break;
        case 'sat':
          expanded.add('saturday');
          break;
      }
    }
    return expanded.join(' ');
  }

  int _toMinutes(String time, String period) {
    final Match? match =
        RegExp(r'^\s*(\d{1,2})\s*:\s*(\d{1,2})\s*$').firstMatch(time);
    if (match == null) {
      return 9999;
    }

    int hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;

    final String p = period.trim().toUpperCase();
    if (p == 'PM' && hour < 12) {
      hour += 12;
    }
    if (p == 'AM' && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  void _openScheduleRouteOnMap(BusSchedule schedule, BusRoute? route) {
    if (route == null || route.id == null || route.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route map not found for this schedule.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteViewScreen(
          route: route,
          scheduleTitle: '${schedule.time} ${schedule.period}',
        ),
      ),
    );
  }
}

class _FirestoreScheduleCard extends StatelessWidget {
  final String title;
  final String routeLabel;
  final String busLabel;
  final String daysText;
  final bool isActive;
  final VoidCallback onTap;

  const _FirestoreScheduleCard({
    required this.title,
    required this.routeLabel,
    required this.busLabel,
    required this.daysText,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Route: $routeLabel',
              style: TextStyle(color: theme.subText, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Bus: $busLabel',
              style: TextStyle(color: theme.subText, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Days: $daysText',
              style: TextStyle(color: theme.subText, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Active: ${isActive ? 'Yes' : 'No'}',
              style: TextStyle(
                color: isActive ? theme.primaryAccent : theme.subText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.event_busy_rounded, color: theme.subText, size: 36),
              const SizedBox(height: 12),
              Text(
                'No schedules found',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No matching Firestore schedules found for your search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.subText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.text, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
