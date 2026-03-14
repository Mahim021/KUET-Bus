import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'geo_utils.dart';
import 'road_network.dart';

class RoadNetworkLoader {
  RoadNetworkLoader._();

  static Future<RoadNetwork> loadKhulnaNetwork({
    String assetPath = 'assets/khulna.json',
    int coordinatePrecision = 6,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>? ?? const [];

    final nodeIndexByKey = <String, int>{};
    final nodes = <RoadNode>[];

    String _key(double lat, double lng) {
      return '${lat.toStringAsFixed(coordinatePrecision)},${lng.toStringAsFixed(coordinatePrecision)}';
    }

    int _getNodeId(double lat, double lng) {
      final k = _key(lat, lng);
      final existing = nodeIndexByKey[k];
      if (existing != null) {
        return existing;
      }
      final id = nodes.length;
      nodes.add(RoadNode(id: id, lat: lat, lng: lng));
      nodeIndexByKey[k] = id;
      return id;
    }

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      if ((geometry['type'] as String?) != 'LineString') continue;

      final coords = geometry['coordinates'];
      if (coords is! List) continue;
      if (coords.length < 2) continue;

      for (var i = 0; i < coords.length - 1; i++) {
        final a = coords[i];
        final b = coords[i + 1];
        if (a is! List || b is! List || a.length < 2 || b.length < 2) continue;

        final lon1 = (a[0] as num).toDouble();
        final lat1 = (a[1] as num).toDouble();
        final lon2 = (b[0] as num).toDouble();
        final lat2 = (b[1] as num).toDouble();

        final id1 = _getNodeId(lat1, lon1);
        final id2 = _getNodeId(lat2, lon2);
        final dist = haversineMeters(lat1, lon1, lat2, lon2);

        nodes[id1].neighbors.add(RoadNeighbor(nodeId: id2, distanceMeters: dist));
        nodes[id2].neighbors.add(RoadNeighbor(nodeId: id1, distanceMeters: dist));
      }
    }

    return RoadNetwork(nodes: nodes);
  }
}

