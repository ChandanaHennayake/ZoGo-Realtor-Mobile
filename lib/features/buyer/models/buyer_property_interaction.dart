import 'package:flutter/material.dart';

enum BuyerInteractionStage {
  interested(1, 'Interested', Icons.favorite_border_rounded, Color(0xFF00C6D4)),
  visitRequested(2, 'Visit Requested', Icons.calendar_month_outlined, Color(0xFF3B82F6)),
  visited(3, 'Visited', Icons.home_rounded, Color(0xFF10B981)),
  documentsRequested(4, 'Documents Requested', Icons.description_outlined, Color(0xFF8B5CF6)),
  negotiating(5, 'Negotiating', Icons.handshake_outlined, Color(0xFFF59E0B)),
  offerSubmitted(6, 'Offer Submitted', Icons.local_offer_outlined, Color(0xFFEC4899)),
  offerAccepted(7, 'Offer Accepted', Icons.verified_rounded, Color(0xFF059669)),
  offerRejected(8, 'Offer Rejected', Icons.cancel_outlined, Color(0xFFEF4444)),
  notInterested(9, 'Not Interested', Icons.thumb_down_outlined, Color(0xFF6B7280));

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const BuyerInteractionStage(this.value, this.label, this.icon, this.color);

  static BuyerInteractionStage? fromValue(int? val) {
    if (val == null) return null;
    for (final s in BuyerInteractionStage.values) {
      if (s.value == val) return s;
    }
    return null;
  }
}

class BuyerPropertyInteraction {
  final String? id;
  final String propertyId;
  final String? buyerId;
  final int currentStatus;
  final String currentStatusName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int statusInterested = 1;
  static const int statusVisitRequested = 2;
  static const int statusVisited = 3;
  static const int statusDocumentsRequested = 4;
  static const int statusNegotiating = 5;
  static const int statusOfferSubmitted = 6;
  static const int statusOfferAccepted = 7;
  static const int statusOfferRejected = 8;
  static const int statusNotInterested = 9;

  const BuyerPropertyInteraction({
    this.id,
    required this.propertyId,
    this.buyerId,
    required this.currentStatus,
    required this.currentStatusName,
    this.createdAt,
    this.updatedAt,
  });

  static String resolveStatusName(int status) {
    switch (status) {
      case statusInterested:
        return 'Interested';
      case statusVisitRequested:
        return 'Visit Requested';
      case statusVisited:
        return 'Visited';
      case statusDocumentsRequested:
        return 'Documents Requested';
      case statusNegotiating:
        return 'Negotiating';
      case statusOfferSubmitted:
        return 'Offer Submitted';
      case statusOfferAccepted:
        return 'Offer Accepted';
      case statusOfferRejected:
        return 'Offer Rejected';
      case statusNotInterested:
        return 'Not Interested';
      default:
        return 'Status #$status';
    }
  }

  BuyerInteractionStage get stage =>
      BuyerInteractionStage.fromValue(currentStatus) ?? BuyerInteractionStage.interested;

  Color get color => stage.color;
  IconData get icon => stage.icon;
  String get displayLabel => resolveStatusName(currentStatus);

  factory BuyerPropertyInteraction.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    final rawStatus = data['currentStatus'] ?? data['status'] ?? data['CurrentStatus'] ?? 1;
    final statusInt = (rawStatus is num) ? rawStatus.toInt() : int.tryParse(rawStatus.toString()) ?? 1;

    return BuyerPropertyInteraction(
      id: (data['id'] ?? data['Id'])?.toString(),
      propertyId: (data['propertyId'] ?? data['PropertyId'] ?? '').toString(),
      buyerId: (data['buyerId'] ?? data['BuyerId'])?.toString(),
      currentStatus: statusInt,
      currentStatusName: (data['currentStatusName'] ??
              data['CurrentStatusName'] ??
              data['statusName'] ??
              resolveStatusName(statusInt))
          .toString(),
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': currentStatus,
    };
  }
}
