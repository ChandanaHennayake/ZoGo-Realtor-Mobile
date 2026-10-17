import 'package:flutter/material.dart';

class PropertyVisitModel {
  final String visitId;
  final String propertyId;
  final String propertyTitle;
  final String propertyReferenceNo;
  final String districtName;
  final String cityName;
  final DateTime scheduledAt;
  final String timeSlot;
  final String? buyerNotes;
  final String? agentNotes;
  final int status;
  final String statusName;
  final String? assignedAgentName;
  final DateTime createdAt;

  // Status Constants
  static const int statusRequested = 1;
  static const int statusConfirmed = 2;
  static const int statusCompleted = 3;
  static const int statusCancelled = 4;
  static const int statusRejected = 5;

  const PropertyVisitModel({
    required this.visitId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyReferenceNo,
    required this.districtName,
    required this.cityName,
    required this.scheduledAt,
    required this.timeSlot,
    this.buyerNotes,
    this.agentNotes,
    required this.status,
    required this.statusName,
    this.assignedAgentName,
    required this.createdAt,
  });

  static String resolveStatusName(int status) {
    switch (status) {
      case statusRequested:
        return 'Visit Requested';
      case statusConfirmed:
        return 'Confirmed';
      case statusCompleted:
        return 'Completed';
      case statusCancelled:
        return 'Cancelled';
      case statusRejected:
        return 'Rejected';
      default:
        return 'Status #$status';
    }
  }

  Color get color {
    switch (status) {
      case statusRequested:
        return const Color(0xFFF59E0B); // Amber
      case statusConfirmed:
        return const Color(0xFF00C6D4); // Cyan
      case statusCompleted:
        return const Color(0xFF10B981); // Emerald Green
      case statusCancelled:
        return const Color(0xFF6B7280); // Gray
      case statusRejected:
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData get icon {
    switch (status) {
      case statusRequested:
        return Icons.schedule_rounded;
      case statusConfirmed:
        return Icons.event_available_rounded;
      case statusCompleted:
        return Icons.task_alt_rounded;
      case statusCancelled:
        return Icons.event_busy_rounded;
      case statusRejected:
        return Icons.cancel_outlined;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  factory PropertyVisitModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['Status'] ?? 1;
    final statusInt = (rawStatus is num) ? rawStatus.toInt() : int.tryParse(rawStatus.toString()) ?? 1;

    return PropertyVisitModel(
      visitId: (json['visitId'] ?? json['VisitId'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
      propertyTitle: (json['propertyTitle'] ?? json['PropertyTitle'] ?? 'Property').toString(),
      propertyReferenceNo: (json['propertyReferenceNo'] ?? json['PropertyReferenceNo'] ?? '').toString(),
      districtName: (json['districtName'] ?? json['DistrictName'] ?? '').toString(),
      cityName: (json['cityName'] ?? json['CityName'] ?? '').toString(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: (json['timeSlot'] ?? json['TimeSlot'] ?? 'Morning (09:00 - 12:00)').toString(),
      buyerNotes: json['buyerNotes']?.toString(),
      agentNotes: json['agentNotes']?.toString(),
      status: statusInt,
      statusName: (json['statusName'] ?? json['StatusName'] ?? resolveStatusName(statusInt)).toString(),
      assignedAgentName: json['assignedAgentName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
