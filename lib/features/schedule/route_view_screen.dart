import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bus_route.dart';

class RouteViewScreen extends StatelessWidget {
  final BusRoute route;
  final String? scheduleTitle;

  const RouteViewScreen({
    super.key,
    required this.route,
    this.scheduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final List<LatLng> path = _routePath(route);
    final LatLng start = path.first;
    final LatLng end = path.last;
    final LatLng center = LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              route.routeName.trim().isEmpty ? 'Route View' : route.routeName,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (scheduleTitle != null && scheduleTitle!.trim().isNotEmpty)
              Text(
                'Schedule: ${scheduleTitle!.trim()}',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.text),
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              minZoom: 9,
              maxZoom: 19,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuet.kuet_bus',
                maxNativeZoom: 19,
              ),
              PolylineLayer(
                polylines: <Polyline>[
                  Polyline(
                    points: path,
                    color: const Color(0xCC2563EB),
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: start,
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: const _StartDot(),
                  ),
                  Marker(
                    point: end,
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: const _DestinationMarker(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<LatLng> _routePath(BusRoute route) {
    if (route.coordinates.isNotEmpty) {
      return route.coordinates
          .map((point) => LatLng(point.lat, point.lng))
          .toList(growable: false);
    }

    return <LatLng>[
      LatLng(route.origin.lat, route.origin.lng),
      LatLng(route.destination.lat, route.destination.lng),
    ];
  }
}

class _StartDot extends StatelessWidget {
  const _StartDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.place_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
