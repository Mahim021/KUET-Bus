import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../../models/bus_location.dart';

// ── Coordinates ───────────────────────────────────────────────────────────────
// KUET campus, Khulna, Bangladesh
const _kCampus = LatLng(22.9000, 89.5012);

// Simulated live bus position (midway on the Dakbangla → KUET corridor)
const _kInitialBus = LatLng(22.8720, 89.5210);

// Approximate road route: Dakbangla → KUET campus
const _kRoute = [
  LatLng(22.8454, 89.5403), // Dakbangla (origin)
  LatLng(22.8560, 89.5320),
  LatLng(22.8650, 89.5255),
  LatLng(22.8720, 89.5210), // ← bus is here
  LatLng(22.8820, 89.5130),
  LatLng(22.8920, 89.5070),
  LatLng(22.9000, 89.5012), // KUET campus
];

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _mapController = MapController();
  final _firestore = FirestoreService();
  StreamSubscription<List<BusLocation>>? _locationSub;
  LatLng _busPosition = _kInitialBus;
  bool _showDetails = true;

  /// Call this method to update the bus position from a real-time source
  /// (e.g., Firebase Realtime DB, WebSocket, etc.)
  void updateBusPosition(LatLng position) {
    setState(() => _busPosition = position);
    _mapController.move(_busPosition, _mapController.camera.zoom);
  }

  void _centerOnBus() {
    _mapController.move(_busPosition, 15.0);
  }

  @override
  void initState() {
    super.initState();
    _locationSub = _firestore.watchBusLocations().listen((locations) {
      if (!mounted || locations.isEmpty) {
        return;
      }
      final latest = locations.first;
      final newPos = LatLng(latest.position.lat, latest.position.lng);
      setState(() => _busPosition = newPos);
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // ── Real OpenStreetMap ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busPosition,
              initialZoom: 14.5,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              // OSM tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuet.kuet_bus',
                maxNativeZoom: 19,
              ),

              // Route line: travelled (grey) + upcoming (maroon)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _kRoute.sublist(0, 4),
                    color: Color(0x80808080),
                    strokeWidth: 5,
                  ),
                  Polyline(
                    points: _kRoute.sublist(3),
                    color: Color(0xD93B0D0D),
                    strokeWidth: 5,
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Campus destination
                  Marker(
                    point: _kCampus,
                    width: 52,
                    height: 58,
                    alignment: Alignment.topCenter,
                    child: const _DestinationMarker(),
                  ),
                  // Live bus
                  Marker(
                    point: _busPosition,
                    width: 60,
                    height: 60,
                    child: const _BusMapMarker(),
                  ),
                ],
              ),
            ],
          ),

          // ── Top overlay ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                    background: theme.surface,
                    iconColor: theme.text,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.surface.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LiveDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Live Tracking',
                            style: TextStyle(
                              color: theme.primaryAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _NavButton(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnBus,
                    background: AppColors.primary,
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom bus details sheet ────────────────────────────────────
          if (_showDetails)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BusDetailsSheet(
                onClose: () => setState(() => _showDetails = false),
              ),
            ),

          // ── Re-open button when sheet is dismissed ──────────────────────
          if (!_showDetails)
            Positioned(
              bottom: 96,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'bus_info',
                onPressed: () => setState(() => _showDetails = true),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.directions_bus_rounded, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Animated live dot ─────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x664CAF50),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Map markers ───────────────────────────────────────────────────────────────

class _BusMapMarker extends StatelessWidget {
  const _BusMapMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x663B0D0D),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x551B5E20),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF1B5E20),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.background = Colors.white,
    this.iconColor = const Color(0xFF374151),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

// ── Bus details bottom sheet ──────────────────────────────────────────────────

class _BusDetailsSheet extends StatelessWidget {
  final VoidCallback onClose;

  const _BusDetailsSheet({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bus Details',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: Icon(Icons.close_rounded,
                          color: theme.subText, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.surfaceDeep,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 36, color: theme.subText),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUS: DAKBANGLA',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 14, color: theme.subText),
                              const SizedBox(width: 4),
                              Text(
                                'Driver: Ahmed Ali',
                                style: TextStyle(
                                    color: theme.subText, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: theme.subText),
                              const SizedBox(width: 4),
                              Text(
                                'En route → KUET Campus',
                                style: TextStyle(
                                    color: theme.subText, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '8 min',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'TO CAMPUS',
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon:
                            const Icon(Icons.notifications_outlined, size: 18),
                        label: const Text('Alert'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.text,
                          side: BorderSide(color: theme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Call Driver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
