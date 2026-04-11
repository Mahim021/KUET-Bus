import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/geo_point.dart';

class RouteSelectionResult {
  final GeoPointData origin;
  final GeoPointData destination;
  final List<GeoPointData> coordinates;

  const RouteSelectionResult({
    required this.origin,
    required this.destination,
    required this.coordinates,
  });
}

class RoutePickerScreen extends StatefulWidget {
  final List<GeoPointData> initialCoordinates;

  const RoutePickerScreen({
    super.key,
    this.initialCoordinates = const [],
  });

  @override
  State<RoutePickerScreen> createState() => _RoutePickerScreenState();
}

class _RoutePickerScreenState extends State<RoutePickerScreen> {
  final _mapController = MapController();
  final List<_RoadFeature> _roads = [];
  final List<String> _selectedRoadIds = [];
  bool _hasUserEditedSelection = false;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoads();
  }

  Future<void> _loadRoads() async {
    try {
      final raw = await rootBundle.loadString('assets/khulna.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final features = decoded['features'] as List<dynamic>? ?? const [];

      final roads = <_RoadFeature>[];
      for (final item in features) {
        final map = item as Map<String, dynamic>;
        final geometry = map['geometry'] as Map<String, dynamic>?;
        if (geometry == null) {
          continue;
        }

        final type = geometry['type'] as String? ?? '';
        if (type != 'LineString') {
          continue;
        }

        final properties = map['properties'] as Map<String, dynamic>? ?? {};
        final wayId = (map['id'] ?? properties['@id'] ?? '').toString();
        if (!wayId.startsWith('way/')) {
          continue;
        }

        final coords = geometry['coordinates'];
        final points = _extractPoints(type, coords);
        if (points.length < 2) {
          continue;
        }

        final name =
            (properties['name'] ?? properties['highway'] ?? wayId).toString();

        roads.add(_RoadFeature(id: wayId, name: name, points: points));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _roads
          ..clear()
          ..addAll(roads);
        _selectedRoadIds
          ..clear()
          ..addAll(
              _matchRoadsFromCoordinates(roads, widget.initialCoordinates));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<LatLng> _extractPoints(String type, dynamic coordinates) {
    final points = <LatLng>[];
    try {
      switch (type) {
        case 'LineString':
          for (final pair in (coordinates as List<dynamic>)) {
            points.add(_toLatLng(pair as List<dynamic>));
          }
          break;
      }
    } catch (_) {
      return const [];
    }
    return points;
  }

  LatLng _toLatLng(List<dynamic> pair) {
    return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    if (_roads.isEmpty) {
      return;
    }

    _RoadFeature? nearest;
    var minDistance = double.infinity;

    for (final road in _roads) {
      final d = _minDistanceToRoadSegments(latLng, road);
      if (d < minDistance) {
        minDistance = d;
        nearest = road;
      }
    }

    if (nearest == null || minDistance > 35) {
      return;
    }

    setState(() {
      final id = nearest!.id;
      if (!_selectedRoadIds.contains(id)) {
        _selectedRoadIds.add(id);
        _hasUserEditedSelection = true;
      }
    });
  }

  List<LatLng> _initialPath() {
    return widget.initialCoordinates
        .map((e) => LatLng(e.lat, e.lng))
        .toList(growable: false);
  }

  List<LatLng> _displayPath() {
    final initialPath = _initialPath();
    if (!_hasUserEditedSelection && initialPath.length >= 2) {
      return initialPath;
    }
    return _selectedPath();
  }

  double _minDistanceToRoadSegments(LatLng tap, _RoadFeature road) {
    if (road.points.length < 2) {
      return double.infinity;
    }

    var min = double.infinity;
    for (var i = 0; i < road.points.length - 1; i++) {
      final d =
          _distanceToSegmentMeters(tap, road.points[i], road.points[i + 1]);
      if (d < min) {
        min = d;
      }
    }
    return min;
  }

  double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final pxy = _projectToLocalMeters(p, p.latitude);
    final axy = _projectToLocalMeters(a, p.latitude);
    final bxy = _projectToLocalMeters(b, p.latitude);

    final abx = bxy.dx - axy.dx;
    final aby = bxy.dy - axy.dy;
    final apx = pxy.dx - axy.dx;
    final apy = pxy.dy - axy.dy;

    final ab2 = (abx * abx) + (aby * aby);
    if (ab2 == 0) {
      return math.sqrt((apx * apx) + (apy * apy));
    }

    final t = ((apx * abx) + (apy * aby)) / ab2;
    final clampedT = t.clamp(0.0, 1.0);
    final cx = axy.dx + (abx * clampedT);
    final cy = axy.dy + (aby * clampedT);
    final dx = pxy.dx - cx;
    final dy = pxy.dy - cy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  Offset _projectToLocalMeters(LatLng p, double refLat) {
    const earthMetersPerDeg = 111320.0;
    final x =
        p.longitude * earthMetersPerDeg * math.cos(refLat * math.pi / 180);
    final y = p.latitude * 110540.0;
    return Offset(x, y);
  }

  List<LatLng> _selectedPath() {
    if (_selectedRoadIds.isEmpty) {
      return const [];
    }

    final byId = {for (final road in _roads) road.id: road};
    final selectedRoads = <_RoadFeature>[];
    for (final id in _selectedRoadIds) {
      final road = byId[id];
      if (road != null && road.points.length >= 2) {
        selectedRoads.add(road);
      }
    }

    if (selectedRoads.isEmpty) {
      return const [];
    }

    final orientedRoads = _bestOrientedRoadChain(selectedRoads);
    final path = <LatLng>[];

    for (final oriented in orientedRoads) {
      if (path.isEmpty) {
        path.addAll(oriented);
      } else if (_distanceToPointMeters(path.last, oriented.first) < 0.6) {
        path.addAll(oriented.skip(1));
      } else {
        path.addAll(oriented);
      }
    }

    return path;
  }

  List<List<LatLng>> _bestOrientedRoadChain(List<_RoadFeature> selectedRoads) {
    final n = selectedRoads.length;
    final variants = <List<List<LatLng>>>[];
    for (final road in selectedRoads) {
      variants.add([road.points, road.points.reversed.toList()]);
    }

    final dp = List.generate(n, (_) => List.filled(2, double.infinity));
    final parent = List.generate(n, (_) => List.filled(2, -1));

    dp[0][0] = 0;
    dp[0][1] = 0;

    for (var i = 1; i < n; i++) {
      for (var currOri = 0; currOri < 2; currOri++) {
        final currStart = variants[i][currOri].first;
        for (var prevOri = 0; prevOri < 2; prevOri++) {
          if (!dp[i - 1][prevOri].isFinite) {
            continue;
          }

          final prevEnd = variants[i - 1][prevOri].last;
          final joinCost = _distanceToPointMeters(prevEnd, currStart);
          final candidateCost = dp[i - 1][prevOri] + joinCost;

          if (candidateCost < dp[i][currOri]) {
            dp[i][currOri] = candidateCost;
            parent[i][currOri] = prevOri;
          }
        }
      }
    }

    var bestLastOri = dp[n - 1][0] <= dp[n - 1][1] ? 0 : 1;
    final chosen = List<int>.filled(n, 0);
    chosen[n - 1] = bestLastOri;

    for (var i = n - 1; i > 0; i--) {
      final prev = parent[i][chosen[i]];
      chosen[i - 1] = prev == -1 ? 0 : prev;
    }

    final oriented = <List<LatLng>>[];
    for (var i = 0; i < n; i++) {
      oriented.add(variants[i][chosen[i]]);
    }
    return oriented;
  }

  List<String> _matchRoadsFromCoordinates(
    List<_RoadFeature> roads,
    List<GeoPointData> initialCoordinates,
  ) {
    if (roads.isEmpty || initialCoordinates.length < 2) {
      return const [];
    }

    final points = initialCoordinates
        .map((e) => LatLng(e.lat, e.lng))
        .toList(growable: false);

    // Slightly generous tolerance to handle Firestore floating-point drift.
    const vertexToleranceMeters = 3.0;

    // For every road compute the FIRST and LAST index of saved points that
    // lie within tolerance of any of the road's vertices.  Gaps in the
    // middle are intentionally ignored — this prevents a single mismatched
    // point from truncating a long road's coverage.
    final intervals = <_RoadInterval>[];
    for (final road in roads) {
      int? first;
      var last = -1;
      for (var i = 0; i < points.length; i++) {
        final hit = road.points.any(
          (rp) =>
              _distanceToPointMeters(points[i], rp) <= vertexToleranceMeters,
        );
        if (hit) {
          first ??= i;
          last = i;
        }
      }
      // Require at least 2 distinct saved points on this road.
      if (first != null && last - first >= 1) {
        intervals.add(_RoadInterval(road: road, first: first, last: last));
      }
    }

    // Greedy "jump-game" interval cover.
    // At each step pick the road whose interval starts at/before the cursor
    // and extends the farthest.  A junction-only road covers just 1-2 shared
    // nodes and can never beat the road that covers the bulk of the path.
    final selected = <String>[];
    var cursor = 0;
    while (cursor < points.length - 1) {
      _RoadInterval? best;
      for (final iv in intervals) {
        if (selected.contains(iv.road.id)) continue;
        // Allow interval to start up to 1 point ahead (junction tolerance).
        if (iv.first > cursor + 1) continue;
        if (best == null || iv.last > best.last) best = iv;
      }
      if (best == null || best.last <= cursor) break;
      selected.add(best.road.id);
      cursor = best.last;
    }

    return selected;
  }

  double _distanceToPointMeters(LatLng a, LatLng b) {
    final ax = _projectToLocalMeters(a, a.latitude);
    final bx = _projectToLocalMeters(b, a.latitude);
    final dx = ax.dx - bx.dx;
    final dy = ax.dy - bx.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  void _confirmSelection() {
    final path = _displayPath();
    if (path.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 map points are required.')),
      );
      return;
    }

    final coordinates = path
        .map((e) => GeoPointData(lat: e.latitude, lng: e.longitude))
        .toList();

    Navigator.of(context).pop(
      RouteSelectionResult(
        origin:
            GeoPointData(lat: path.first.latitude, lng: path.first.longitude),
        destination:
            GeoPointData(lat: path.last.latitude, lng: path.last.longitude),
        coordinates: coordinates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewPath = _displayPath();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Route From Map'),
        actions: [
          IconButton(
            tooltip: 'Undo last',
            onPressed: _selectedRoadIds.isEmpty
                ? null
                : () => setState(() {
                      _selectedRoadIds.removeLast();
                      _hasUserEditedSelection = true;
                    }),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: _selectedRoadIds.isEmpty
                ? null
                : () => setState(() {
                      _selectedRoadIds.clear();
                      _hasUserEditedSelection = true;
                    }),
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load khulna.json: $_error'),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(22.84, 89.54),
                          initialZoom: 12.5,
                          minZoom: 10,
                          maxZoom: 18,
                          onTap: _handleMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.kuet.kuet_bus',
                            maxNativeZoom: 19,
                          ),
                          PolylineLayer(
                            polylines: [
                              ..._roads.map(
                                (e) => Polyline(
                                  points: e.points,
                                  color: _selectedRoadIds.contains(e.id)
                                      ? Colors.red
                                      : Colors.blueGrey.withValues(alpha: 0.35),
                                  strokeWidth:
                                      _selectedRoadIds.contains(e.id) ? 4 : 2,
                                ),
                              ),
                              if (previewPath.length >= 2)
                                Polyline(
                                  points: previewPath,
                                  color: Colors.deepOrange,
                                  strokeWidth: 5,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected ways: ${_selectedRoadIds.length}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _confirmSelection,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Confirm Selection'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RoadFeature {
  final String id;
  final String name;
  final List<LatLng> points;

  const _RoadFeature({
    required this.id,
    required this.name,
    required this.points,
  });
}

class _RoadInterval {
  final _RoadFeature road;
  final int first;
  final int last;

  const _RoadInterval({
    required this.road,
    required this.first,
    required this.last,
  });
}
