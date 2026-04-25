import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus_route.dart';
import '../schedule/route_view_screen.dart';

class EmailSchedulesScreen extends StatefulWidget {
  const EmailSchedulesScreen({super.key});

  @override
  State<EmailSchedulesScreen> createState() => _EmailSchedulesScreenState();
}

class _EmailSchedulesScreenState extends State<EmailSchedulesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestore.watchEmailSchedules(limit: 50),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !(snapshot.hasData)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load schedule.',
                  style: TextStyle(color: theme.subText),
                ),
              );
            }

            final docs = snapshot.data ?? const <Map<String, dynamic>>[];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No schedule update found.',
                  style: TextStyle(color: theme.subText),
                ),
              );
            }

            final latest = docs.first;
            final schedule = _asMap(latest['schedule']);
            final morning = _asListOfMap(schedule['morning']);
            final noon = _asListOfMap(schedule['noon']);
            final evening = _asListOfMap(schedule['afternoon_evening']);
            final query = _searchController.text.trim().toLowerCase();

            final filteredMorning = _filterTrips(morning, query);
            final filteredNoon = _filterTrips(noon, query);
            final filteredEvening = _filterTrips(evening, query);

            final lastUpdateRaw = _asString(latest['extractedAt']).isNotEmpty
                ? _asString(latest['extractedAt'])
                : _asString(latest['receivedAt']);
            final scheduleDate = _parseScheduleDate(
              _asString(latest['date']),
              _asString(latest['receivedAt']),
            );

            return StreamBuilder<List<BusRoute>>(
              stream: firestore.watchRoutes(),
              builder: (context, routeSnap) {
                final routes = routeSnap.data ?? const <BusRoute>[];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Schedule',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Last update: ${_formatDateTime(lastUpdateRaw)}',
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SearchBar(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _DayOfWeekStrip(date: scheduleDate),
                      const SizedBox(height: 16),
                      _Section(
                        title: 'Morning Departures',
                        trips: filteredMorning,
                        routes: routes,
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        title: 'Noon Departures',
                        trips: filteredNoon,
                        routes: routes,
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        title: 'Afternoon / Evening',
                        trips: filteredEvening,
                        routes: routes,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DayOfWeekStrip extends StatelessWidget {
  const _DayOfWeekStrip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final days = _buildWeekDays(date);
    final selectedBg =
        theme.isDark ? Colors.white : const Color(0xFF5C0B0D); // inverse
    final selectedText =
        theme.isDark ? const Color(0xFF5C0B0D) : Colors.white; // inverse

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((d) {
          final isSelected =
              d.year == date.year && d.month == date.month && d.day == date.day;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 74,
              height: 90,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : theme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? (theme.isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF5C0B0D))
                      : theme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayShort(d.weekday),
                    style: TextStyle(
                      color: isSelected ? selectedText : theme.subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: isSelected ? selectedText : theme.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: theme.text, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search route or trip...',
          hintStyle: TextStyle(color: theme.subText, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: theme.subText),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.trips,
    required this.routes,
  });

  final String title;
  final List<Map<String, dynamic>> trips;
  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (trips.isEmpty)
          Text(
            'No trips',
            style: TextStyle(color: theme.subText, fontSize: 13),
          )
        else
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TripCard(trip: trip, routes: routes),
            ),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.routes});

  final Map<String, dynamic> trip;
  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final tripName = _asString(trip['trip_name']);
    final departure = _asString(trip['campus_departure']);
    final boarding = _asString(trip['boarding']);
    final route = _asString(trip['route']);
    final effectiveRoute = _effectiveRoute(boarding, route);
    final routeTitle = _routeTitle(effectiveRoute, tripName);
    final matchedRoute = _matchRouteByTitle(routeTitle, effectiveRoute, routes);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openRouteMapFromCard(
          context,
          matchedRoute,
          routeTitle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5C0B0D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _compactTime(departure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Departure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2E6E6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeTitle,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trip: ${tripName.isEmpty ? '-' : tripName}',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Boarding: ${boarding.isEmpty ? '-' : boarding}',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showFullRouteDialog(context, effectiveRoute),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.surfaceDeep,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.chevron_right_rounded, color: theme.subText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _filterTrips(
    List<Map<String, dynamic>> trips, String q) {
  if (q.isEmpty) return trips;
  return trips.where((trip) {
    final text = <String>[
      _asString(trip['trip_name']),
      _asString(trip['campus_departure']),
      _asString(trip['boarding']),
      _asString(trip['route']),
    ].join(' ').toLowerCase();
    return text.contains(q);
  }).toList();
}

String _compactTime(String value) {
  if (value.trim().isEmpty) return '--';
  final compact = value.replaceAll('মিঃ', '').trim();
  if (compact.length <= 16) return compact;
  return '${compact.substring(0, 16)}...';
}

DateTime _parseScheduleDate(String dateText, String fallbackIso) {
  final byDate = DateTime.tryParse(dateText);
  if (byDate != null) return byDate;
  final byFallback = DateTime.tryParse(fallbackIso);
  if (byFallback != null) return byFallback;
  return DateTime.now();
}

List<DateTime> _buildWeekDays(DateTime selected) {
  final monday = selected.subtract(Duration(days: selected.weekday - 1));
  return List<DateTime>.generate(
    7,
    (i) => DateTime(monday.year, monday.month, monday.day + i),
  );
}

String _weekdayShort(int weekday) {
  const labels = <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  if (weekday < 1 || weekday > 7) return 'DAY';
  return labels[weekday - 1];
}

String _effectiveRoute(String boarding, String route) {
  final b = boarding.trim();
  final r = route.trim();
  if (b.isEmpty && r.isEmpty) return '';
  if (b.isEmpty) return r;
  if (r.isEmpty) return b;
  return '$b $r';
}

String _routeTitle(String route, String fallbackTrip) {
  final orderedRules = <MapEntry<String, String>>[
    const MapEntry('সোনাডাঙ্গা', 'Sonadanga'),
    const MapEntry('ফুলতলা', 'Fultala'),
    const MapEntry('আলমনগর', 'Alamnagar'),
    const MapEntry('রূপসা', 'Rupsha'),
    const MapEntry('ডাকবাংলা', 'Dakbangla'),
    const MapEntry('শিববাড়ি', 'Shibbari'),
    const MapEntry('শিববাড়ী', 'Shibbari'),
  ];

  for (final rule in orderedRules) {
    if (route.contains(rule.key)) {
      return rule.value;
    }
  }

  if (fallbackTrip.trim().isNotEmpty) return fallbackTrip;
  if (route.trim().isNotEmpty) return route;
  return 'Trip';
}

BusRoute? _matchRouteByTitle(
  String title,
  String effectiveRoute,
  List<BusRoute> routes,
) {
  if (routes.isEmpty) return null;
  final t = title.trim().toLowerCase();
  final e = effectiveRoute.trim().toLowerCase();

  for (final r in routes) {
    final rn = r.routeName.trim().toLowerCase();
    if (t.isNotEmpty && rn.contains(t)) return r;
  }

  for (final r in routes) {
    final rn = r.routeName.trim().toLowerCase();
    if (e.isNotEmpty && (e.contains(rn) || rn.contains(e.split(' ').first))) {
      return r;
    }
  }

  return null;
}

void _openRouteMapFromCard(
  BuildContext context,
  BusRoute? route,
  String scheduleTitle,
) {
  if (route == null || route.id == null || route.id!.trim().isEmpty) {
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
        scheduleTitle: scheduleTitle,
      ),
    ),
  );
}

void _showFullRouteDialog(BuildContext context, String route) {
  final shown = route.trim().isEmpty ? 'No route text found.' : route.trim();
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = AppThemeData.of(context);
      return AlertDialog(
        title: const Text('Full Route'),
        content: SingleChildScrollView(
          child: Text(
            shown,
            style: TextStyle(
              color: theme.text,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asListOfMap(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map((e) => _asMap(e)).toList();
}

String _asString(dynamic value) => value == null ? '' : value.toString();

String _formatDateTime(String value) {
  if (value.trim().isEmpty) return '-';
  final dt = DateTime.tryParse(value);
  if (dt == null) return value;
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
