import 'dart:math' as math;

import 'geo_utils.dart';
import 'road_network.dart';

class AStarResult {
  final List<int>? path;
  final double distanceMeters;
  final int nodesExplored;
  final double elapsedMs;

  const AStarResult({
    required this.path,
    required this.distanceMeters,
    required this.nodesExplored,
    required this.elapsedMs,
  });
}

class _HeapEntry {
  final int nodeId;
  final double priority;
  const _HeapEntry(this.nodeId, this.priority);
}

class MinHeap {
  final List<_HeapEntry> _heap = <_HeapEntry>[];
  final Map<int, int> _indexByNode = <int, int>{};

  bool get isEmpty => _heap.isEmpty;

  bool contains(int nodeId) => _indexByNode.containsKey(nodeId);

  void insert(int nodeId, double priority) {
    final entry = _HeapEntry(nodeId, priority);
    _heap.add(entry);
    final i = _heap.length - 1;
    _indexByNode[nodeId] = i;
    _bubbleUp(i);
  }

  int? extractMin() {
    if (_heap.isEmpty) return null;

    final minNode = _heap[0].nodeId;
    final last = _heap.removeLast();
    _indexByNode.remove(minNode);

    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _indexByNode[last.nodeId] = 0;
      _bubbleDown(0);
    }

    return minNode;
  }

  void updatePriority(int nodeId, double newPriority) {
    final index = _indexByNode[nodeId];
    if (index == null) return;

    final old = _heap[index].priority;
    _heap[index] = _HeapEntry(nodeId, newPriority);
    if (newPriority < old) {
      _bubbleUp(index);
    } else {
      _bubbleDown(index);
    }
  }

  int _parent(int i) => (i - 1) ~/ 2;
  int _left(int i) => 2 * i + 1;
  int _right(int i) => 2 * i + 2;

  void _swap(int i, int j) {
    final a = _heap[i];
    final b = _heap[j];
    _heap[i] = b;
    _heap[j] = a;
    _indexByNode[a.nodeId] = j;
    _indexByNode[b.nodeId] = i;
  }

  void _bubbleUp(int i) {
    var idx = i;
    while (idx > 0) {
      final p = _parent(idx);
      if (_heap[p].priority <= _heap[idx].priority) break;
      _swap(p, idx);
      idx = p;
    }
  }

  void _bubbleDown(int i) {
    var idx = i;
    while (true) {
      var minIdx = idx;
      final l = _left(idx);
      final r = _right(idx);

      if (l < _heap.length && _heap[l].priority < _heap[minIdx].priority) {
        minIdx = l;
      }
      if (r < _heap.length && _heap[r].priority < _heap[minIdx].priority) {
        minIdx = r;
      }

      if (minIdx == idx) break;
      _swap(idx, minIdx);
      idx = minIdx;
    }
  }
}

double _heuristic(int a, int b, RoadNetwork network) {
  final na = network.nodes[a];
  final nb = network.nodes[b];
  return haversineMeters(na.lat, na.lng, nb.lat, nb.lng);
}

List<int> _reconstructPath(List<int?> cameFrom, int current) {
  final path = <int>[current];
  var cur = current;
  while (cameFrom[cur] != null) {
    cur = cameFrom[cur]!;
    path.insert(0, cur);
  }
  return path;
}

AStarResult aStarPathfinding(int startNodeId, int endNodeId, RoadNetwork network) {
  final sw = Stopwatch()..start();
  final n = network.nodes.length;
  if (startNodeId < 0 ||
      endNodeId < 0 ||
      startNodeId >= n ||
      endNodeId >= n) {
    return const AStarResult(
      path: null,
      distanceMeters: 0,
      nodesExplored: 0,
      elapsedMs: 0,
    );
  }

  final openSet = MinHeap();
  final cameFrom = List<int?>.filled(n, null);
  final gScore = List<double>.filled(n, double.infinity);

  gScore[startNodeId] = 0;
  openSet.insert(startNodeId, _heuristic(startNodeId, endNodeId, network));

  var nodesExplored = 0;
  var iterations = 0;
  const maxIterations = 200000;

  while (!openSet.isEmpty && iterations < maxIterations) {
    iterations++;
    final current = openSet.extractMin();
    if (current == null) break;

    nodesExplored++;
    if (current == endNodeId) {
      final path = _reconstructPath(cameFrom, current);
      sw.stop();
      return AStarResult(
        path: path,
        distanceMeters: gScore[endNodeId],
        nodesExplored: nodesExplored,
        elapsedMs: sw.elapsedMicroseconds / 1000.0,
      );
    }

    final currentScore = gScore[current];
    if (currentScore.isInfinite) {
      continue;
    }

    final node = network.nodes[current];
    for (final neighbor in node.neighbors) {
      final next = neighbor.nodeId;
      final tentative = currentScore + neighbor.distanceMeters;
      if (tentative < gScore[next]) {
        cameFrom[next] = current;
        gScore[next] = tentative;
        final f = tentative + _heuristic(next, endNodeId, network);
        if (openSet.contains(next)) {
          openSet.updatePriority(next, f);
        } else {
          openSet.insert(next, f);
        }
      }
    }
  }

  sw.stop();
  return AStarResult(
    path: null,
    distanceMeters: 0,
    nodesExplored: nodesExplored,
    elapsedMs: math.max(0, sw.elapsedMicroseconds / 1000.0),
  );
}

