import 'dart:async';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/astar.dart';
import '../../../core/routing/geo_utils.dart';
import '../../../core/routing/road_network.dart';
import '../../../core/routing/road_network_loader.dart';
import '../../core/services/firestore_service.dart';
import '../../models/bus_location.dart';

// ── Coordinates ───────────────────────────────────────────────────────────────
// KUET campus, Khulna, Bangladesh
const _kCampus = LatLng(22.9000, 89.5012);

// Simulated live bus position (midway on the Dakbangla → KUET corridor)
const _kInitialBus = LatLng(22.8720, 89.5210);

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveMapScreen extends StatefulWidget {
  final String busNo;
  final String driver;
  final String route;
  final String eta;
  final String status;

  const LiveMapScreen({
    super.key,
    this.busNo = '',
    this.driver = 'Unknown',
    this.route = '',
    this.eta = '--',
    this.status = 'On route',
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _mapController = MapController();
  final _firestore = FirestoreService();
  StreamSubscription<List<BusLocation>>? _locationSub;
  LatLng _busPosition = _kInitialBus;

  // A* demo state (prototype, used until hardware GPS is ready)
  bool _routeMode = false;
  bool _networkLoading = false;
  String? _networkError;
  RoadNetwork? _roadNetwork;

  int? _startNodeId;
  int? _endNodeId;
  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _routePath = const <LatLng>[];
  AStarResult? _lastRouteResult;

  /// Call this method to update the bus position from a real-time source
  /// (e.g., Firebase Realtime DB, WebSocket, etc.)
  void updateBusPosition(LatLng position) {
    setState(() => _busPosition = position);
    _mapController.move(_busPosition, _mapController.camera.zoom);
  }

  void _centerOnBus() {
    _mapController.move(_busPosition, 15.0);
  }

  Future<void> _ensureRoadNetworkLoaded() async {
    if (_roadNetwork != null || _networkLoading) {
      return;
    }
    setState(() {
      _networkLoading = true;
      _networkError = null;
    });
    try {
      final network = await RoadNetworkLoader.loadKhulnaNetwork();
      if (!mounted) return;
      setState(() {
        _roadNetwork = network;
        _networkLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _networkLoading = false;
        _networkError = e.toString();
      });
    }
  }

  void _clearRouteSelection() {
    setState(() {
      _startNodeId = null;
      _endNodeId = null;
      _startPoint = null;
      _endPoint = null;
      _routePath = const <LatLng>[];
      _lastRouteResult = null;
    });
  }

  Future<void> _toggleRouteMode() async {
    final next = !_routeMode;
    setState(() => _routeMode = next);
    _clearRouteSelection();
    if (next) {
      await _ensureRoadNetworkLoaded();
    }
  }

  (int nodeId, LatLng point, double meters) _snapToNearestNode(
    LatLng tap,
    RoadNetwork network,
  ) {
    var bestId = 0;
    var bestDist = double.infinity;

    for (final node in network.nodes) {
      final d = haversineMeters(tap.latitude, tap.longitude, node.lat, node.lng);
      if (d < bestDist) {
        bestDist = d;
        bestId = node.id;
      }
    }

    final bestNode = network.nodes[bestId];
    return (bestId, LatLng(bestNode.lat, bestNode.lng), bestDist);
  }

  Future<void> _handleMapTap(TapPosition tapPosition, LatLng latLng) async {
    if (!_routeMode) {
      return;
    }

    if (_roadNetwork == null) {
      await _ensureRoadNetworkLoaded();
      if (_roadNetwork == null) {
        return;
      }
    }

    final network = _roadNetwork!;
    final snapped = _snapToNearestNode(latLng, network);

    await HapticFeedback.selectionClick();

    if (_startNodeId == null) {
      setState(() {
        _startNodeId = snapped.$1;
        _startPoint = snapped.$2;
        _routePath = const <LatLng>[];
        _lastRouteResult = null;
      });
      return;
    }

    if (_endNodeId == null) {
      final startId = _startNodeId!;
      final endId = snapped.$1;
      setState(() {
        _endNodeId = endId;
        _endPoint = snapped.$2;
      });

      final result = aStarPathfinding(startId, endId, network);
      final path = result.path;
      final points = path == null
          ? const <LatLng>[]
          : path
              .map((id) => LatLng(network.nodes[id].lat, network.nodes[id].lng))
              .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _lastRouteResult = result;
        _routePath = points;
      });
      return;
    }

    // Third tap: reset and start a new route.
    _clearRouteSelection();
    setState(() {
      _startNodeId = snapped.$1;
      _startPoint = snapped.$2;
    });
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
              onTap: _handleMapTap,
            ),
            children: [
              // OSM tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuet.kuet_bus',
                maxNativeZoom: 19,
              ),

              if (_startPoint != null && _endPoint != null && _routePath.isEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_startPoint!, _endPoint!],
                      color: const Color(0xCCEF4444),
                      strokeWidth: 4,
                    ),
                  ],
                ),

              if (_routePath.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePath,
                      color: const Color(0xFF22C55E),
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

              if (_startPoint != null || _endPoint != null)
                MarkerLayer(
                  markers: [
                    if (_startPoint != null)
                      Marker(
                        point: _startPoint!,
                        width: 44,
                        height: 44,
                        child: const _RoutePin(color: Color(0xFFEF4444), label: 'S'),
                      ),
                    if (_endPoint != null)
                      Marker(
                        point: _endPoint!,
                        width: 44,
                        height: 44,
                        child: const _RoutePin(color: Color(0xFF3B82F6), label: 'D'),
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
                          if (!_routeMode) _LiveDot(),
                          if (_routeMode)
                            const Icon(Icons.alt_route_rounded,
                                size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            _routeMode ? 'A* Routing' : 'Live Tracking',
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
                    icon: _routeMode
                        ? Icons.close_rounded
                        : Icons.alt_route_rounded,
                    onTap: _toggleRouteMode,
                    background:
                        _routeMode ? AppColors.primary : theme.surface,
                    iconColor: _routeMode ? Colors.white : theme.text,
                  ),
                  const SizedBox(width: 10),
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

          if (_routeMode)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: _RouteStatusBanner(
                theme: theme,
                loading: _networkLoading,
                error: _networkError,
                startSet: _startPoint != null,
                endSet: _endPoint != null,
                result: _lastRouteResult,
                onClear: _clearRouteSelection,
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

class _RoutePin extends StatelessWidget {
  final Color color;
  final String label;

  const _RoutePin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RouteStatusBanner extends StatelessWidget {
  final AppThemeData theme;
  final bool loading;
  final String? error;
  final bool startSet;
  final bool endSet;
  final AStarResult? result;
  final VoidCallback onClear;

  const _RouteStatusBanner({
    required this.theme,
    required this.loading,
    required this.error,
    required this.startSet,
    required this.endSet,
    required this.result,
    required this.onClear,
  });

  String _fmtMeters(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final hasPath = r?.path != null && (r?.path?.isNotEmpty ?? false);

    String headline;
    String subline;

    if (loading) {
      headline = 'Loading road network...';
      subline = 'Please wait';
    } else if (error != null) {
      headline = 'Failed to load roads';
      subline = error!;
    } else if (!startSet) {
      headline = 'Tap to set start point';
      subline = 'We will snap to the nearest road node';
    } else if (!endSet) {
      headline = 'Tap to set destination';
      subline = 'Running A* after you pick the second point';
    } else if (!hasPath) {
      headline = 'No path found';
      subline = 'Try selecting points closer to connected roads';
    } else {
      headline = 'Shortest path found';
      subline =
          '${_fmtMeters(r!.distanceMeters)} • explored ${r.nodesExplored} nodes • ${r.elapsedMs.toStringAsFixed(0)} ms';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: loading ? theme.surfaceDeep : theme.navActivePill,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.alt_route_rounded,
                    size: 18,
                    color: theme.navActive,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (startSet || endSet)
            _NavButton(
              icon: Icons.delete_outline_rounded,
              onTap: onClear,
              background: theme.surfaceDeep,
              iconColor: theme.text,
            ),
        ],
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

// Hardcoded bus detail UI removed. We'll reintroduce a dynamic version later
// once bus metadata (name/driver/ETA) is available from the backend.
