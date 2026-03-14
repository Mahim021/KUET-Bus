class RoadNeighbor {
  final int nodeId;
  final double distanceMeters;

  const RoadNeighbor({
    required this.nodeId,
    required this.distanceMeters,
  });
}

class RoadNode {
  final int id;
  final double lat;
  final double lng;
  final List<RoadNeighbor> neighbors;

  RoadNode({
    required this.id,
    required this.lat,
    required this.lng,
    List<RoadNeighbor>? neighbors,
  }) : neighbors = neighbors ?? <RoadNeighbor>[];
}

class RoadNetwork {
  final List<RoadNode> nodes;
  const RoadNetwork({required this.nodes});
}

