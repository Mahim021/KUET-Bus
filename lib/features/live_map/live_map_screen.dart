import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/astar.dart';
import '../../../core/routing/geo_utils.dart';
import '../../../core/routing/road_network.dart';
import '../../../core/routing/road_network_loader.dart';
import '../../core/services/firestore_service.dart';
import '../../models/bus.dart';
import '../../models/bus_location.dart';
import '../../models/bus_route.dart';
import '../../models/bus_schedule.dart';

// ── Coordinates ───────────────────────────────────────────────────────────────
// KUET campus, Khulna, Bangladesh
const _kCampus = LatLng(22.9000, 89.5012);

// Simulated live bus position (midway on the Dakbangla → KUET corridor)
const _kInitialBus = LatLng(22.8720, 89.5210);

enum _TapSelectionStage { bus, student }

enum _TravelModeChoice { walking, easyBike, cng }

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveMapScreen extends StatefulWidget {
  final String busNo;
  final String driver;
  final String route;
  final String eta;
  final String status;
  final String? initialRouteId;

  const LiveMapScreen({
    super.key,
    this.busNo = '',
    this.driver = 'Unknown',
    this.route = '',
    this.eta = '--',
    this.status = 'On route',
    this.initialRouteId,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final _mapController = MapController();
  final _firestore = FirestoreService();
  StreamSubscription<List<BusLocation>>? _locationSub;
  StreamSubscription<Position>? _studentLocationSub;
  StreamSubscription<List<Bus>>? _busSub;
  StreamSubscription<List<BusSchedule>>? _scheduleSub;
  StreamSubscription<List<BusRoute>>? _routeSub;
  LatLng _busPosition = _kInitialBus;
  List<BusLocation> _liveLocations = const <BusLocation>[];
  final Map<String, BusLocation> _currentBusLocationById =
      <String, BusLocation>{};
  final Map<String, BusLocation> _previousBusLocationById =
      <String, BusLocation>{};
  Map<String, Bus> _busesById = const <String, Bus>{};
  Map<String, String> _busIdByNumberKey = const <String, String>{};
  Map<String, BusSchedule> _preferredScheduleByBusId =
      const <String, BusSchedule>{};
  Map<String, BusRoute> _routesById = const <String, BusRoute>{};
  String? _forcedRouteId;
  String? _selectedBusRef;
  List<LatLng> _selectedBusRoutePath = const <LatLng>[];
  LatLng? _studentPosition;
  LatLng? _studentDevicePosition;
  _PickupSuggestion? _pickupSuggestion;
  bool _pickupLoading = false;

  static const double _defaultBusSpeedMetersPerSec = 7.5;
  static const double _defaultStudentWalkMetersPerSec = 1.35;
  static const double _pickupBufferSec = 30;
  static const double _routeTapToleranceMeters = 80;
  static const Duration _busFreshThreshold = Duration(seconds: 45);
  bool _prototypeEnabled = false;
  bool _showPrototypeForm = true;
  bool _normalSuggestFlowStarted = false;
  _TapSelectionStage _tapSelectionStage = _TapSelectionStage.bus;
  LatLng? _prototypeBusPosition;
  double _busSpeedMetersPerSec = _defaultBusSpeedMetersPerSec;
  double _studentWalkMetersPerSec = _defaultStudentWalkMetersPerSec;
  _TravelModeChoice _travelModeChoice = _TravelModeChoice.walking;

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
    final busPoint = _effectiveBusPoint;
    if (busPoint != null) {
      _mapController.move(busPoint, 15.0);
      return;
    }
    _mapController.move(_busPosition, 15.0);
  }

  LatLng? get _effectiveBusPoint {
    if (_prototypeBusPosition != null) {
      return _prototypeBusPosition;
    }
    final selected = _selectedBusLocation;
    if (selected != null) {
      return LatLng(selected.position.lat, selected.position.lng);
    }
    return null;
  }

  LatLng? get _effectiveStudentPoint {
    if (_prototypeEnabled) {
      return _studentPosition;
    }
    return _studentDevicePosition;
  }

  double get _normalStudentSpeedMetersPerSec {
    switch (_travelModeChoice) {
      case _TravelModeChoice.walking:
        return 4.0 / 3.6;
      case _TravelModeChoice.easyBike:
        return 18.0 / 3.6;
      case _TravelModeChoice.cng:
        return 25.0 / 3.6;
    }
  }

  bool _isFreshBusLocation(BusLocation location) {
    final updatedAt = location.updatedAt;
    if (updatedAt == null) {
      return false;
    }
    return DateTime.now().difference(updatedAt) <= _busFreshThreshold;
  }

  double? _selectedBusVelocityMetersPerSec() {
    final selectedRef = _selectedBusRef;
    if (selectedRef == null || selectedRef.isEmpty) {
      return null;
    }
    final current = _currentBusLocationById[selectedRef];
    final previous = _previousBusLocationById[selectedRef];
    if (current == null || previous == null) {
      return null;
    }
    if (!_isFreshBusLocation(current)) {
      return null;
    }
    final currentUpdatedAt = current.updatedAt;
    final previousUpdatedAt = previous.updatedAt;
    if (currentUpdatedAt == null || previousUpdatedAt == null) {
      return null;
    }
    final deltaSeconds =
        currentUpdatedAt.difference(previousUpdatedAt).inMilliseconds / 1000.0;
    if (deltaSeconds <= 0) {
      return null;
    }
    final distanceMeters = haversineMeters(
      previous.position.lat,
      previous.position.lng,
      current.position.lat,
      current.position.lng,
    );
    return distanceMeters / deltaSeconds;
  }

  (LatLng point, double distanceMeters)? _snapToRoutePath(
    LatLng tap,
    List<LatLng> path,
  ) {
    if (path.length < 2) {
      return null;
    }

    final latScale = 111320.0;
    final lngScale = 111320.0 *
        math.cos(tap.latitude * math.pi / 180.0).abs().clamp(0.1, 1.0);

    double toX(LatLng p) => (p.longitude - tap.longitude) * lngScale;
    double toY(LatLng p) => (p.latitude - tap.latitude) * latScale;

    LatLng? bestPoint;
    var bestDistance = double.infinity;

    for (var i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];

      final ax = toX(a);
      final ay = toY(a);
      final bx = toX(b);
      final by = toY(b);

      final abx = bx - ax;
      final aby = by - ay;
      final ab2 = (abx * abx) + (aby * aby);
      if (ab2 <= 0) {
        continue;
      }

      final t = ((-ax * abx) + (-ay * aby)) / ab2;
      final clampedT = t.clamp(0.0, 1.0);

      final px = ax + (abx * clampedT);
      final py = ay + (aby * clampedT);
      final d = math.sqrt(px * px + py * py);
      if (d < bestDistance) {
        bestDistance = d;
        bestPoint = LatLng(
          a.latitude + (b.latitude - a.latitude) * clampedT,
          a.longitude + (b.longitude - a.longitude) * clampedT,
        );
      }
    }

    if (bestPoint == null) {
      return null;
    }
    return (bestPoint, bestDistance);
  }

  String _normalizeBusKey(String raw) {
    return raw.trim().toLowerCase();
  }

  String _todayLabel() {
    const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[DateTime.now().weekday - 1];
  }

  String? _resolveBusDocId(String busRef) {
    final byId = _busesById[busRef];
    if (byId != null && byId.id != null && byId.id!.isNotEmpty) {
      return byId.id;
    }
    return _busIdByNumberKey[_normalizeBusKey(busRef)];
  }

  Bus? _busFromRef(String busRef) {
    final byId = _busesById[busRef];
    if (byId != null) {
      return byId;
    }
    final docId = _resolveBusDocId(busRef);
    if (docId == null) {
      return null;
    }
    return _busesById[docId];
  }

  BusLocation? get _selectedBusLocation {
    final selected = _selectedBusRef;
    if (selected == null || selected.isEmpty) {
      return null;
    }
    for (final location in _liveLocations) {
      if (location.busId == selected) {
        return location;
      }
    }
    return null;
  }

  void _refreshSelectedBusState() {
    if (_forcedRouteId != null && _forcedRouteId!.isNotEmpty) {
      final route = _routesById[_forcedRouteId!];
      if (route == null) {
        _selectedBusRoutePath = const <LatLng>[];
        return;
      }

      if (route.coordinates.isNotEmpty) {
        _selectedBusRoutePath = route.coordinates
            .map((point) => LatLng(point.lat, point.lng))
            .toList(growable: false);
      } else {
        _selectedBusRoutePath = <LatLng>[
          LatLng(route.origin.lat, route.origin.lng),
          LatLng(route.destination.lat, route.destination.lng),
        ];
      }

      _busPosition = LatLng(route.origin.lat, route.origin.lng);
      return;
    }

    final current = _selectedBusRef;
    final hasCurrent = current != null &&
        _liveLocations.any((location) => location.busId == current);

    if (!hasCurrent) {
      _selectedBusRef =
          _liveLocations.isEmpty ? null : _liveLocations.first.busId;
    }

    final selectedRef = _selectedBusRef;
    if (selectedRef == null || selectedRef.isEmpty) {
      _selectedBusRoutePath = const <LatLng>[];
      return;
    }

    final selectedLocation = _selectedBusLocation;
    if (selectedLocation != null) {
      _busPosition = LatLng(
        selectedLocation.position.lat,
        selectedLocation.position.lng,
      );
    }

    final busDocId = _resolveBusDocId(selectedRef);
    if (busDocId == null || busDocId.isEmpty) {
      _selectedBusRoutePath = const <LatLng>[];
      return;
    }

    final schedule = _preferredScheduleByBusId[busDocId];
    if (schedule == null || schedule.routeId.isEmpty) {
      _selectedBusRoutePath = const <LatLng>[];
      return;
    }

    final route = _routesById[schedule.routeId];
    if (route == null) {
      _selectedBusRoutePath = const <LatLng>[];
      return;
    }

    if (route.coordinates.isNotEmpty) {
      _selectedBusRoutePath = route.coordinates
          .map((point) => LatLng(point.lat, point.lng))
          .toList(growable: false);
      return;
    }

    _selectedBusRoutePath = <LatLng>[
      LatLng(route.origin.lat, route.origin.lng),
      LatLng(route.destination.lat, route.destination.lng),
    ];
  }

  void _selectBus(String busRef) {
    setState(() {
      _selectedBusRef = busRef;
      _refreshSelectedBusState();
    });
    unawaited(_recomputePickupSuggestion());
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
      final d =
          haversineMeters(tap.latitude, tap.longitude, node.lat, node.lng);
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
      if (!_prototypeEnabled) {
        return;
      }
      if (_tapSelectionStage == _TapSelectionStage.bus) {
        final snapped = _snapToRoutePath(latLng, _selectedBusRoutePath);
        if (snapped == null || snapped.$2 > _routeTapToleranceMeters) {
          return;
        }

        await HapticFeedback.selectionClick();
        setState(() {
          _prototypeBusPosition = snapped.$1;
          _tapSelectionStage = _TapSelectionStage.student;
          _pickupSuggestion = null;
        });
        await _recomputePickupSuggestion();
        return;
      }

      await HapticFeedback.selectionClick();
      setState(() {
        _studentPosition = latLng;
        _pickupSuggestion = null;
      });
      await _recomputePickupSuggestion();
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

  Future<void> _handleMapLongPress(
    TapPosition tapPosition,
    LatLng latLng,
  ) async {
    return;
  }

  List<int> _routeNodeIdsFromPath(List<LatLng> path, RoadNetwork network) {
    final snapped = <int>[];
    for (final point in path) {
      final nodeId = _snapToNearestNode(point, network).$1;
      if (snapped.isEmpty || snapped.last != nodeId) {
        snapped.add(nodeId);
      }
    }
    if (snapped.length <= 1) {
      return snapped;
    }

    // Rebuild the full route with A* between consecutive route waypoints
    // so bus-time estimation follows drivable road segments.
    final expanded = <int>[snapped.first];
    for (var i = 1; i < snapped.length; i++) {
      final from = snapped[i - 1];
      final to = snapped[i];
      if (from == to) {
        continue;
      }

      final segment = aStarPathfinding(from, to, network).path;
      if (segment == null || segment.isEmpty) {
        if (expanded.last != to) {
          expanded.add(to);
        }
        continue;
      }

      for (var k = 1; k < segment.length; k++) {
        final id = segment[k];
        if (expanded.last != id) {
          expanded.add(id);
        }
      }
    }
    return expanded;
  }

  int _nearestIndexOnRouteNodes(
    LatLng point,
    List<int> routeNodeIds,
    RoadNetwork network,
  ) {
    var bestIndex = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < routeNodeIds.length; i++) {
      final node = network.nodes[routeNodeIds[i]];
      final d =
          haversineMeters(point.latitude, point.longitude, node.lat, node.lng);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  double _neighborDistanceMeters(RoadNetwork network, int aId, int bId) {
    final a = network.nodes[aId];
    for (final neighbor in a.neighbors) {
      if (neighbor.nodeId == bId) {
        return neighbor.distanceMeters;
      }
    }

    // Fallback for asymmetric edge lists.
    final b = network.nodes[bId];
    for (final neighbor in b.neighbors) {
      if (neighbor.nodeId == aId) {
        return neighbor.distanceMeters;
      }
    }

    return haversineMeters(a.lat, a.lng, b.lat, b.lng);
  }

  double _distanceAlongRouteNodes(
    List<int> routeNodeIds,
    int fromIndex,
    int toIndex,
    RoadNetwork network,
  ) {
    if (toIndex <= fromIndex) {
      return 0;
    }
    var distance = 0.0;
    for (var i = fromIndex; i < toIndex; i++) {
      distance += _neighborDistanceMeters(
          network, routeNodeIds[i], routeNodeIds[i + 1]);
    }
    return distance;
  }

  List<LatLng> _busPathToCandidate(
    LatLng busPoint,
    List<int> routeNodeIds,
    int fromIndex,
    int toIndex,
    RoadNetwork network,
  ) {
    final points = <LatLng>[busPoint];
    for (var i = fromIndex; i <= toIndex; i++) {
      final node = network.nodes[routeNodeIds[i]];
      points.add(LatLng(node.lat, node.lng));
    }
    return points;
  }

  Future<void> _initializeStudentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _studentDevicePosition = LatLng(current.latitude, current.longitude);
      });

      _studentLocationSub?.cancel();
      _studentLocationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          _studentDevicePosition =
              LatLng(position.latitude, position.longitude);
        });
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _recomputePickupSuggestion() async {
    if (_routeMode || !mounted) {
      return;
    }

    final student = _effectiveStudentPoint;
    final selectedLocation = _selectedBusLocation;
    final busPoint = _effectiveBusPoint;
    final busSpeedMetersPerSec = _prototypeEnabled
        ? _busSpeedMetersPerSec
        : _selectedBusVelocityMetersPerSec();
    final studentSpeedMetersPerSec = _prototypeEnabled
        ? _studentWalkMetersPerSec
        : _normalStudentSpeedMetersPerSec;
    final busIsMoving = _prototypeEnabled
        ? busPoint != null
        : selectedLocation != null &&
            _isFreshBusLocation(selectedLocation) &&
            busSpeedMetersPerSec != null;
    if (student == null || busPoint == null || !busIsMoving) {
      if (mounted) {
        setState(() {
          _pickupSuggestion = null;
          _pickupLoading = false;
        });
      }
      return;
    }

    if (_selectedBusRoutePath.length < 2) {
      setState(() {
        _pickupSuggestion = null;
        _pickupLoading = false;
      });
      return;
    }

    setState(() {
      _pickupLoading = true;
    });

    await _ensureRoadNetworkLoaded();
    final network = _roadNetwork;
    if (network == null || !mounted) {
      setState(() {
        _pickupSuggestion = null;
        _pickupLoading = false;
      });
      return;
    }

    final studentNodeId = _snapToNearestNode(student, network).$1;
    final busNodeId = _snapToNearestNode(busPoint, network).$1;
    final routeNodeIds = _routeNodeIdsFromPath(_selectedBusRoutePath, network);

    if (routeNodeIds.length < 3) {
      setState(() {
        _pickupSuggestion = null;
        _pickupLoading = false;
      });
      return;
    }

    final busRouteIndex =
        _nearestIndexOnRouteNodes(busPoint, routeNodeIds, network);
    final seenCandidates = <int>{};
    _PickupSuggestion? best;

    for (var i = busRouteIndex + 1; i < routeNodeIds.length; i++) {
      final candidateId = routeNodeIds[i];
      if (!seenCandidates.add(candidateId)) {
        continue;
      }

      final candidateNode = network.nodes[candidateId];
      if (candidateNode.neighbors.length < 3) {
        continue;
      }

      final busDistance = haversineMeters(
            busPoint.latitude,
            busPoint.longitude,
            network.nodes[busNodeId].lat,
            network.nodes[busNodeId].lng,
          ) +
          _distanceAlongRouteNodes(routeNodeIds, busRouteIndex, i, network);

      final busTimeSec = busDistance / busSpeedMetersPerSec!;
      if (!busTimeSec.isFinite || busTimeSec <= 0) {
        continue;
      }

      final studentResult =
          aStarPathfinding(studentNodeId, candidateId, network);
      if (studentResult.path == null || studentResult.path!.isEmpty) {
        continue;
      }

      final studentTimeSec =
          studentResult.distanceMeters / studentSpeedMetersPerSec;
      if (studentTimeSec + _pickupBufferSec >= busTimeSec) {
        continue;
      }

      final pathPoints = studentResult.path!
          .map((id) => LatLng(network.nodes[id].lat, network.nodes[id].lng))
          .toList(growable: false);

      final suggestion = _PickupSuggestion(
        point: LatLng(candidateNode.lat, candidateNode.lng),
        busPath: _busPathToCandidate(
          busPoint,
          routeNodeIds,
          busRouteIndex,
          i,
          network,
        ),
        studentPath: pathPoints,
        busDistanceMeters: busDistance,
        studentDistanceMeters: studentResult.distanceMeters,
        busTimeSec: busTimeSec,
        studentTimeSec: studentTimeSec,
      );

      if (best == null ||
          suggestion.studentDistanceMeters < best.studentDistanceMeters ||
          (suggestion.studentDistanceMeters == best.studentDistanceMeters &&
              suggestion.busTimeSec < best.busTimeSec)) {
        best = suggestion;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _pickupSuggestion = best;
      _pickupLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    final routeId = widget.initialRouteId?.trim() ?? '';
    _forcedRouteId = routeId.isEmpty ? null : routeId;

    _locationSub = _firestore.watchBusLocations().listen((locations) {
      if (!mounted) {
        return;
      }
      setState(() {
        for (final location in locations) {
          final previous = _currentBusLocationById[location.busId];
          if (previous != null) {
            _previousBusLocationById[location.busId] = previous;
          }
          _currentBusLocationById[location.busId] = location;
        }
        _liveLocations = locations;
        _refreshSelectedBusState();
      });
      if (_prototypeEnabled) {
        unawaited(_recomputePickupSuggestion());
      }
    });

    _busSub = _firestore.watchBuses().listen((buses) {
      if (!mounted) {
        return;
      }

      final byId = <String, Bus>{};
      final byNumber = <String, String>{};
      for (final bus in buses) {
        final id = bus.id;
        if (id == null || id.isEmpty) {
          continue;
        }
        byId[id] = bus;
        final key = _normalizeBusKey(bus.busNumber);
        if (key.isNotEmpty) {
          byNumber[key] = id;
        }
      }

      setState(() {
        _busesById = byId;
        _busIdByNumberKey = byNumber;
        _refreshSelectedBusState();
      });
      if (_prototypeEnabled) {
        unawaited(_recomputePickupSuggestion());
      }
    });

    _scheduleSub = _firestore.watchSchedules().listen((schedules) {
      if (!mounted) {
        return;
      }

      final preferred = <String, BusSchedule>{};
      final scoreByBus = <String, int>{};
      final today = _todayLabel();

      for (final schedule in schedules) {
        if (!schedule.isActive || schedule.busId.trim().isEmpty) {
          continue;
        }
        final score = schedule.daysOfWeek.contains(today) ? 2 : 1;
        final previousScore = scoreByBus[schedule.busId] ?? -1;
        if (score > previousScore) {
          scoreByBus[schedule.busId] = score;
          preferred[schedule.busId] = schedule;
        }
      }

      setState(() {
        _preferredScheduleByBusId = preferred;
        _refreshSelectedBusState();
      });
      if (_prototypeEnabled) {
        unawaited(_recomputePickupSuggestion());
      }
    });

    _routeSub = _firestore.watchRoutes().listen((routes) {
      if (!mounted) {
        return;
      }

      final byId = <String, BusRoute>{};
      for (final route in routes) {
        final id = route.id;
        if (id == null || id.isEmpty) {
          continue;
        }
        byId[id] = route;
      }

      setState(() {
        _routesById = byId;
        _refreshSelectedBusState();
      });
      if (_prototypeEnabled) {
        unawaited(_recomputePickupSuggestion());
      }
    });

    unawaited(_initializeStudentLocation());
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _studentLocationSub?.cancel();
    _busSub?.cancel();
    _scheduleSub?.cancel();
    _routeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    final availableRoutes = _routesById.values
        .where((route) => route.id != null && route.id!.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) {
        final left = a.routeName.trim().toLowerCase();
        final right = b.routeName.trim().toLowerCase();
        return left.compareTo(right);
      });
    final selectedRouteId = availableRoutes.any((r) => r.id == _forcedRouteId)
        ? _forcedRouteId
        : null;

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
              onLongPress: _handleMapLongPress,
            ),
            children: [
              // OSM tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuet.kuet_bus',
                maxNativeZoom: 19,
              ),

              if (_startPoint != null &&
                  _endPoint != null &&
                  _routePath.isEmpty)
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

              if (!_routeMode &&
                  _pickupSuggestion != null &&
                  _pickupSuggestion!.busPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _pickupSuggestion!.busPath,
                      color: const Color(0xCC2563EB),
                      strokeWidth: 4,
                    ),
                  ],
                ),

              if (!_routeMode &&
                  _pickupSuggestion != null &&
                  _pickupSuggestion!.studentPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _pickupSuggestion!.studentPath,
                      color: const Color(0xCC16A34A),
                      strokeWidth: 4,
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
                  if (!_routeMode && _prototypeBusPosition != null)
                    Marker(
                      point: _prototypeBusPosition!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child:
                          const _RoutePin(color: Color(0xFF2563EB), label: 'B'),
                    ),
                  ..._liveLocations.map((location) {
                    final busRef = location.busId;
                    final bus = _busFromRef(busRef);
                    final busLabel = (bus?.busName.trim().isNotEmpty ?? false)
                        ? bus!.busName.trim()
                        : (bus?.busNumber.trim().isNotEmpty ?? false)
                            ? bus!.busNumber.trim()
                            : busRef;
                    return Marker(
                      point:
                          LatLng(location.position.lat, location.position.lng),
                      width: 94,
                      height: 76,
                      child: GestureDetector(
                        onTap: () => _selectBus(busRef),
                        child: _BusMapMarker(
                          label: busLabel,
                          isSelected: busRef == _selectedBusRef,
                          gpsEnabled: bus?.hasGpsService ?? true,
                        ),
                      ),
                    );
                  }),
                  if (!_routeMode && _effectiveStudentPoint != null)
                    Marker(
                      point: _effectiveStudentPoint!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child:
                          const _RoutePin(color: Color(0xFF16A34A), label: 'S'),
                    ),
                  if (!_routeMode && _pickupSuggestion != null)
                    Marker(
                      point: _pickupSuggestion!.point,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child:
                          const _RoutePin(color: Color(0xFFF59E0B), label: 'P'),
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
                        child: const _RoutePin(
                            color: Color(0xFFEF4444), label: 'S'),
                      ),
                    if (_endPoint != null)
                      Marker(
                        point: _endPoint!,
                        width: 44,
                        height: 44,
                        child: const _RoutePin(
                            color: Color(0xFF3B82F6), label: 'D'),
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
                    background: _routeMode ? AppColors.primary : theme.surface,
                    iconColor: _routeMode ? Colors.white : theme.text,
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: _prototypeEnabled
                        ? 'Disable prototype mode'
                        : 'Enable prototype mode',
                    child: _NavButton(
                      icon: Icons.science_outlined,
                      onTap: () {
                        var enabled = false;
                        setState(() {
                          _prototypeEnabled = !_prototypeEnabled;
                          enabled = _prototypeEnabled;
                          _showPrototypeForm = true;
                          if (!_prototypeEnabled) {
                            _tapSelectionStage = _TapSelectionStage.bus;
                            _prototypeBusPosition = null;
                            _studentPosition = null;
                            _pickupSuggestion = null;
                            _pickupLoading = false;
                          }
                        });
                        if (enabled) {
                          unawaited(_recomputePickupSuggestion());
                        }
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              enabled
                                  ? 'Prototype mode enabled'
                                  : 'Prototype mode disabled',
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                      background:
                          _prototypeEnabled ? AppColors.primary : theme.surface,
                      iconColor: _prototypeEnabled ? Colors.white : theme.text,
                    ),
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

          if (!_routeMode && !_prototypeEnabled)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _normalSuggestFlowStarted
                    ? _LiveControlCard(
                        theme: theme,
                        showTravelModeInput: _normalSuggestFlowStarted,
                        travelModeChoice: _travelModeChoice,
                        onTravelModeChanged: (mode) {
                          setState(() {
                            _travelModeChoice = mode;
                          });
                          unawaited(_recomputePickupSuggestion());
                        },
                        onSuggestPressed: () {
                          setState(() {
                            _normalSuggestFlowStarted = true;
                            _forcedRouteId = null;
                            _pickupSuggestion = null;
                            _pickupLoading = false;
                            _refreshSelectedBusState();
                          });
                          unawaited(_recomputePickupSuggestion());
                        },
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _normalSuggestFlowStarted = true;
                                _forcedRouteId = null;
                                _pickupSuggestion = null;
                                _pickupLoading = false;
                                _refreshSelectedBusState();
                              });
                              unawaited(_recomputePickupSuggestion());
                            },
                            icon: const Icon(Icons.alt_route_rounded, size: 16),
                            label: const Text('Suggest route'),
                          ),
                        ),
                      ),
              ),
            )
          else if (!_routeMode && _prototypeEnabled)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              _showPrototypeForm = !_showPrototypeForm;
                            });
                          },
                          icon: Icon(
                            _showPrototypeForm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _showPrototypeForm ? 'Hide form' : 'Show form',
                          ),
                        ),
                      ),
                    ),
                    if (_showPrototypeForm)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PrototypeControlCard(
                          theme: theme,
                          selectionStage: _tapSelectionStage,
                          hasBusPoint: _prototypeBusPosition != null,
                          hasStudentPoint: _studentPosition != null,
                          availableRoutes: availableRoutes,
                          selectedRouteId: selectedRouteId,
                          busSpeedMetersPerSec: _busSpeedMetersPerSec,
                          studentSpeedMetersPerSec: _studentWalkMetersPerSec,
                          onRouteChanged: (routeId) {
                            setState(() {
                              _forcedRouteId = routeId;
                              _tapSelectionStage = _TapSelectionStage.bus;
                              _prototypeBusPosition = null;
                              _studentPosition = null;
                              _pickupSuggestion = null;
                              _refreshSelectedBusState();
                            });
                            unawaited(_recomputePickupSuggestion());
                          },
                          onResetSelection: () {
                            setState(() {
                              _tapSelectionStage = _TapSelectionStage.bus;
                              _prototypeBusPosition = null;
                              _studentPosition = null;
                              _pickupSuggestion = null;
                            });
                            unawaited(_recomputePickupSuggestion());
                          },
                          onBusSpeedChanged: (value) {
                            setState(() {
                              _busSpeedMetersPerSec = value;
                              _pickupSuggestion = null;
                            });
                            unawaited(_recomputePickupSuggestion());
                          },
                          onStudentSpeedChanged: (value) {
                            setState(() {
                              _studentWalkMetersPerSec = value;
                              _pickupSuggestion = null;
                            });
                            unawaited(_recomputePickupSuggestion());
                          },
                        ),
                      ),
                    if (_studentPosition != null ||
                        _pickupSuggestion != null ||
                        _pickupLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PickupSuggestionCard(
                          theme: theme,
                          loading: _pickupLoading,
                          suggestion: _pickupSuggestion,
                        ),
                      ),
                  ],
                ),
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
  final String label;
  final bool isSelected;
  final bool gpsEnabled;

  const _BusMapMarker({
    required this.label,
    required this.isSelected,
    required this.gpsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor =
        gpsEnabled ? AppColors.primary : const Color(0xFF6B7280);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
              width: 3,
            ),
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
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _PickupSuggestion {
  final LatLng point;
  final List<LatLng> busPath;
  final List<LatLng> studentPath;
  final double busDistanceMeters;
  final double studentDistanceMeters;
  final double busTimeSec;
  final double studentTimeSec;

  const _PickupSuggestion({
    required this.point,
    required this.busPath,
    required this.studentPath,
    required this.busDistanceMeters,
    required this.studentDistanceMeters,
    required this.busTimeSec,
    required this.studentTimeSec,
  });
}

class _PrototypeControlCard extends StatelessWidget {
  final AppThemeData theme;
  final _TapSelectionStage selectionStage;
  final bool hasBusPoint;
  final bool hasStudentPoint;
  final List<BusRoute> availableRoutes;
  final String? selectedRouteId;
  final double busSpeedMetersPerSec;
  final double studentSpeedMetersPerSec;
  final ValueChanged<String?> onRouteChanged;
  final VoidCallback onResetSelection;
  final ValueChanged<double> onBusSpeedChanged;
  final ValueChanged<double> onStudentSpeedChanged;

  const _PrototypeControlCard({
    required this.theme,
    required this.selectionStage,
    required this.hasBusPoint,
    required this.hasStudentPoint,
    required this.availableRoutes,
    required this.selectedRouteId,
    required this.busSpeedMetersPerSec,
    required this.studentSpeedMetersPerSec,
    required this.onRouteChanged,
    required this.onResetSelection,
    required this.onBusSpeedChanged,
    required this.onStudentSpeedChanged,
  });

  String _fmtSpeed(double metersPerSec) {
    final kmh = metersPerSec * 3.6;
    return '${metersPerSec.toStringAsFixed(1)} m/s (${kmh.toStringAsFixed(1)} km/h)';
  }

  @override
  Widget build(BuildContext context) {
    final stageText = selectionStage == _TapSelectionStage.bus
        ? 'Tap route to set bus point'
        : hasStudentPoint
            ? 'Tap map to update student point'
            : 'Tap map to set student point';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stageText,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onResetSelection,
                child: const Text('Reset'),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(selectedRouteId),
            initialValue: selectedRouteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Route',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Auto (selected bus schedule)'),
              ),
              ...availableRoutes.map(
                (route) => DropdownMenuItem<String>(
                  value: route.id,
                  child: Text(
                    route.routeName.trim().isEmpty
                        ? (route.id ?? 'Unknown route')
                        : route.routeName.trim(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onRouteChanged,
          ),
          const SizedBox(height: 2),
          Text(
            'Bus speed: ${_fmtSpeed(busSpeedMetersPerSec)}',
            style: TextStyle(
              color: theme.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: busSpeedMetersPerSec,
            min: 1.0,
            max: 20.0,
            divisions: 190,
            label: busSpeedMetersPerSec.toStringAsFixed(1),
            onChanged: onBusSpeedChanged,
          ),
          Text(
            'Student speed: ${_fmtSpeed(studentSpeedMetersPerSec)}',
            style: TextStyle(
              color: theme.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: studentSpeedMetersPerSec,
            min: 1.0,
            max: 20.0,
            divisions: 190,
            label: studentSpeedMetersPerSec.toStringAsFixed(1),
            onChanged: onStudentSpeedChanged,
          ),
        ],
      ),
    );
  }
}

class _LiveControlCard extends StatelessWidget {
  final AppThemeData theme;
  final bool showTravelModeInput;
  final _TravelModeChoice travelModeChoice;
  final ValueChanged<_TravelModeChoice> onTravelModeChanged;
  final VoidCallback onSuggestPressed;

  const _LiveControlCard({
    required this.theme,
    required this.showTravelModeInput,
    required this.travelModeChoice,
    required this.onTravelModeChanged,
    required this.onSuggestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Normal mode',
            style: TextStyle(
              color: theme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (showTravelModeInput)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<_TravelModeChoice>(
                key: ValueKey(travelModeChoice),
                initialValue: travelModeChoice,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Travel mode',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: _TravelModeChoice.walking,
                    child: Text('Walking (4 km/h)'),
                  ),
                  DropdownMenuItem(
                    value: _TravelModeChoice.easyBike,
                    child: Text('Easy bike (18 km/h)'),
                  ),
                  DropdownMenuItem(
                    value: _TravelModeChoice.cng,
                    child: Text('CNG (25 km/h)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onTravelModeChanged(value);
                  }
                },
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSuggestPressed,
              icon: const Icon(Icons.alt_route_rounded, size: 16),
              label: const Text('Suggest route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupSuggestionCard extends StatelessWidget {
  final AppThemeData theme;
  final bool loading;
  final _PickupSuggestion? suggestion;

  const _PickupSuggestionCard({
    required this.theme,
    required this.loading,
    required this.suggestion,
  });

  String _fmtEta(double sec) {
    if (!sec.isFinite || sec < 0) {
      return '--';
    }
    final minutes = (sec / 60).round();
    return '${minutes <= 0 ? 1 : minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    if (loading) {
      title = 'Finding best pickup point...';
      subtitle = 'Checking forward intersections on bus route';
    } else if (suggestion == null) {
      title = 'No feasible pickup point found yet';
      subtitle = 'Set student + bus points and make sure a route is selected';
    } else {
      title = 'Suggested pickup point is ready';
      subtitle =
          'You: ${_fmtEta(suggestion!.studentTimeSec)} | Bus: ${_fmtEta(suggestion!.busTimeSec)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x1A16A34A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.route_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
