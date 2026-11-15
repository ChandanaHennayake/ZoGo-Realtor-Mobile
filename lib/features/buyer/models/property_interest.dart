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

class BuyerInterestedPropertyModel {
  final String propertyId;
  final String referenceNo;
  final String title;
  final double askingPrice;
  final bool isNegotiable;
  final String? districtName;
  final String? cityName;
  final String? addressLine1;
  final String? imageUrl;
  final int? bedrooms;
  final int? bathrooms;
  final double? propertySize;
  final String? sizeUnit;
  final int interestStatus;
  final String interestStatusName;
  final int? interactionStatus;
  final String? interactionStatusName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BuyerInterestedPropertyModel({
    required this.propertyId,
    required this.referenceNo,
    required this.title,
    required this.askingPrice,
    required this.isNegotiable,
    this.districtName,
    this.cityName,
    this.addressLine1,
    this.imageUrl,
    this.bedrooms,
    this.bathrooms,
    this.propertySize,
    this.sizeUnit,
    required this.interestStatus,
    required this.interestStatusName,
    this.interactionStatus,
    this.interactionStatusName,
    required this.createdAt,
    this.updatedAt,
  });

  factory BuyerInterestedPropertyModel.fromJson(Map<String, dynamic> json) {
    return BuyerInterestedPropertyModel(
      propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
      referenceNo: (json['referenceNo'] ?? json['ReferenceNo'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Untitled Property').toString(),
      askingPrice: (json['askingPrice'] ?? json['AskingPrice'] as num?)?.toDouble() ?? 0.0,
      isNegotiable: json['isNegotiable'] ?? json['IsNegotiable'] ?? false,
      districtName: json['districtName'] ?? json['DistrictName'],
      cityName: json['cityName'] ?? json['CityName'],
      addressLine1: json['addressLine1'] ?? json['AddressLine1'],
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      bedrooms: (json['bedrooms'] ?? json['Bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] ?? json['Bathrooms'] as num?)?.toInt(),
      propertySize: (json['propertySize'] ?? json['PropertySize'] as num?)?.toDouble(),
      sizeUnit: json['sizeUnit'] ?? json['SizeUnit'],
      interestStatus: (json['interestStatus'] ?? json['InterestStatus'] as num?)?.toInt() ?? 1,
      interestStatusName: (json['interestStatusName'] ?? json['InterestStatusName'] ?? 'INTERESTED').toString(),
      interactionStatus: (json['interactionStatus'] ?? json['InteractionStatus'] as num?)?.toInt(),
      interactionStatusName: json['interactionStatusName'] ?? json['InteractionStatusName'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  String get stageBadgeText {
    if (interactionStatus == 2) return 'Visit Requested';
    if (interactionStatus == 3) return 'Visited';
    if (interactionStatus == 4) return 'Docs Requested';
    if (interactionStatus == 5) return 'Negotiating';
    if (interactionStatus == 6) return 'Offer Submitted';
    if (interactionStatus == 7) return 'Offer Accepted';
    return interestStatusName.toUpperCase();
  }

  Color get stageBadgeColor {
    if (interactionStatus == 2) return const Color(0xFF6366F1); // Indigo / Purple
    if (interactionStatus == 3) return const Color(0xFF10B981); // Emerald
    if (interactionStatus == 6 || interactionStatus == 7) return const Color(0xFF00C6D4); // Cyan
    return const Color(0xFF10B981);
  }
}
