import 'package:flutter/material.dart';

class AdminPropertySummaryModel {
  final String propertyId;
  final String referenceNo;
  final String title;
  final int propertyTypeId;
  final String propertyTypeName;
  final int listingTypeId;
  final String listingTypeName;
  final String districtName;
  final String cityName;
  final double askingPrice;
  final int status;
  final String statusName;
  final String ownerUserId;
  final String ownerName;
  final String ownerEmail;
  final int photoCount;
  final int documentCount;
  final String? primaryImageUrl;
  final DateTime createdAt;

  static const int statusDraft = 1;
  static const int statusPublished = 2;
  static const int statusUnderReview = 3;
  static const int statusPendingApproval = 4;
  static const int statusRejected = 5;
  static const int statusChangesRequested = 9;

  const AdminPropertySummaryModel({
    required this.propertyId,
    required this.referenceNo,
    required this.title,
    required this.propertyTypeId,
    required this.propertyTypeName,
    required this.listingTypeId,
    required this.listingTypeName,
    required this.districtName,
    required this.cityName,
    required this.askingPrice,
    required this.status,
    required this.statusName,
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerEmail,
    required this.photoCount,
    required this.documentCount,
    this.primaryImageUrl,
    required this.createdAt,
  });

  factory AdminPropertySummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminPropertySummaryModel(
      propertyId: json['propertyId']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Property',
      propertyTypeId: (json['propertyTypeId'] as num?)?.toInt() ?? 0,
      propertyTypeName: json['propertyTypeName']?.toString() ?? '',
      listingTypeId: (json['listingTypeId'] as num?)?.toInt() ?? 0,
      listingTypeName: json['listingTypeName']?.toString() ?? '',
      districtName: json['districtName']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      askingPrice: (json['askingPrice'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusName: json['statusName']?.toString() ?? 'Pending',
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Property Owner',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      primaryImageUrl: json['primaryImageUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Color get statusColor {
    switch (status) {
      case statusPublished:
        return const Color(0xFF10B981); // Emerald
      case statusPendingApproval:
        return const Color(0xFFF59E0B); // Amber
      case statusUnderReview:
        return const Color(0xFF3B82F6); // Blue
      case statusChangesRequested:
        return const Color(0xFF8B5CF6); // Purple
      case statusRejected:
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData get statusIcon {
    switch (status) {
      case statusPublished:
        return Icons.verified_rounded;
      case statusPendingApproval:
        return Icons.hourglass_top_rounded;
      case statusUnderReview:
        return Icons.rate_review_rounded;
      case statusChangesRequested:
        return Icons.edit_note_rounded;
      case statusRejected:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class AdminPropertyMediaItem {
  final String mediaId;
  final String mediaUrl;
  final bool isCover;
  final int displayOrder;

  const AdminPropertyMediaItem({
    required this.mediaId,
    required this.mediaUrl,
    required this.isCover,
    required this.displayOrder,
  });

  factory AdminPropertyMediaItem.fromJson(Map<String, dynamic> json) {
    return AdminPropertyMediaItem(
      mediaId: json['mediaId']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      isCover: json['isCover'] == true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPropertyDocumentItem {
  final String documentId;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final DateTime uploadedAt;

  const AdminPropertyDocumentItem({
    required this.documentId,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.uploadedAt,
  });

  factory AdminPropertyDocumentItem.fromJson(Map<String, dynamic> json) {
    return AdminPropertyDocumentItem(
      documentId: json['documentId']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? 'Document',
      documentName: json['documentName']?.toString() ?? 'Official File',
      documentUrl: json['documentUrl']?.toString() ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminPropertyReviewDetailsModel {
  final String propertyId;
  final String referenceNo;
  final String title;
  final String? description;
  final int propertyTypeId;
  final String propertyTypeName;
  final int listingTypeId;
  final String listingTypeName;
  final String provinceName;
  final String districtName;
  final String cityName;
  final String addressLine1;
  final String? addressLine2;
  final String? postalCode;
  final double askingPrice;
  final bool isNegotiable;
  final int status;
  final String statusName;
  final DateTime createdAt;

  final String ownerUserId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;

  final List<AdminPropertyMediaItem> media;
  final List<AdminPropertyDocumentItem> documents;

  final int? bedrooms;
  final int? bathrooms;
  final double? floorAreaSqFt;
  final double? landAreaPerches;
  final int? parkingSpaces;
  final List<String> amenities;
  final List<String> features;

  final String? divisionalSecretariatName;
  final String? gnDivisionName;

  final double? maintenanceFee;
  final bool? billsUpToDate;
  final bool hasOutstandingCharges;
  final double? outstandingAmount;

  final String? ownershipTypeName;
  final bool hasMortgage;
  final String? mortgageProvider;
  final bool hasLegalIssues;
  final String? legalIssueDescription;

  const AdminPropertyReviewDetailsModel({
    required this.propertyId,
    required this.referenceNo,
    required this.title,
    this.description,
    required this.propertyTypeId,
    required this.propertyTypeName,
    required this.listingTypeId,
    required this.listingTypeName,
    required this.provinceName,
    required this.districtName,
    required this.cityName,
    required this.addressLine1,
    this.addressLine2,
    this.postalCode,
    required this.askingPrice,
    required this.isNegotiable,
    required this.status,
    required this.statusName,
    required this.createdAt,
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.media,
    required this.documents,
    this.bedrooms,
    this.bathrooms,
    this.floorAreaSqFt,
    this.landAreaPerches,
    this.parkingSpaces,
    required this.amenities,
    required this.features,
    this.divisionalSecretariatName,
    this.gnDivisionName,
    this.maintenanceFee,
    this.billsUpToDate,
    required this.hasOutstandingCharges,
    this.outstandingAmount,
    this.ownershipTypeName,
    required this.hasMortgage,
    this.mortgageProvider,
    required this.hasLegalIssues,
    this.legalIssueDescription,
  });

  factory AdminPropertyReviewDetailsModel.fromJson(Map<String, dynamic> json) {
    List<AdminPropertyMediaItem> mediaList = [];
    if (json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((m) => AdminPropertyMediaItem.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    List<AdminPropertyDocumentItem> docList = [];
    if (json['documents'] is List) {
      docList = (json['documents'] as List)
          .map((d) => AdminPropertyDocumentItem.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    }

    List<String> amenitiesList = [];
    if (json['amenities'] is List) {
      amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    }

    List<String> featuresList = [];
    if (json['features'] is List) {
      featuresList = (json['features'] as List).map((f) => f.toString()).toList();
    }

    return AdminPropertyReviewDetailsModel(
      propertyId: json['propertyId']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Property',
      description: json['description']?.toString(),
      propertyTypeId: (json['propertyTypeId'] as num?)?.toInt() ?? 0,
      propertyTypeName: json['propertyTypeName']?.toString() ?? '',
      listingTypeId: (json['listingTypeId'] as num?)?.toInt() ?? 0,
      listingTypeName: json['listingTypeName']?.toString() ?? '',
      provinceName: json['provinceName']?.toString() ?? '',
      districtName: json['districtName']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      postalCode: json['postalCode']?.toString(),
      askingPrice: (json['askingPrice'] as num?)?.toDouble() ?? 0.0,
      isNegotiable: json['isNegotiable'] == true,
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusName: json['statusName']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Owner',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      ownerPhone: json['ownerPhone']?.toString() ?? '',
      media: mediaList,
      documents: docList,
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      floorAreaSqFt: (json['floorAreaSqFt'] as num?)?.toDouble(),
      landAreaPerches: (json['landAreaPerches'] as num?)?.toDouble(),
      parkingSpaces: (json['parkingSpaces'] as num?)?.toInt(),
      amenities: amenitiesList,
      features: featuresList,
      divisionalSecretariatName: json['divisionalSecretariatName']?.toString(),
      gnDivisionName: json['gnDivisionName']?.toString(),
      maintenanceFee: (json['maintenanceFee'] as num?)?.toDouble(),
      billsUpToDate: json['billsUpToDate'] == true,
      hasOutstandingCharges: json['hasOutstandingCharges'] == true,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble(),
      ownershipTypeName: json['ownershipTypeName']?.toString(),
      hasMortgage: json['hasMortgage'] == true,
      mortgageProvider: json['mortgageProvider']?.toString(),
      hasLegalIssues: json['hasLegalIssues'] == true,
      legalIssueDescription: json['legalIssueDescription']?.toString(),
    );
  }
}
