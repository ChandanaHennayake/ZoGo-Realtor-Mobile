class AgentTerritoryPropertyItem {
  final String propertyId;
  final String referenceNo;
  final String title;
  final String? description;
  final double askingPrice;
  final bool isNegotiable;
  final int propertyTypeId;
  final String propertyTypeName;
  final int listingTypeId;
  final String listingTypeName;
  final int districtId;
  final String districtName;
  final int cityId;
  final String cityName;
  final String addressLine1;
  final String? primaryImageUrl;
  final String listerUserId;
  final String listerName;
  final String? listerPhone;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const AgentTerritoryPropertyItem({
    required this.propertyId,
    required this.referenceNo,
    required this.title,
    this.description,
    required this.askingPrice,
    required this.isNegotiable,
    required this.propertyTypeId,
    required this.propertyTypeName,
    required this.listingTypeId,
    required this.listingTypeName,
    required this.districtId,
    required this.districtName,
    required this.cityId,
    required this.cityName,
    required this.addressLine1,
    this.primaryImageUrl,
    required this.listerUserId,
    required this.listerName,
    this.listerPhone,
    this.publishedAt,
    required this.createdAt,
  });

  factory AgentTerritoryPropertyItem.fromJson(Map<String, dynamic> json) {
    final listerMap = json['lister'] as Map<String, dynamic>? ?? {};

    return AgentTerritoryPropertyItem(
      propertyId: json['propertyId']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Property',
      description: json['description']?.toString(),
      askingPrice: (json['askingPrice'] as num?)?.toDouble() ?? 0.0,
      isNegotiable: json['isNegotiable'] as bool? ?? false,
      propertyTypeId: (json['propertyTypeId'] as num?)?.toInt() ?? 0,
      propertyTypeName: json['propertyTypeName']?.toString() ?? '',
      listingTypeId: (json['listingTypeId'] as num?)?.toInt() ?? 0,
      listingTypeName: json['listingTypeName']?.toString() ?? '',
      districtId: (json['districtId'] as num?)?.toInt() ?? 0,
      districtName: json['districtName']?.toString() ?? 'Unknown District',
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
      cityName: json['cityName']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      primaryImageUrl: json['primaryImageUrl']?.toString(),
      listerUserId: listerMap['userId']?.toString() ?? '',
      listerName: listerMap['name']?.toString() ?? 'Lister / Seller',
      listerPhone: listerMap['phoneNumber']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

