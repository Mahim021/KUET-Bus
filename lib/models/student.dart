import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String uid;
  final String name;
  final String email;
  final String kuetId;
  final String department;
  final String batch;
  final String role; // 'student' | 'admin'
  final String? bloodGroup;
  final String? hometown;
  final String? phoneNumber;
  final String? photoUrl;
  final String? photoPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.kuetId,
    required this.department,
    required this.batch,
    this.role = 'student',
    this.bloodGroup,
    this.hometown,
    this.phoneNumber,
    this.photoUrl,
    this.photoPath,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json, {String? uid}) {
    return Student(
      uid: uid ?? (json['uid'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      kuetId: json['kuetId'] as String? ?? '',
      department: json['department'] as String? ?? '',
      batch: json['batch'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      bloodGroup: json['bloodGroup'] as String?,
      hometown: json['hometown'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      photoPath: json['photoPath'] as String?,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'kuetId': kuetId,
      'department': department,
      'batch': batch,
      'role': role,
      'bloodGroup': bloodGroup,
      'hometown': hometown,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
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
