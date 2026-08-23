import 'package:flutter/material.dart';

class FeaturedPropertyCard extends StatelessWidget {
  const FeaturedPropertyCard({
    super.key,
    required this.imageUrl,
    required this.price,
    required this.title,
    required this.location,
    required this.beds,
    required this.baths,
    required this.area,
    this.onFavorite,
  });

  final String imageUrl;
  final String price;
  final String title;
  final String location;
  final String beds;
  final String baths;
  final String area;
  final VoidCallback? onFavorite;

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color accentPink = Color(0xFFFF2D7A);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF687386);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 205,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        color: const Color(0xFFE6F9FB),
                        child: const Icon(
                          Icons.home_outlined,
                          size: 60,
                          color: primaryCyan,
                        ),
                      );
                    },
                  ),
                ),

                // Property status
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryCyan,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FOR SALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onFavorite,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: accentPink,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Property information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    title,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: primaryCyan,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _PropertyFeature(
                        icon: Icons.bed_outlined,
                        value: beds,
                      ),
                      const SizedBox(width: 18),

                      _PropertyFeature(
                        icon: Icons.bathtub_outlined,
                        value: baths,
                      ),
                      const SizedBox(width: 18),

                      _PropertyFeature(
                        icon: Icons.square_foot_outlined,
                        value: area,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyFeature extends StatelessWidget {
  const _PropertyFeature({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF687386),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF687386),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}