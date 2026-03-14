import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String? id;
  final String title;
  final String body;
  final String tag;
  final String? priority;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Notice({
    this.id,
    required this.title,
    required this.body,
    required this.tag,
    this.priority,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json, {String? id}) {
    return Notice(
      id: id,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      priority: json['priority'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'tag': tag,
      'priority': priority,
      'createdBy': createdBy,
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
