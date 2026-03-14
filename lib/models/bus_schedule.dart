import 'package:cloud_firestore/cloud_firestore.dart';

class BusSchedule {
  final String? id;
  final String routeId;
  final String busId;
  final String time;
  final String period;
  final List<String> daysOfWeek;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusSchedule({
    this.id,
    required this.routeId,
    required this.busId,
    required this.time,
    required this.period,
    required this.daysOfWeek,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json, {String? id}) {
    return BusSchedule(
      id: id,
      routeId: json['routeId'] as String? ?? '',
      busId: json['busId'] as String? ?? '',
      time: json['time'] as String? ?? '',
      period: json['period'] as String? ?? '',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? []).cast<String>(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'busId': busId,
      'time': time,
      'period': period,
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
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
