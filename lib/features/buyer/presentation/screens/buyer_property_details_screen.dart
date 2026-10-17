import 'package:flutter/material.dart';
import '../../data/services/buyer_favorite_service.dart';
import '../../data/services/buyer_property_interest_service.dart';
import '../../data/services/buyer_property_service.dart';
import '../../models/buyer_property_details.dart';
import '../../models/buyer_property_list_item.dart';
import '../../models/property_interest.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../widgets/buyer_interaction_section.dart';
import '../widgets/property_interest_section.dart';

class BuyerPropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  final BuyerPropertyListItem? initialItem;

  const BuyerPropertyDetailsScreen({
    super.key,
    required this.propertyId,
    this.initialItem,
  });

  @override
  State<BuyerPropertyDetailsScreen> createState() =>
      _BuyerPropertyDetailsScreenState();
}

class _BuyerPropertyDetailsScreenState
    extends State<BuyerPropertyDetailsScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color pinkAccent = Color(0xFFFF2D7A);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  final BuyerPropertyService _propertyService = BuyerPropertyService();
  final BuyerFavoriteService _favoriteService = BuyerFavoriteService();
  final PageController _pageController = PageController();

  BuyerPropertyDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  bool _isFavorite = false;
  bool _isTogglingFavorite = false;
  bool _isInterested = false;
  final GlobalKey<BuyerInteractionSectionState> _interactionKey =
      GlobalKey<BuyerInteractionSectionState>();

  // Feature icon mapping
  static const Map<int, IconData> _featureIcons = {
    1: Icons.pool_outlined,
    2: Icons.yard_outlined,
    3: Icons.balcony_outlined,
    4: Icons.local_parking_outlined,
    5: Icons.security_outlined,
    6: Icons.videocam_outlined,
    7: Icons.ac_unit_outlined,
    8: Icons.elevator_outlined,
    9: Icons.electrical_services_outlined,
    10: Icons.fitness_center_outlined,
    11: Icons.meeting_room_outlined,
    12: Icons.park_outlined,
    13: Icons.flare_outlined,
    14: Icons.water_drop_outlined,
    15: Icons.roofing_outlined,
    16: Icons.fence_outlined,
    17: Icons.deck_outlined,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _isFavorite = widget.initialItem!.isFavorite;
    }
    _loadPropertyDetails();
    _loadFavoriteState();
    _loadInitialInterest();
  }

  Future<void> _loadInitialInterest() async {
    try {
      final interest = await BuyerPropertyInterestService().getInterest(widget.propertyId);
      if (mounted) {
        setState(() {
          _isInterested = interest?.status == PropertyInterest.statusInterested;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _propertyService.dispose();
    _favoriteService.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _propertyService.getBuyerPropertyDetails(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final favStatus = await _favoriteService.checkFavorite(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _isFavorite = favStatus.isFavorite;
      });
    } catch (_) {}
  }

  Future<void> _handleToggleFavorite() async {
    if (_isTogglingFavorite) return;

    final prev = _isFavorite;
    final next = !prev;

    setState(() {
      _isFavorite = next;
      _isTogglingFavorite = true;
    });

    try {
      if (next) {
        await _favoriteService.addFavorite(widget.propertyId);
      } else {
        await _favoriteService.removeFavorite(widget.propertyId);
      }

      if (!mounted) return;
      setState(() {
        _isTogglingFavorite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next ? 'Property added to favorites!' : 'Property removed from favorites.',
          ),
          backgroundColor: next ? pinkAccent : const Color(0xFF374151),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFavorite = prev;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _details?.title ?? widget.initialItem?.title ?? 'Property Details',
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: darkText),
        actions: [
          // Favorite Action Button in AppBar
          IconButton(
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: _handleToggleFavorite,
            icon: _isTogglingFavorite
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: pinkAccent,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? pinkAccent : darkText,
                  ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadPropertyDetails();
              _loadFavoriteState();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _details == null ? null : _buildBottomChatBar(_details!),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _details == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryCyan),
            SizedBox(height: 16),
            Text(
              'Loading property details...',
              style: TextStyle(fontSize: 14, color: secondaryGray),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _details == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: secondaryGray),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadPropertyDetails,
                style: ElevatedButton.styleFrom(backgroundColor: primaryCyan),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final p = _details!;

    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: () async {
        await _loadPropertyDetails();
        await _loadFavoriteState();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Carousel
            _buildMediaCarousel(p),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Price & Status Card
                  _buildHeaderCard(p),

                  const SizedBox(height: 16),

                  // Overview & Specs Card (Bedrooms, Bathrooms, Size)
                  _buildOverviewSpecsCard(p),

                  const SizedBox(height: 16),

                  // Location Card
                  _buildLocationCard(p),

                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDescriptionCard(p),
                  ],

                  // Features Card
                  if (p.features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildFeaturesCard(p),
                  ],

                  // Amenities Card
                  if (p.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAmenitiesCard(p),
                  ],

                  const SizedBox(height: 20),

                  // PHASE 3: Property Interest Section
                  PropertyInterestSection(
                    propertyId: p.propertyId,
                    onInterestChanged: (interest) {
                      if (mounted) {
                        setState(() {
                          _isInterested = interest?.status == PropertyInterest.statusInterested;
                        });
                        _interactionKey.currentState?.reload();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // PHASE 4: Buyer Property Interaction Section
                  BuyerInteractionSection(
                    key: _interactionKey,
                    propertyId: p.propertyId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomChatBar(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: _isInterested
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Realtor Available',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Direct chat active for interested buyer',
                          style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            propertyId: p.propertyId,
                            propertyTitle: p.title,
                            recipientId: 'agent_${p.districtId}',
                            recipientName: 'Assigned Realtor (${p.districtName})',
                            recipientRole: 'agent',
                            currentUserRole: 'buyer',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryCyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text(
                      'Chat with Agent',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct agent chat unlocks when you mark "Interested" above.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMediaCarousel(BuyerPropertyDetails p) {
    if (p.media.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No photos available',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: p.media.length,
            onPageChanged: (idx) {
              setState(() {
                _currentImageIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final mediaItem = p.media[index];
              return Image.network(
                mediaItem.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),

        // Photo Index Pill
        Positioned(
          bottom: 12,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentImageIndex + 1} / ${p.media.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges: Type + Listing + Ref No
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.propertyTypeName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryCyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.listingTypeId == 2
                      ? Colors.teal.withValues(alpha: 0.12)
                      : primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.listingTypeName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.listingTypeId == 2 ? Colors.teal : primaryCyan,
                  ),
                ),
              ),
              const Spacer(),
              if (p.referenceNo.isNotEmpty)
                Text(
                  '#${p.referenceNo}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: darkText,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          // Price & Negotiable
          Row(
            children: [
              Text(
                p.formattedPrice,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryCyan,
                ),
              ),
              if (p.isNegotiable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Negotiable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryCyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSpecsCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview & Specifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (p.bedrooms != null && p.bedrooms! > 0)
                Expanded(
                  child: _buildSpecBox(
                    icon: Icons.king_bed_outlined,
                    label: 'Bedrooms',
                    value: '${p.bedrooms}',
                  ),
                ),
              if (p.bedrooms != null && p.bedrooms! > 0) const SizedBox(width: 10),
              if (p.bathrooms != null && p.bathrooms! > 0)
                Expanded(
                  child: _buildSpecBox(
                    icon: Icons.bathtub_outlined,
                    label: 'Bathrooms',
                    value: '${p.bathrooms}',
                  ),
                ),
              if (p.bathrooms != null && p.bathrooms! > 0) const SizedBox(width: 10),
              if (p.propertySize != null && p.propertySize! > 0)
                Expanded(
                  child: _buildSpecBox(
                    icon: Icons.square_foot_rounded,
                    label: 'Property Size',
                    value: '${p.propertySize!.toStringAsFixed(0)} ${p.sizeUnit ?? 'sq.ft'}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryCyan, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondaryGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: primaryCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          if (p.latitude != null && p.longitude != null) ...[
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${p.latitude}, ${p.longitude}',
              style: const TextStyle(fontSize: 12, color: secondaryGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this Property',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            p.description!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features & Highlights (${p.features.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.features.map((f) {
              final id = (f['featureId'] ?? f['FeatureId'] ?? f['id']) as num?;
              final name = (f['featureName'] ?? f['FeatureName'] ?? 'Feature').toString();
              final icon = id != null ? (_featureIcons[id.toInt()] ?? Icons.check_circle_outline) : Icons.check_circle_outline;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryCyan.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: primaryCyan),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard(BuyerPropertyDetails p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities (${p.amenities.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.amenities.map((a) {
              final name = (a['amenityName'] ?? a['AmenityName'] ?? a['name'] ?? 'Amenity').toString();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
