import 'package:flutter/material.dart';

enum PropertyInterestType {
  interested(1, 'Interested'),
  considering(2, 'Considering'),
  notInterested(3, 'Not Interested');

  final int value;
  final String label;

  const PropertyInterestType(this.value, this.label);

  static PropertyInterestType? fromValue(int? val) {
    if (val == null) return null;
    for (final t in PropertyInterestType.values) {
      if (t.value == val) return t;
    }
    return null;
  }
}

class PropertyInterest {
  final String propertyId;
  final int status;
  final String statusName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int statusInterested = 1;
  static const int statusConsidering = 2;
  static const int statusNotInterested = 3;

  const PropertyInterest({
    required this.propertyId,
    required this.status,
    required this.statusName,
    this.createdAt,
    this.updatedAt,
  });

  static String resolveStatusName(int status) {
    switch (status) {
      case statusInterested:
        return 'Interested';
      case statusConsidering:
        return 'Considering';
      case statusNotInterested:
        return 'Not Interested';
      default:
        return 'Status #$status';
    }
  }

  Color get color {
    switch (status) {
      case statusInterested:
        return const Color(0xFF10B981); // Emerald green
      case statusConsidering:
        return const Color(0xFFF59E0B); // Amber
      case statusNotInterested:
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF00C6D4);
    }
  }

  factory PropertyInterest.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    final rawStatus = data['status'] ?? data['Status'] ?? 0;
    final statusInt = (rawStatus is num) ? rawStatus.toInt() : int.tryParse(rawStatus.toString()) ?? 0;
    final propId = (data['propertyId'] ?? data['PropertyId'] ?? '').toString();

    return PropertyInterest(
      propertyId: propId,
      status: statusInt,
      statusName: (data['statusName'] ?? data['StatusName'] ?? resolveStatusName(statusInt)).toString(),
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}
