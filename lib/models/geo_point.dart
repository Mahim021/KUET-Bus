class GeoPointData {
  final double lat;
  final double lng;

  const GeoPointData({
    required this.lat,
    required this.lng,
  });

  factory GeoPointData.fromJson(Map<String, dynamic> json) {
    return GeoPointData(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
