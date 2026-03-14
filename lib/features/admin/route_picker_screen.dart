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
      }
    });
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
    final path = <LatLng>[];

    for (final id in _selectedRoadIds) {
      final road = byId[id];
      if (road == null || road.points.isEmpty) {
        continue;
      }

      if (path.isEmpty) {
        path.addAll(road.points);
        continue;
      }

      final last = path.last;
      final firstDistance = _distanceToPointMeters(last, road.points.first);
      final lastDistance = _distanceToPointMeters(last, road.points.last);

      final oriented = firstDistance <= lastDistance
          ? road.points
          : road.points.reversed.toList();

      if (_distanceToPointMeters(path.last, oriented.first) < 0.6) {
        path.addAll(oriented.skip(1));
      } else {
        path.addAll(oriented);
      }
    }

    return path;
  }

  List<String> _matchRoadsFromCoordinates(
    List<_RoadFeature> roads,
    List<GeoPointData> initialCoordinates,
  ) {
    if (roads.isEmpty || initialCoordinates.length < 2) {
      return const [];
    }

    final remaining = initialCoordinates
        .map((e) => LatLng(e.lat, e.lng))
        .toList(growable: true);
    final selected = <String>[];

    while (remaining.length >= 2) {
      _RoadFeature? bestRoad;
      List<LatLng>? bestPoints;
      var bestScore = 0;

      for (final road in roads) {
        final directScore = _prefixMatchLength(remaining, road.points);
        final reversePoints = road.points.reversed.toList();
        final reverseScore = _prefixMatchLength(remaining, reversePoints);
        final score = directScore >= reverseScore ? directScore : reverseScore;
        final candidatePoints =
            directScore >= reverseScore ? road.points : reversePoints;

        if (score > bestScore) {
          bestScore = score;
          bestRoad = road;
          bestPoints = candidatePoints;
        }
      }

      if (bestRoad == null || bestPoints == null || bestScore < 2) {
        break;
      }

      selected.add(bestRoad.id);
      remaining.removeRange(0, bestScore - 1);
    }

    return selected;
  }

  int _prefixMatchLength(List<LatLng> source, List<LatLng> candidate) {
    final length = math.min(source.length, candidate.length);
    var count = 0;
    for (var index = 0; index < length; index++) {
      if (_distanceToPointMeters(source[index], candidate[index]) > 1.5) {
        break;
      }
      count++;
    }
    return count;
  }

  double _distanceToPointMeters(LatLng a, LatLng b) {
    final ax = _projectToLocalMeters(a, a.latitude);
    final bx = _projectToLocalMeters(b, a.latitude);
    final dx = ax.dx - bx.dx;
    final dy = ax.dy - bx.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  void _confirmSelection() {
    final path = _selectedPath();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Route From Map'),
        actions: [
          IconButton(
            tooltip: 'Undo last',
            onPressed: _selectedRoadIds.isEmpty
                ? null
                : () => setState(() => _selectedRoadIds.removeLast()),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: _selectedRoadIds.isEmpty
                ? null
                : () => setState(_selectedRoadIds.clear),
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
                              if (_selectedPath().length >= 2)
                                Polyline(
                                  points: _selectedPath(),
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
