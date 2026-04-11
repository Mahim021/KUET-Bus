import 'package:cloud_firestore/cloud_firestore.dart';
import 'geo_point.dart';

class BusRoute {
  final String? id;
  final String routeName;
  final GeoPointData origin;
  final GeoPointData destination;
  final List<GeoPointData> coordinates;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusRoute({
    this.id,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.coordinates,
    this.createdAt,
    this.updatedAt,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json, {String? id}) {
    final coords = (json['coordinates'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GeoPointData.fromJson)
        .toList();
    final originMap = json['origin'];
    final destinationMap = json['destination'];

    final fallbackOrigin =
        coords.isNotEmpty ? coords.first : const GeoPointData(lat: 0, lng: 0);
    final fallbackDestination =
        coords.isNotEmpty ? coords.last : fallbackOrigin;

    return BusRoute(
      id: id,
      routeName: json['routeName'] as String? ?? '',
      origin: originMap is Map<String, dynamic>
          ? GeoPointData.fromJson(originMap)
          : fallbackOrigin,
      destination: destinationMap is Map<String, dynamic>
          ? GeoPointData.fromJson(destinationMap)
          : fallbackDestination,
      coordinates: coords,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'coordinates': coordinates.map((c) => c.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
