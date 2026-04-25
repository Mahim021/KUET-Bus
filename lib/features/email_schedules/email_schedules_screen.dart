import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class EmailSchedulesScreen extends StatelessWidget {
  const EmailSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Center(
                child: Text(
                  'Schedule',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestore.watchEmailSchedules(limit: 50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !(snapshot.hasData)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Failed to load email schedules.',
                          style: TextStyle(color: theme.subText),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No email schedule found yet.',
                          style: TextStyle(color: theme.subText),
                        ),
                      ),
                    );
                  }

                  // Show only the latest update in a static layout.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    child: _EmailScheduleCard(data: docs.first),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailScheduleCard extends StatelessWidget {
  const _EmailScheduleCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final schedule = _asMap(data['schedule']);
    final morning = _asListOfMap(schedule['morning']);
    final noon = _asListOfMap(schedule['noon']);
    final evening = _asListOfMap(schedule['afternoon_evening']);
    final lastUpdateRaw = _asString(data['extractedAt']).isNotEmpty
        ? _asString(data['extractedAt'])
        : _asString(data['receivedAt']);
    final dateText = _asString(data['date']).isEmpty
        ? 'Unknown date'
        : _asString(data['date']);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText,
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Last update: ${_formatDateTime(lastUpdateRaw)}',
            style: TextStyle(color: theme.subText, fontSize: 12, height: 1.25),
          ),
          const SizedBox(height: 8),
          _Section(title: 'Morning', trips: morning),
          const SizedBox(height: 10),
          _Section(title: 'Noon', trips: noon),
          const SizedBox(height: 10),
          _Section(title: 'Afternoon / Evening', trips: evening),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.trips});

  final String title;
  final List<Map<String, dynamic>> trips;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${trips.length})',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        if (trips.isEmpty)
          Text(
            'No trips',
            style: TextStyle(color: theme.subText, fontSize: 12),
          )
        else
          Column(
            children: trips
                .map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TripCard(trip: trip),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _asString(trip['trip_name']).isEmpty
                ? 'Trip'
                : _asString(trip['trip_name']),
            style: TextStyle(
              color: theme.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          _infoLine(
              context, 'Campus Departure', _asString(trip['campus_departure'])),
          const SizedBox(height: 4),
          _infoLine(
              context, 'Boarding Place & Time', _asString(trip['boarding'])),
          const SizedBox(height: 4),
          _infoLine(context, 'Route', _asString(trip['route'])),
        ],
      ),
    );
  }
}

Widget _infoLine(BuildContext context, String label, String value) {
  final theme = AppThemeData.of(context);
  final shown = value.isEmpty ? '-' : value;
  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: TextStyle(
            color: theme.text,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        TextSpan(
          text: shown,
          style: TextStyle(
            color: theme.subText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    ),
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
