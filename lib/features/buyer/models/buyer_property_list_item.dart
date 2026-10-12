class BuyerPropertyListItem {
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
  final int? districtId;
  final String? districtName;
  final int? cityId;
  final String? city;
  final String? addressLine1;
  final String? addressLine2;
  final int? bedrooms;
  final int? bathrooms;
  final double? propertySize;
  final String? sizeUnit;
  final String? imageUrl;
  final int status;
  final String statusName;
  final bool isFavorite;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  const BuyerPropertyListItem({
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
    this.districtId,
    this.districtName,
    this.cityId,
    this.city,
    this.addressLine1,
    this.addressLine2,
    this.bedrooms,
    this.bathrooms,
    this.propertySize,
    this.sizeUnit,
    this.imageUrl,
    this.status = 2,
    this.statusName = 'Published',
    this.isFavorite = false,
    this.publishedAt,
    this.createdAt,
  });

  static const Map<int, String> _propertyTypeNames = {
    1: 'House',
    2: 'Apartment',
    3: 'Land',
    4: 'Commercial',
    5: 'Villa',
  };

  static const Map<int, String> _listingTypeNames = {
    1: 'For Sale',
    2: 'For Rent',
  };

  static String _resolvePropertyTypeName(int id, [String? fallback]) {
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    return _propertyTypeNames[id] ?? 'Property';
  }

  static String _resolveListingTypeName(int id, [String? fallback]) {
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    return _listingTypeNames[id] ?? (id == 2 ? 'For Rent' : 'For Sale');
  }

  factory BuyerPropertyListItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['propertyId'] ?? json['id'] ?? '';
    final rawPrice = json['askingPrice'] ?? json['price'] ?? 0;
    final priceVal = (rawPrice is num)
        ? rawPrice.toDouble()
        : (double.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);

    final rawPropType = json['propertyTypeId'] ?? json['typeId'] ?? 1;
    final propTypeId = (rawPropType is num) ? rawPropType.toInt() : 1;

    final rawListingType = json['listingTypeId'] ?? 1;
    final listingTypeId = (rawListingType is num) ? rawListingType.toInt() : 1;

    final rawStatus = json['status'] ?? json['propertyStatus'] ?? 2;
    final statusId = (rawStatus is num) ? rawStatus.toInt() : 2;

    // Handle image URL resolution
    String? imgUrl;
    if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      imgUrl = json['imageUrl'].toString();
    } else if (json['coverImageUrl'] != null && json['coverImageUrl'].toString().isNotEmpty) {
      imgUrl = json['coverImageUrl'].toString();
    } else if (json['coverImage'] != null && json['coverImage'].toString().isNotEmpty) {
      imgUrl = json['coverImage'].toString();
    } else if (json['media'] is List && (json['media'] as List).isNotEmpty) {
      final list = json['media'] as List;
      final cover = list.firstWhere(
        (m) => m is Map && (m['isCover'] == true || m['IsCover'] == true),
        orElse: () => list.first,
      );
      if (cover is Map) {
        imgUrl = (cover['mediaUrl'] ?? cover['url'] ?? cover['filePath'])?.toString();
      }
    }

    final rawBedrooms = json['bedrooms'] ?? json['beds'] ?? json['numberOfBedrooms'];
    final rawBathrooms = json['bathrooms'] ?? json['baths'] ?? json['numberOfBathrooms'];
    final rawSize = json['propertySize'] ?? json['floorArea'] ?? json['area'] ?? json['size'];

    return BuyerPropertyListItem(
      propertyId: rawId.toString(),
      referenceNo: (json['referenceNo'] ?? json['refNo'] ?? '').toString(),
      title: (json['title'] ?? json['propertyTitle'] ?? json['name'] ?? 'Untitled Property').toString(),
      description: json['description']?.toString(),
      propertyTypeId: propTypeId,
      propertyTypeName: _resolvePropertyTypeName(
        propTypeId,
        (json['propertyTypeName'] ?? json['typeName'])?.toString(),
      ),
      listingTypeId: listingTypeId,
      listingTypeName: _resolveListingTypeName(
        listingTypeId,
        (json['listingTypeName'] ?? json['listingType'])?.toString(),
      ),
      askingPrice: priceVal,
      formattedPrice: _formatCurrency(priceVal),
      isNegotiable: json['isNegotiable'] == true,
      provinceId: (json['provinceId'] as num?)?.toInt(),
      districtId: (json['districtId'] as num?)?.toInt(),
      districtName: json['districtName']?.toString(),
      cityId: (json['cityId'] as num?)?.toInt(),
      city: (json['city'] ?? json['cityName'])?.toString(),
      addressLine1: json['addressLine1']?.toString(),
      addressLine2: json['addressLine2']?.toString(),
      bedrooms: (rawBedrooms as num?)?.toInt(),
      bathrooms: (rawBathrooms as num?)?.toInt(),
      propertySize: (rawSize as num?)?.toDouble(),
      sizeUnit: (json['sizeUnit'] ?? json['areaUnit'] ?? 'sq.ft')?.toString(),
      imageUrl: imgUrl,
      status: statusId,
      statusName: (json['statusName'] ?? (statusId == 2 ? 'Published' : 'Status #$statusId')).toString(),
      isFavorite: json['isFavorite'] == true,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  BuyerPropertyListItem copyWith({
    bool? isFavorite,
    int? status,
    String? statusName,
  }) {
    return BuyerPropertyListItem(
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
      districtId: districtId,
      districtName: districtName,
      cityId: cityId,
      city: city,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      propertySize: propertySize,
      sizeUnit: sizeUnit,
      imageUrl: imageUrl,
      status: status ?? this.status,
      statusName: statusName ?? this.statusName,
      isFavorite: isFavorite ?? this.isFavorite,
      publishedAt: publishedAt,
      createdAt: createdAt,
    );
  }

  static String _formatCurrency(double amount) {
    if (amount <= 0) return 'Price upon request';
    final parts = amount.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rs. ${parts.replaceAll(reg, ',')}';
  }

  String get locationDisplay {
    final parts = <String>[];
    if (city != null && city!.trim().isNotEmpty) {
      parts.add(city!.trim());
    }
    if (districtName != null && districtName!.trim().isNotEmpty && districtName != city) {
      parts.add(districtName!.trim());
    } else if (addressLine1 != null && addressLine1!.trim().isNotEmpty && parts.isEmpty) {
      parts.add(addressLine1!.trim());
    }
    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }
}
