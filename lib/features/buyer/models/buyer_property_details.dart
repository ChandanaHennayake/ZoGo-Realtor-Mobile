class BuyerPropertyMediaItem {
  final String id;
  final String url;
  final int mediaType; // 1: Image, 2: Video
  final bool isCover;
  final int displayOrder;

  const BuyerPropertyMediaItem({
    required this.id,
    required this.url,
    this.mediaType = 1,
    this.isCover = false,
    this.displayOrder = 0,
  });

  bool get isVideo => mediaType == 2;

  factory BuyerPropertyMediaItem.fromJson(Map<String, dynamic> json) {
    return BuyerPropertyMediaItem(
      id: (json['id'] ?? json['mediaId'] ?? '').toString(),
      url: (json['mediaUrl'] ?? json['url'] ?? json['filePath'] ?? '').toString(),
      mediaType: (json['mediaType'] as num?)?.toInt() ?? 1,
      isCover: json['isCover'] == true || json['IsCover'] == true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class BuyerPropertyDetails {
  final String propertyId;
  final String referenceNo;
  final String title;
  final String? description;
  final int propertyTypeId;
  final String propertyTypeName;
  final int listingTypeId;
  final String listingTypeName;
  final double askingPrice;
  final String formattedPrice;
  final bool isNegotiable;
  final int? provinceId;
  final String? provinceName;
  final int? districtId;
  final String? districtName;
  final int? cityId;
  final String? city;
  final String? addressLine1;
  final String? addressLine2;
  final String? postalCode;
  final String? divisionalSecretariatName;
  final String? gnDivisionName;
  final double? latitude;
  final double? longitude;
  final int? bedrooms;
  final int? bathrooms;
  final double? propertySize;
  final String? sizeUnit;
  final int status;
  final String statusName;
  final bool isFavorite;
  final List<BuyerPropertyMediaItem> media;
  final List<Map<String, dynamic>> features;
  final List<Map<String, dynamic>> amenities;
  final Map<String, dynamic>? financials;
  final Map<String, dynamic>? legalDetails;
  final Map<String, dynamic>? apartmentDetails;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final String? agentUserId;
  final String? agentName;
  final String? agentPhoneNumber;

  const BuyerPropertyDetails({
    required this.propertyId,
    required this.referenceNo,
    required this.title,
    this.description,
    required this.propertyTypeId,
    required this.propertyTypeName,
    required this.listingTypeId,
    required this.listingTypeName,
    required this.askingPrice,
    required this.formattedPrice,
    this.isNegotiable = false,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.cityId,
    this.city,
    this.addressLine1,
    this.addressLine2,
    this.postalCode,
    this.divisionalSecretariatName,
    this.gnDivisionName,
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.propertySize,
    this.sizeUnit,
    this.status = 2,
    this.statusName = 'Published',
    this.isFavorite = false,
    this.media = const [],
    this.features = const [],
    this.amenities = const [],
    this.financials,
    this.legalDetails,
    this.apartmentDetails,
    this.publishedAt,
    this.createdAt,
    this.agentUserId,
    this.agentName,
    this.agentPhoneNumber,
  });

  static const Map<int, String> _propertyTypeNames = {
    1: 'House',
    2: 'Land',
    3: 'Apartment',
    4: 'Commercial',
    5: 'Villa',
  };

  static const Map<int, String> _listingTypeNames = {
    1: 'For Sale',
    2: 'For Rent',
  };

  static String _formatCurrency(double amount) {
    if (amount <= 0) return 'Price upon request';
    final parts = amount.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rs. ${parts.replaceAll(reg, ',')}';
  }

  factory BuyerPropertyDetails.fromJson(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>>? extraMedia,
    List<Map<String, dynamic>>? extraFeatures,
    List<Map<String, dynamic>>? extraAmenities,
    Map<String, dynamic>? extraApartmentDetails,
    Map<String, dynamic>? extraFinancials,
    Map<String, dynamic>? extraLegalDetails,
    bool? isFav,
  }) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    final rawPrice = rawData['askingPrice'] ?? rawData['price'] ?? 0;
    final priceVal = (rawPrice is num)
        ? rawPrice.toDouble()
        : (double.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);

    final rawPropType = rawData['propertyTypeId'] ?? rawData['typeId'] ?? 1;
    final propTypeId = (rawPropType is num) ? rawPropType.toInt() : 1;

    final rawListingType = rawData['listingTypeId'] ?? 1;
    final listingTypeId = (rawListingType is num) ? rawListingType.toInt() : 1;

    final rawStatus = rawData['status'] ?? rawData['propertyStatus'] ?? 2;
    final statusId = (rawStatus is num) ? rawStatus.toInt() : 2;

    // Parse Apartment Details if present
    final rawApt = extraApartmentDetails ?? (rawData['apartmentDetails'] is Map ? rawData['apartmentDetails'] : null);
    final rawBedrooms = rawData['bedrooms'] ?? rawApt?['bedrooms'];
    final rawBathrooms = rawData['bathrooms'] ?? rawApt?['bathrooms'];
    final rawSize = rawData['propertySize'] ?? rawApt?['floorAreaSqFt'] ?? rawData['floorArea'];

    // Parse media
    final mediaList = <BuyerPropertyMediaItem>[];
    if (extraMedia != null && extraMedia.isNotEmpty) {
      for (final m in extraMedia) {
        mediaList.add(BuyerPropertyMediaItem.fromJson(m));
      }
    } else if (rawData['media'] is List) {
      for (final m in (rawData['media'] as List)) {
        if (m is Map) {
          mediaList.add(BuyerPropertyMediaItem.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return BuyerPropertyDetails(
      propertyId: (rawData['propertyId'] ?? rawData['id'] ?? '').toString(),
      referenceNo: (rawData['referenceNo'] ?? '').toString(),
      title: (rawData['title'] ?? 'Untitled Property').toString(),
      description: rawData['description']?.toString(),
      propertyTypeId: propTypeId,
      propertyTypeName: (rawData['propertyTypeName'] ?? _propertyTypeNames[propTypeId] ?? 'Property').toString(),
      listingTypeId: listingTypeId,
      listingTypeName: (rawData['listingTypeName'] ?? _listingTypeNames[listingTypeId] ?? 'For Sale').toString(),
      askingPrice: priceVal,
      formattedPrice: _formatCurrency(priceVal),
      isNegotiable: rawData['isNegotiable'] == true,
      provinceId: (rawData['provinceId'] as num?)?.toInt(),
      provinceName: rawData['provinceName']?.toString(),
      districtId: (rawData['districtId'] as num?)?.toInt(),
      districtName: rawData['districtName']?.toString(),
      cityId: (rawData['cityId'] as num?)?.toInt(),
      city: (rawData['city'] ?? rawData['cityName'])?.toString(),
      addressLine1: rawData['addressLine1']?.toString(),
      addressLine2: rawData['addressLine2']?.toString(),
      postalCode: rawData['postalCode']?.toString(),
      divisionalSecretariatName: rawData['divisionalSecretariatName']?.toString() ??
          rawData['divisionalSecretariat']?['name']?.toString() ??
          rawData['dsDivision']?.toString(),
      gnDivisionName: rawData['gramaNiladhariName']?.toString() ??
          rawData['gramaNiladhariDivision']?['name']?.toString() ??
          rawData['gnDivision']?.toString(),
      latitude: (rawData['latitude'] as num?)?.toDouble(),
      longitude: (rawData['longitude'] as num?)?.toDouble(),
      bedrooms: (rawBedrooms as num?)?.toInt(),
      bathrooms: (rawBathrooms as num?)?.toInt(),
      propertySize: (rawSize as num?)?.toDouble(),
      sizeUnit: (rawData['sizeUnit'] ?? rawData['areaUnit'] ?? 'sq.ft')?.toString(),
      status: statusId,
      statusName: (rawData['statusName'] ?? (statusId == 2 ? 'Published' : 'Status #$statusId')).toString(),
      isFavorite: isFav ?? (rawData['isFavorite'] == true),
      media: mediaList,
      features: extraFeatures ??
          (rawData['features'] is List
              ? (rawData['features'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : const []),
      amenities: extraAmenities ??
          (rawData['amenities'] is List
              ? (rawData['amenities'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : const []),
      financials: extraFinancials ?? (rawData['financials'] is Map ? Map<String, dynamic>.from(rawData['financials'] as Map) : null),
      legalDetails: extraLegalDetails ?? (rawData['legalDetails'] is Map ? Map<String, dynamic>.from(rawData['legalDetails'] as Map) : null),
      apartmentDetails: extraApartmentDetails ?? (rawData['apartmentDetails'] is Map ? Map<String, dynamic>.from(rawData['apartmentDetails'] as Map) : null),
      publishedAt: rawData['publishedAt'] != null ? DateTime.tryParse(rawData['publishedAt'].toString()) : null,
      createdAt: rawData['createdAt'] != null ? DateTime.tryParse(rawData['createdAt'].toString()) : null,
      agentUserId: rawData['agentUserId']?.toString(),
      agentName: rawData['agentName']?.toString(),
      agentPhoneNumber: rawData['agentPhoneNumber']?.toString(),
    );
  }

  BuyerPropertyDetails copyWith({
    bool? isFavorite,
    List<BuyerPropertyMediaItem>? media,
    List<Map<String, dynamic>>? features,
    List<Map<String, dynamic>>? amenities,
    String? agentUserId,
    String? agentName,
    String? agentPhoneNumber,
  }) {
    return BuyerPropertyDetails(
      propertyId: propertyId,
      referenceNo: referenceNo,
      title: title,
      description: description,
      propertyTypeId: propertyTypeId,
      propertyTypeName: propertyTypeName,
      listingTypeId: listingTypeId,
      listingTypeName: listingTypeName,
      askingPrice: askingPrice,
      formattedPrice: formattedPrice,
      isNegotiable: isNegotiable,
      provinceId: provinceId,
      provinceName: provinceName,
      districtId: districtId,
      districtName: districtName,
      cityId: cityId,
      city: city,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      propertySize: propertySize,
      sizeUnit: sizeUnit,
      status: status,
      statusName: statusName,
      isFavorite: isFavorite ?? this.isFavorite,
      media: media ?? this.media,
      features: features ?? this.features,
      amenities: amenities ?? this.amenities,
      financials: financials,
      legalDetails: legalDetails,
      publishedAt: publishedAt,
      createdAt: createdAt,
      agentUserId: agentUserId ?? this.agentUserId,
      agentName: agentName ?? this.agentName,
      agentPhoneNumber: agentPhoneNumber ?? this.agentPhoneNumber,
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.trim().isNotEmpty) {
      parts.add(addressLine1!.trim());
    }
    if (addressLine2 != null && addressLine2!.trim().isNotEmpty) {
      parts.add(addressLine2!.trim());
    }
    if (city != null && city!.trim().isNotEmpty) {
      parts.add(city!.trim());
    }
    if (districtName != null && districtName!.trim().isNotEmpty && districtName != city) {
      parts.add(districtName!.trim());
    }
    if (postalCode != null && postalCode!.trim().isNotEmpty) {
      parts.add(postalCode!.trim());
    }
    return parts.isEmpty ? 'Address not specified' : parts.join(', ');
  }
}
