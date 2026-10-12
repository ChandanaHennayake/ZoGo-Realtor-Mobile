class FavoriteStatus {
  final String propertyId;
  final bool isFavorite;

  const FavoriteStatus({
    required this.propertyId,
    required this.isFavorite,
  });

  factory FavoriteStatus.fromJson(String propertyId, dynamic json) {
    if (json is bool) {
      return FavoriteStatus(propertyId: propertyId, isFavorite: json);
    }
    if (json is Map<String, dynamic>) {
      final data = json['data'] is Map ? json['data'] : json;
      final isFav = data['isFavorite'] == true ||
          data['IsFavorite'] == true ||
          data['favorite'] == true;
      return FavoriteStatus(propertyId: propertyId, isFavorite: isFav);
    }
    return FavoriteStatus(propertyId: propertyId, isFavorite: false);
  }
}
