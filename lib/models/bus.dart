import 'package:cloud_firestore/cloud_firestore.dart';

class Bus {
  final String? id;
  final String busNumber;
  final String busName;
  final String? driverId;
  final String? plateNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Bus({
    this.id,
    required this.busNumber,
    required this.busName,
    this.driverId,
    this.plateNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json, {String? id}) {
    return Bus(
      id: id,
      busNumber: json['busNumber'] as String? ?? '',
      busName: json['busName'] as String? ?? '',
      driverId: json['driverId'] as String?,
      plateNumber: json['plateNumber'] as String?,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busNumber': busNumber,
      'busName': busName,
      'driverId': driverId,
      'plateNumber': plateNumber,
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
