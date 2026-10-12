class AgentPropertyItem {
  final String propertyId;
  final String title;
  final double price;
  final String? referenceNo;
  final String? addressLine1;
  final int districtId;
  final String districtName;
  final String sellerUserId;
  final String sellerName;
  final String? sellerPhone;
  final String buyerUserId;
  final String buyerName;
  final String? buyerPhone;
  final int interestStatus;
  final int interactionStatus;

  const AgentPropertyItem({
    required this.propertyId,
    required this.title,
    required this.price,
    this.referenceNo,
    this.addressLine1,
    required this.districtId,
    required this.districtName,
    required this.sellerUserId,
    required this.sellerName,
    this.sellerPhone,
    required this.buyerUserId,
    required this.buyerName,
    this.buyerPhone,
    required this.interestStatus,
    required this.interactionStatus,
  });

  factory AgentPropertyItem.fromJson(Map<String, dynamic> json) {
    final districtMap = json['district'] as Map<String, dynamic>? ?? {};
    final sellerMap = json['seller'] as Map<String, dynamic>? ?? {};
    final buyerMap = json['buyer'] as Map<String, dynamic>? ?? {};

    return AgentPropertyItem(
      propertyId: json['propertyId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Property',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      referenceNo: json['referenceNo']?.toString(),
      addressLine1: json['addressLine1']?.toString(),
      districtId: (districtMap['id'] as num?)?.toInt() ?? 0,
      districtName: districtMap['name']?.toString() ?? 'Unknown District',
      sellerUserId: sellerMap['userId']?.toString() ?? '',
      sellerName: sellerMap['name']?.toString() ?? 'Unknown Seller',
      sellerPhone: sellerMap['phoneNumber']?.toString(),
      buyerUserId: buyerMap['userId']?.toString() ?? '',
      buyerName: buyerMap['name']?.toString() ?? 'Unknown Buyer',
      buyerPhone: buyerMap['phoneNumber']?.toString(),
      interestStatus: (json['interestStatus'] as num?)?.toInt() ?? 1,
      interactionStatus: (json['interactionStatus'] as num?)?.toInt() ?? 1,
    );
  }

  String get interactionStatusLabel {
    switch (interactionStatus) {
      case 1:
        return 'Interested';
      case 2:
        return 'Visit Requested';
      case 3:
        return 'Visited';
      case 4:
        return 'Documents Requested';
      case 5:
        return 'Negotiating';
      case 6:
        return 'Offer Accepted';
      default:
        return 'Status $interactionStatus';
    }
  }
}
