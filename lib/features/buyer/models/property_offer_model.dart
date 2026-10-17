import 'package:flutter/material.dart';

class PropertyOfferModel {
  final String offerId;
  final String propertyId;
  final String propertyTitle;
  final String propertyReferenceNo;
  final double askingPrice;
  final double offerAmount;
  final double? counterAmount;
  final String? buyerNotes;
  final String? sellerNotes;
  final int status;
  final String statusName;
  final DateTime? expiresAt;
  final DateTime createdAt;

  // Status Constants
  static const int statusSubmitted = 1;
  static const int statusCountered = 2;
  static const int statusAccepted = 3;
  static const int statusRejected = 4;
  static const int statusWithdrawn = 5;
  static const int statusExpired = 6;

  const PropertyOfferModel({
    required this.offerId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyReferenceNo,
    required this.askingPrice,
    required this.offerAmount,
    this.counterAmount,
    this.buyerNotes,
    this.sellerNotes,
    required this.status,
    required this.statusName,
    this.expiresAt,
    required this.createdAt,
  });

  static String resolveStatusName(int status) {
    switch (status) {
      case statusSubmitted:
        return 'Offer Submitted';
      case statusCountered:
        return 'Counter Offered';
      case statusAccepted:
        return 'Offer Accepted';
      case statusRejected:
        return 'Offer Rejected';
      case statusWithdrawn:
        return 'Withdrawn';
      case statusExpired:
        return 'Expired';
      default:
        return 'Status #$status';
    }
  }

  Color get color {
    switch (status) {
      case statusSubmitted:
        return const Color(0xFFF59E0B); // Amber
      case statusCountered:
        return const Color(0xFF6366F1); // Indigo / Purple
      case statusAccepted:
        return const Color(0xFF10B981); // Emerald Green
      case statusRejected:
        return const Color(0xFFEF4444); // Red
      case statusWithdrawn:
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF00C6D4);
    }
  }

  IconData get icon {
    switch (status) {
      case statusSubmitted:
        return Icons.local_offer_rounded;
      case statusCountered:
        return Icons.handshake_rounded;
      case statusAccepted:
        return Icons.verified_rounded;
      case statusRejected:
        return Icons.highlight_off_rounded;
      case statusWithdrawn:
        return Icons.undo_rounded;
      default:
        return Icons.monetization_on_outlined;
    }
  }

  factory PropertyOfferModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['Status'] ?? 1;
    final statusInt = (rawStatus is num) ? rawStatus.toInt() : int.tryParse(rawStatus.toString()) ?? 1;

    final rawAskingPrice = json['askingPrice'] ?? json['AskingPrice'] ?? 0;
    final askingPriceVal = (rawAskingPrice is num) ? rawAskingPrice.toDouble() : double.tryParse(rawAskingPrice.toString()) ?? 0.0;

    final rawOfferAmount = json['offerAmount'] ?? json['OfferAmount'] ?? 0;
    final offerAmountVal = (rawOfferAmount is num) ? rawOfferAmount.toDouble() : double.tryParse(rawOfferAmount.toString()) ?? 0.0;

    final rawCounterAmount = json['counterAmount'] ?? json['CounterAmount'];
    final counterAmountVal = rawCounterAmount != null
        ? ((rawCounterAmount is num) ? rawCounterAmount.toDouble() : double.tryParse(rawCounterAmount.toString()))
        : null;

    return PropertyOfferModel(
      offerId: (json['offerId'] ?? json['OfferId'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
      propertyTitle: (json['propertyTitle'] ?? json['PropertyTitle'] ?? 'Property').toString(),
      propertyReferenceNo: (json['propertyReferenceNo'] ?? json['PropertyReferenceNo'] ?? '').toString(),
      askingPrice: askingPriceVal,
      offerAmount: offerAmountVal,
      counterAmount: counterAmountVal,
      buyerNotes: json['buyerNotes']?.toString(),
      sellerNotes: json['sellerNotes']?.toString(),
      status: statusInt,
      statusName: (json['statusName'] ?? json['StatusName'] ?? resolveStatusName(statusInt)).toString(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
