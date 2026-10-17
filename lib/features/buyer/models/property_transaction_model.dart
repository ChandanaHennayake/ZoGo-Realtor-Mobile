import 'package:flutter/material.dart';

class PropertyTransactionModel {
  final String transactionId;
  final String propertyId;
  final String propertyTitle;
  final String propertyReferenceNo;
  final String districtName;
  final String cityName;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String? agentId;
  final String? agentName;
  final double agreedPrice;
  final double commissionRate;
  final double commissionAmount;
  final int status;
  final String statusName;
  final String? titleDeedReference;
  final String? notaryName;
  final String? closingNotes;
  final DateTime? closingDate;
  final DateTime createdAt;

  // Status Constants
  static const int statusInitiated = 1;
  static const int statusTitleVerified = 2;
  static const int statusDeedSigned = 3;
  static const int statusSettled = 4;
  static const int statusCancelled = 5;

  const PropertyTransactionModel({
    required this.transactionId,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyReferenceNo,
    required this.districtName,
    required this.cityName,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.agentId,
    this.agentName,
    required this.agreedPrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.status,
    required this.statusName,
    this.titleDeedReference,
    this.notaryName,
    this.closingNotes,
    this.closingDate,
    required this.createdAt,
  });

  static String resolveStatusName(int status) {
    switch (status) {
      case statusInitiated:
        return 'Title Search Pending';
      case statusTitleVerified:
        return 'Title Clear / Deed Prep';
      case statusDeedSigned:
        return 'Deed of Transfer Signed';
      case statusSettled:
        return 'Settled & Sold';
      case statusCancelled:
        return 'Cancelled';
      default:
        return 'Status #$status';
    }
  }

  Color get color {
    switch (status) {
      case statusInitiated:
        return const Color(0xFFF59E0B); // Amber
      case statusTitleVerified:
        return const Color(0xFF3B82F6); // Blue
      case statusDeedSigned:
        return const Color(0xFF6366F1); // Indigo / Purple
      case statusSettled:
        return const Color(0xFF10B981); // Emerald Green
      case statusCancelled:
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF00C6D4);
    }
  }

  IconData get icon {
    switch (status) {
      case statusInitiated:
        return Icons.policy_outlined;
      case statusTitleVerified:
        return Icons.verified_user_outlined;
      case statusDeedSigned:
        return Icons.draw_outlined;
      case statusSettled:
        return Icons.check_circle_outline_rounded;
      case statusCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  factory PropertyTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['Status'] ?? 1;
    final statusInt = (rawStatus is num) ? rawStatus.toInt() : int.tryParse(rawStatus.toString()) ?? 1;

    final rawPrice = json['agreedPrice'] ?? json['AgreedPrice'] ?? 0;
    final priceVal = (rawPrice is num) ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0.0;

    final rawCommRate = json['commissionRate'] ?? json['CommissionRate'] ?? 0.03;
    final commRateVal = (rawCommRate is num) ? rawCommRate.toDouble() : double.tryParse(rawCommRate.toString()) ?? 0.03;

    final rawCommAmount = json['commissionAmount'] ?? json['CommissionAmount'] ?? 0;
    final commAmountVal = (rawCommAmount is num) ? rawCommAmount.toDouble() : double.tryParse(rawCommAmount.toString()) ?? 0.0;

    return PropertyTransactionModel(
      transactionId: (json['transactionId'] ?? json['TransactionId'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
      propertyTitle: (json['propertyTitle'] ?? json['PropertyTitle'] ?? 'Property').toString(),
      propertyReferenceNo: (json['propertyReferenceNo'] ?? json['PropertyReferenceNo'] ?? '').toString(),
      districtName: (json['districtName'] ?? json['DistrictName'] ?? '').toString(),
      cityName: (json['cityName'] ?? json['CityName'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? json['BuyerId'] ?? '').toString(),
      buyerName: (json['buyerName'] ?? json['BuyerName'] ?? 'Buyer').toString(),
      sellerId: (json['sellerId'] ?? json['SellerId'] ?? '').toString(),
      sellerName: (json['sellerName'] ?? json['SellerName'] ?? 'Seller').toString(),
      agentId: json['agentId']?.toString(),
      agentName: json['agentName']?.toString(),
      agreedPrice: priceVal,
      commissionRate: commRateVal,
      commissionAmount: commAmountVal,
      status: statusInt,
      statusName: (json['statusName'] ?? json['StatusName'] ?? resolveStatusName(statusInt)).toString(),
      titleDeedReference: json['titleDeedReference']?.toString(),
      notaryName: json['notaryName']?.toString(),
      closingNotes: json['closingNotes']?.toString(),
      closingDate: json['closingDate'] != null ? DateTime.tryParse(json['closingDate'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
