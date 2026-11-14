import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final bool isAgentView;
  final String? buyerName;
  final String? buyerPhoneNumber;
  final String? buyerUserId;
  final String? sellerName;
  final String? sellerPhoneNumber;

  const BuyerPropertyDetailsScreen({
    super.key,
    required this.propertyId,
    this.initialItem,
    this.isAgentView = false,
    this.buyerName,
    this.buyerPhoneNumber,
    this.buyerUserId,
    this.sellerName,
    this.sellerPhoneNumber,
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

                  if (p.apartmentDetails != null && p.apartmentDetails!.isNotEmpty) ...[
                    _buildApartmentDetailsCard(p),
                    const SizedBox(height: 16),
                  ],

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

                  if (p.financials != null) ...[
                    const SizedBox(height: 16),
                    _buildFinancialsCard(p),
                  ],

                  const SizedBox(height: 16),
                  _buildLegalVerificationCard(p),

                  if (widget.isAgentView) ...[
                    const SizedBox(height: 20),
                    _buildAgentBuyerOverviewCard(p),
                  ] else ...[
                    const SizedBox(height: 20),
                    // PHASE 3: Property Interest Section
                    PropertyInterestSection(
                      propertyId: p.propertyId,
                      propertyTitle: p.title,
                      agentName: p.agentName,
                      agentPhoneNumber: p.agentPhoneNumber,
                      agentUserId: p.agentUserId,
                      districtId: p.districtId,
                      districtName: p.districtName,
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
                      propertyTitle: p.title,
                      agentName: p.agentName,
                      agentPhoneNumber: p.agentPhoneNumber,
                      agentUserId: p.agentUserId,
                      districtId: p.districtId,
                      districtName: p.districtName,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomChatBar(BuyerPropertyDetails p) {
    if (widget.isAgentView) {
      final buyerName = (widget.buyerName != null && widget.buyerName!.trim().isNotEmpty)
          ? widget.buyerName!.trim()
          : 'Interested Buyer';
      final buyerPhone = (widget.buyerPhoneNumber != null && widget.buyerPhoneNumber!.trim().isNotEmpty)
          ? widget.buyerPhoneNumber!.trim()
          : '077 000 0000';
      final hasPhone = widget.buyerPhoneNumber != null && widget.buyerPhoneNumber!.trim().isNotEmpty;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
          top: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_pin_rounded, color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            buyerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BUYER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasPhone ? buyerPhone : 'Phone not provided',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasPhone ? const Color(0xFF10B981) : secondaryGray,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // CALL BUYER BUTTON
              IconButton.filled(
                tooltip: 'Call Buyer ($buyerPhone)',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.phone_rounded, size: 18),
                onPressed: () async {
                  final cleaned = buyerPhone.replaceAll(RegExp(r'[^\d+]'), '');
                  final uri = Uri.parse('tel:$cleaned');
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    debugPrint('Could not launch call: $e');
                  }
                },
              ),
              const SizedBox(width: 8),
              // CHAT WITH BUYER BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        propertyId: p.propertyId,
                        propertyTitle: p.title,
                        recipientId: widget.buyerUserId ?? 'buyer_${p.propertyId}',
                        recipientName: buyerName,
                        recipientRole: 'buyer',
                        currentUserRole: 'agent',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text(
                  'Chat Buyer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final agentName = p.agentName ?? 'Assigned Realtor';
    final agentPhone = p.agentPhoneNumber ?? '0770000002';
    final districtName = p.districtName ?? 'District';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: primaryCyan, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          agentName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isInterested) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Interested',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    agentPhone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: primaryCyan,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // DIRECT CALL BUTTON (Always accessible without requiring prior interest)
            IconButton.filled(
              tooltip: 'Direct Call Agent ($agentPhone)',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(10),
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              onPressed: () async {
                final cleaned = agentPhone.replaceAll(RegExp(r'[^\d+]'), '');
                final uri = Uri.parse('tel:$cleaned');
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Could not launch call: $e');
                }

                // Asynchronously record contact interaction in database so call activity is tracked
                try {
                  if (!_isInterested) {
                    await BuyerPropertyInterestService().setInterest(p.propertyId, PropertyInterest.statusInterested);
                    if (mounted) {
                      setState(() {
                        _isInterested = true;
                      });
                      _interactionKey.currentState?.reload();
                    }
                  }
                } catch (e) {
                  debugPrint('Could not track call interest: $e');
                }
              },
            ),
            const SizedBox(width: 8),
            // CHAT BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      propertyId: p.propertyId,
                      propertyTitle: p.title,
                      recipientId: p.agentUserId ?? 'agent_${p.districtId}',
                      recipientName: '$agentName ($districtName)',
                      recipientRole: 'agent',
                      currentUserRole: 'buyer',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: const Text(
                'Chat',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
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
    final ds = p.divisionalSecretariatName;
    final gn = p.gnDivisionName;

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
                'Location & Administrative Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Administrative Hierarchy Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'Province / District',
                  value: '${p.provinceName ?? '-'} / ${p.districtName ?? '-'}',
                ),
                if ((ds != null && ds.isNotEmpty) || (gn != null && gn.isNotEmpty)) ...[
                  const Divider(height: 16),
                  _buildInfoRow(
                    label: 'DS Division',
                    value: ds ?? 'Not specified',
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    label: 'GN Division',
                    value: gn ?? 'Not specified',
                  ),
                ],
                if (p.city != null || p.postalCode != null) ...[
                  const Divider(height: 16),
                  _buildInfoRow(
                    label: 'City / Postal Code',
                    value: '${p.city ?? '-'} ${p.postalCode != null ? '(${p.postalCode})' : ''}',
                  ),
                ],
              ],
            ),
          ),

          if (p.latitude != null && p.longitude != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined, size: 15, color: secondaryGray),
                const SizedBox(width: 6),
                Text(
                  'GPS Coordinates: ${p.latitude}, ${p.longitude}',
                  style: const TextStyle(fontSize: 12, color: secondaryGray),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApartmentDetailsCard(BuyerPropertyDetails p) {
    final apt = p.apartmentDetails ?? {};
    if (apt.isEmpty) return const SizedBox.shrink();

    final condoName = apt['condominiumName']?.toString() ?? 'Stand-alone / Complex';
    final aptTypeName = apt['apartmentTypeName']?.toString() ?? 'Apartment';
    final floorNumber = apt['floorNumber']?.toString() ?? '-';
    final unitNumber = apt['unitNumber']?.toString() ?? '-';
    final isCornerUnit = apt['isCornerUnit'] == true;
    final floorArea = apt['floorAreaSqFt'];
    final areaText = floorArea != null ? '${floorArea.toString()} Sq.Ft' : null;

    final bedroomCount = (apt['bedroomCount'] as num?)?.toInt() ?? p.bedrooms ?? 0;
    final masterBedroomCount = (apt['masterBedroomCount'] as num?)?.toInt() ?? 0;
    final bathroomCount = (apt['bathroomCount'] as num?)?.toInt() ?? p.bathrooms ?? 0;
    final attachedBathroomCount = (apt['attachedBathroomCount'] as num?)?.toInt() ?? 0;
    final balconyCount = (apt['balconyCount'] as num?)?.toInt() ?? 0;

    final viewTypeName = apt['viewTypeName']?.toString() ?? 'Standard View';
    final furnishingTypeName = apt['furnishingTypeName']?.toString() ?? 'Unfurnished';

    final List<String> utilitySpaces = [];
    if (apt['hasMaidRoom'] == true) utilitySpaces.add("Maid's Room");
    if (apt['hasMaidBathroom'] == true) utilitySpaces.add("Maid's Bathroom");
    if (apt['hasLaundryArea'] == true) utilitySpaces.add('Laundry Area');
    if (apt['hasStorageRoom'] == true) utilitySpaces.add('Storage Room');
    if (apt['hasWalkInCloset'] == true) utilitySpaces.add('Walk-in Closet');
    if (apt['hasDriversRoom'] == true) utilitySpaces.add("Driver's Quarters");

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
          Row(
            children: [
              const Icon(Icons.apartment_rounded, color: primaryCyan, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Apartment & Unit Specifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  aptTypeName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Condominium complex banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city_rounded, color: primaryCyan, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Condominium Complex',
                        style: TextStyle(fontSize: 11, color: secondaryGray),
                      ),
                      Text(
                        condoName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Unit Specs Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'Floor / Unit Number',
                  value: 'Floor $floorNumber (Unit #$unitNumber)',
                ),
                if (areaText != null) ...[
                  const Divider(height: 16),
                  _buildInfoRow(
                    label: 'Floor Area',
                    value: areaText,
                  ),
                ],
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'View Type',
                  value: viewTypeName,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'Furnishing Status',
                  value: furnishingTypeName,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'Bedrooms',
                  value: '$bedroomCount ($masterBedroomCount Master)',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'Bathrooms',
                  value: '$bathroomCount ($attachedBathroomCount Attached)',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'Balconies',
                  value: '$balconyCount',
                ),
                if (isCornerUnit) ...[
                  const Divider(height: 16),
                  _buildInfoRow(
                    label: 'Unit Position',
                    value: 'Corner Unit (Prime Exposure)',
                    valueColor: const Color(0xFF6366F1),
                  ),
                ],
              ],
            ),
          ),

          if (utilitySpaces.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Additional Spaces & Utility',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: utilitySpaces.map((space) {
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
                      const Icon(Icons.check_circle_outline, size: 14, color: primaryCyan),
                      const SizedBox(width: 6),
                      Text(
                        space,
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
        ],
      ),
    );
  }

  Widget _buildFinancialsCard(BuyerPropertyDetails p) {
    final fin = p.financials;
    if (fin == null) return const SizedBox.shrink();

    final maintFee = fin['maintenanceFee'];
    final sinkingFund = fin['sinkingFundAmount'];
    final billsUpToDate = fin['billsUpToDate'] == true;

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
              Icon(Icons.payments_outlined, color: primaryCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Financials & Maintenance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                if (maintFee != null) ...[
                  _buildInfoRow(
                    label: 'Maintenance Fee',
                    value: 'Rs. $maintFee / Month',
                  ),
                  const Divider(height: 16),
                ],
                if (sinkingFund != null) ...[
                  _buildInfoRow(
                    label: 'Sinking Fund',
                    value: 'Rs. $sinkingFund',
                  ),
                  const Divider(height: 16),
                ],
                _buildInfoRow(
                  label: 'Utility Bills',
                  value: billsUpToDate ? 'Up to date' : 'Pending clarification',
                  valueColor: billsUpToDate ? const Color(0xFF10B981) : Colors.orange.shade800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalVerificationCard(BuyerPropertyDetails p) {
    final legal = p.legalDetails;
    final isClear = legal != null ? legal['hasLegalIssues'] != true : true;
    final isVerified = legal != null ? legal['legalVerified'] == true : false;

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
              Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Title & Legal Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'Title Status',
                  value: isClear ? 'Clear Title Disclosed' : 'Pending Disclosures',
                  valueColor: isClear ? const Color(0xFF10B981) : Colors.orange.shade800,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  label: 'Legal Verification',
                  value: isVerified ? 'Verified by ZoGo Realtor' : 'Under Realtor Review',
                  valueColor: isVerified ? const Color(0xFF10B981) : secondaryGray,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: secondaryGray),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? darkText,
          ),
        ),
      ],
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
  Widget _buildAgentBuyerOverviewCard(BuyerPropertyDetails p) {
    final buyerName = (widget.buyerName != null && widget.buyerName!.trim().isNotEmpty)
        ? widget.buyerName!.trim()
        : 'Interested Buyer';
    final buyerPhone = (widget.buyerPhoneNumber != null && widget.buyerPhoneNumber!.trim().isNotEmpty)
        ? widget.buyerPhoneNumber!.trim()
        : 'Phone not provided';
    final sellerName = (widget.sellerName != null && widget.sellerName!.trim().isNotEmpty)
        ? widget.sellerName!.trim()
        : 'Property Seller';
    final sellerPhone = (widget.sellerPhoneNumber != null && widget.sellerPhoneNumber!.trim().isNotEmpty)
        ? widget.sellerPhoneNumber!.trim()
        : 'Phone not provided';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Realtor Console',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Direct Contact & Negotiation Hub',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'ACTIVE INQUIRY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),

          // Interested Buyer Contact Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INTERESTED BUYER',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), letterSpacing: 0.5),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Verified Buyer',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      child: Text(
                        buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'B',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyerName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                buyerPhone,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981), fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons for Buyer
                    IconButton.filled(
                      tooltip: 'Call Buyer',
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      onPressed: () async {
                        final cleaned = buyerPhone.replaceAll(RegExp(r'[^\d+]'), '');
                        final uri = Uri.parse('tel:$cleaned');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'Chat with Buyer',
                      style: IconButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.white),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              propertyId: p.propertyId,
                              propertyTitle: p.title,
                              recipientId: widget.buyerUserId ?? 'buyer_${p.propertyId}',
                              recipientName: buyerName,
                              recipientRole: 'buyer',
                              currentUserRole: 'agent',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Property Seller Details Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LISTING SELLER',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sellerName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sellerPhone,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Call Seller',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E293B)),
                    foregroundColor: const Color(0xFF10B981),
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  onPressed: () async {
                    final cleaned = sellerPhone.replaceAll(RegExp(r'[^\d+]'), '');
                    final uri = Uri.parse('tel:$cleaned');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
