import 'package:flutter/material.dart';
import '../../models/buyer_property_list_item.dart';

class BuyerPropertyCard extends StatefulWidget {
  final BuyerPropertyListItem property;
  final VoidCallback? onTap;
  final Future<bool> Function(String propertyId, bool currentlyFavorite)? onFavoriteToggle;

  const BuyerPropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<BuyerPropertyCard> createState() => _BuyerPropertyCardState();
}

class _BuyerPropertyCardState extends State<BuyerPropertyCard> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color pinkAccent = Color(0xFFFF2D7A);

  late bool _isFavorite;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.property.isFavorite;
  }

  @override
  void didUpdateWidget(covariant BuyerPropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.isFavorite != widget.property.isFavorite) {
      _isFavorite = widget.property.isFavorite;
    }
  }

  Future<void> _handleFavoriteTap() async {
    if (_isTogglingFavorite || widget.onFavoriteToggle == null) return;

    final previousState = _isFavorite;
    final newState = !previousState;

    // Optimistic UI update
    setState(() {
      _isFavorite = newState;
      _isTogglingFavorite = true;
    });

    try {
      final success = await widget.onFavoriteToggle!(
        widget.property.propertyId,
        previousState,
      );

      if (!mounted) return;

      if (!success) {
        // Revert on failure
        setState(() {
          _isFavorite = previousState;
          _isTogglingFavorite = false;
        });
      } else {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Revert on error
      setState(() {
        _isFavorite = previousState;
        _isTogglingFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.property;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Property Image Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: const Color(0xFFF3F4F6),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: primaryCyan,
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),

                  // Top Tags: Property Type & Listing Type
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.propertyTypeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.listingTypeId == 2
                                ? Colors.teal.withValues(alpha: 0.90)
                                : primaryCyan.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.listingTypeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top-Right Favorite Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _handleFavoriteTap,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isTogglingFavorite
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: pinkAccent,
                                    ),
                                  )
                                : Icon(
                                    _isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 21,
                                    color: _isFavorite ? pinkAccent : const Color(0xFF6B7280),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Property Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Row
                    Row(
                      children: [
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (item.isNegotiable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Negotiable',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primaryCyan,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (item.referenceNo.isNotEmpty)
                          Text(
                            '#${item.referenceNo}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Location (District / City / Area)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),

                    // Specs Row: Bedrooms, Bathrooms, Size
                    Row(
                      children: [
                        if (item.bedrooms != null && item.bedrooms! > 0) ...[
                          _buildSpecBadge(
                            icon: Icons.king_bed_outlined,
                            text: '${item.bedrooms} Beds',
                          ),
                          const SizedBox(width: 14),
                        ],
                        if (item.bathrooms != null && item.bathrooms! > 0) ...[
                          _buildSpecBadge(
                            icon: Icons.bathtub_outlined,
                            text: '${item.bathrooms} Baths',
                          ),
                          const SizedBox(width: 14),
                        ],
                        if (item.propertySize != null && item.propertySize! > 0)
                          _buildSpecBadge(
                            icon: Icons.square_foot_rounded,
                            text: '${item.propertySize!.toStringAsFixed(0)} ${item.sizeUnit ?? 'sq.ft'}',
                          ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: primaryCyan,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: primaryCyan.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 44,
              color: primaryCyan.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'ZoGo Real Estate',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}
