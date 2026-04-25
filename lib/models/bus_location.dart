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
    final lat = _asDouble(json['lat']);
    final lng = _asDouble(json['lng']);
    final payloadBusId = (json['busId'] as String?)?.trim();

    final effectivePosition = positionMap is Map<String, dynamic>
        ? GeoPointData.fromJson(positionMap)
        : (lat != null && lng != null)
            ? GeoPointData(lat: lat, lng: lng)
            : const GeoPointData(lat: 0, lng: 0);

    return BusLocation(
      busId: (payloadBusId != null && payloadBusId.isNotEmpty)
          ? payloadBusId
          : (busId ?? ''),
      position: effectivePosition,
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
    if (value is num) {
      final millis =
          value > 1000000000000 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    if (value is String) {
      final parsedNum = num.tryParse(value);
      if (parsedNum != null) {
        final millis = parsedNum > 1000000000000
            ? parsedNum.toInt()
            : (parsedNum * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
