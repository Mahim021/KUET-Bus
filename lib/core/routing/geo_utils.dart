import 'dart:math' as math;

double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final phi1 = lat1 * math.pi / 180.0;
  final phi2 = lat2 * math.pi / 180.0;
  final dPhi = (lat2 - lat1) * math.pi / 180.0;
  final dLam = (lng2 - lng1) * math.pi / 180.0;

  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(dLam / 2) * math.sin(dLam / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

