import 'package:cloud_firestore/cloud_firestore.dart';
import 'geo_point.dart';

class BusLocation {
  final String busId;
  final GeoPointData position;
  final double? heading;
  final bool isMoving;
  final DateTime? updatedAt;

  const BusLocation({
    required this.busId,
    required this.position,
    this.heading,
    required this.isMoving,
    this.updatedAt,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json, {String? busId}) {
    final positionMap = json['position'];
    return BusLocation(
      busId: busId ?? (json['busId'] as String? ?? ''),
      position: positionMap is Map<String, dynamic>
          ? GeoPointData.fromJson(positionMap)
          : const GeoPointData(lat: 0, lng: 0),
      heading: (json['heading'] as num?)?.toDouble(),
      isMoving: json['isMoving'] as bool? ?? false,
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'position': position.toJson(),
      'heading': heading,
      'isMoving': isMoving,
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
