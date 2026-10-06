import 'package:flutter/material.dart';
import 'package:zogo_realtor/core/constants/api_constants.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_amenities_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_basic_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_features_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_financials_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_legal_details_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_documents_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_media_screen.dart';

class SellerPropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic>? initialData;

  const SellerPropertyDetailsScreen({
    super.key,
    required this.propertyId,
    this.initialData,
  });

  @override
  State<SellerPropertyDetailsScreen> createState() =>
      _SellerPropertyDetailsScreenState();
}

class _SellerPropertyDetailsScreenState
    extends State<SellerPropertyDetailsScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  final SellerService _sellerService = SellerService();
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _isLoading = true;
  bool _isPublishing = false;
  String? _errorMessage;
  String? _accessToken;

  Map<String, dynamic> _property = {};
  List<Map<String, dynamic>> _propertyStatuses =
      List.from(SellerService.defaultPropertyStatuses);
  List<Map<String, dynamic>> _media = [];
  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _amenities = [];
  Map<String, dynamic>? _financials;
  Map<String, dynamic>? _legalDetails;
  List<Map<String, dynamic>> _documents = [];

  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  static const Map<int, String> _propertyTypes = {
    1: 'House',
    2: 'Apartment',
    3: 'Land',
    4: 'Commercial',
  };

  static const Map<int, String> _listingTypes = {
    1: 'For Sale',
    2: 'For Rent',
  };

  static const Map<int, String> _periodNames = {
    1: 'Monthly',
    2: 'Quarterly',
    3: 'Half-Yearly',
    4: 'Annually',
  };

  static const Map<int, String> _ownershipTypes = {
    1: 'Freehold',
    2: 'Leasehold',
    3: 'Condominium Title',
    4: 'Joint Ownership',
    5: 'Power of Attorney',
  };

  // Known feature icon lookups
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
    18: Icons.grass_outlined,
    19: Icons.store_mall_directory_outlined,
    20: Icons.speed_outlined,
  };

  // Known amenity icon lookups
  static const Map<int, IconData> _amenityIcons = {
    1: Icons.pool_outlined,
    2: Icons.fitness_center_outlined,
    3: Icons.shield_outlined,
    4: Icons.diversity_3_outlined,
    5: Icons.garage_outlined,
    6: Icons.local_parking_outlined,
    7: Icons.park_outlined,
    8: Icons.bolt_outlined,
    9: Icons.elevator_outlined,
    10: Icons.videocam_outlined,
    11: Icons.deck_outlined,
    12: Icons.yard_outlined,
    13: Icons.cleaning_services_outlined,
    14: Icons.sports_tennis_outlined,
    15: Icons.sports_basketball_outlined,
    16: Icons.menu_book_outlined,
    17: Icons.business_outlined,
    18: Icons.local_laundry_service_outlined,
    19: Icons.pets_outlined,
    20: Icons.wifi_outlined,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _property = Map<String, dynamic>.from(widget.initialData!);
    }
    _loadAllPropertyData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPropertyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _accessToken = await _secureStorage.getAccessToken();

      // Load main details, statuses, media, features, amenities, financials, legal, documents in parallel
      final results = await Future.wait([
        _sellerService.getPropertyById(widget.propertyId).catchError((_) => _property),
        _sellerService.getPropertyMedia(widget.propertyId).catchError((_) => <Map<String, dynamic>>[]),
        _sellerService.getPropertyFeatures(widget.propertyId).catchError((_) => <Map<String, dynamic>>[]),
        _sellerService.getPropertyAmenities(widget.propertyId).catchError((_) => <Map<String, dynamic>>[]),
        _sellerService.getPropertyFinancials(widget.propertyId).catchError((_) => null),
        _sellerService.getPropertyLegalDetails(widget.propertyId).catchError((_) => null),
        _sellerService.getPropertyDocuments(widget.propertyId).catchError((_) => <Map<String, dynamic>>[]),
        _sellerService.getPropertyStatuses().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0] is Map<String, dynamic> && (results[0] as Map).isNotEmpty) {
          _property = results[0] as Map<String, dynamic>;
        }
        _media = results[1] as List<Map<String, dynamic>>;
        _features = results[2] as List<Map<String, dynamic>>;
        _amenities = results[3] as List<Map<String, dynamic>>;
        _financials = results[4] as Map<String, dynamic>?;
        _legalDetails = results[5] as Map<String, dynamic>?;
        _documents = results[6] as List<Map<String, dynamic>>;
        final fetchedStatuses = results[7] as List<Map<String, dynamic>>;
        if (fetchedStatuses.isNotEmpty) {
          _propertyStatuses = fetchedStatuses;
        }
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

  bool get _isDraft {
    final status = _property['status'] ?? _property['propertyStatus'];
    if (status == null) return true;
    if (status == 1 || status == '1' || status.toString().toLowerCase() == 'draft') {
      return true;
    }
    return false;
  }

  String _getPropertyStatusName() {
    final rawName = _property['statusName']?.toString();
    if (rawName != null && rawName.trim().isNotEmpty) {
      return rawName.trim();
    }
    final rawStatus = (_property['status'] as num?)?.toInt() ?? 1;
    final match = _propertyStatuses.firstWhere(
      (s) => (s['id'] as num?)?.toInt() == rawStatus,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty && match['name'] != null) {
      return match['name'].toString();
    }
    return rawStatus == 1 ? 'Draft' : 'Status #$rawStatus';
  }

  ({Color bg, Color border, Color text, IconData icon}) _getStatusVisuals(
      int statusId, String statusName) {
    final lower = statusName.toLowerCase();
    if (statusId == 1 || lower.contains('draft')) {
      return (
        bg: Colors.amber.shade50,
        border: Colors.amber.shade400,
        text: Colors.amber.shade900,
        icon: Icons.edit_note_rounded,
      );
    } else if (statusId == 2 ||
        lower.contains('published') ||
        lower.contains('live')) {
      return (
        bg: Colors.green.shade50,
        border: Colors.green.shade400,
        text: Colors.green.shade800,
        icon: Icons.check_circle_rounded,
      );
    } else if (statusId == 3 || lower.contains('review')) {
      return (
        bg: Colors.blue.shade50,
        border: Colors.blue.shade400,
        text: Colors.blue.shade800,
        icon: Icons.hourglass_top_rounded,
      );
    } else if (statusId == 4 || lower.contains('pending')) {
      return (
        bg: Colors.deepPurple.shade50,
        border: Colors.deepPurple.shade400,
        text: Colors.deepPurple.shade800,
        icon: Icons.pending_actions_rounded,
      );
    } else if (statusId == 5 || lower.contains('sold')) {
      return (
        bg: Colors.red.shade50,
        border: Colors.red.shade400,
        text: Colors.red.shade800,
        icon: Icons.sell_rounded,
      );
    } else if (statusId == 6 || lower.contains('rented')) {
      return (
        bg: Colors.teal.shade50,
        border: Colors.teal.shade400,
        text: Colors.teal.shade800,
        icon: Icons.vpn_key_rounded,
      );
    } else if (statusId == 7 || lower.contains('suspended')) {
      return (
        bg: Colors.orange.shade50,
        border: Colors.orange.shade400,
        text: Colors.orange.shade800,
        icon: Icons.pause_circle_outline_rounded,
      );
    } else {
      return (
        bg: const Color(0xFFF3F4F6),
        border: Colors.grey.shade400,
        text: const Color(0xFF374151),
        icon: Icons.info_outline_rounded,
      );
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final numVal = num.tryParse(value.toString());
    if (numVal == null) return value.toString();
    final parts = numVal.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  Future<void> _publishProperty() async {
    if (_isPublishing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.publish, color: primaryCyan),
            SizedBox(width: 8),
            Text('Publish Property'),
          ],
        ),
        content: const Text(
          'Are you ready to publish this property listing? It will become visible to all buyers and renters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      await _sellerService.publishProperty(widget.propertyId);

      if (!mounted) return;

      setState(() {
        _isPublishing = false;
        _property['status'] = 2; // Published
        _property['statusName'] = 'Published';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Property published successfully and is now Live!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );

      _loadAllPropertyData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSectionPicker() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Section to Edit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can start or modify any section of your listing:',
              style: TextStyle(fontSize: 13, color: secondaryGray),
            ),
            const SizedBox(height: 18),
            _buildSectionTile(
              stepNumber: 1,
              title: 'Basic Details',
              subtitle: 'Type, title, location, and price',
              icon: Icons.edit_note_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyBasicScreen(
                      propertyId: widget.propertyId,
                      initialData: _property,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 2,
              title: 'Property Features',
              subtitle: 'Pool, garden, parking, elevator, etc.',
              icon: Icons.star_outline_rounded,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyFeaturesScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 3,
              title: 'Property Amenities',
              subtitle: 'Gym, security, playground, clubhouse, etc.',
              icon: Icons.pool_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyAmenitiesScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 4,
              title: 'Financials & Charges',
              subtitle: 'Maintenance, sinking fund, pending bills',
              icon: Icons.payments_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyFinancialsScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 5,
              title: 'Legal Details',
              subtitle: 'Ownership type, mortgage, legal verification',
              icon: Icons.gavel_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyLegalDetailsScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 6,
              title: 'Legal & Official Documents',
              subtitle: 'Title Deed, Survey Plan, approvals, and certificates',
              icon: Icons.folder_shared_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDocumentsScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
            _buildSectionTile(
              stepNumber: 7,
              title: 'Photos & Media',
              subtitle: 'Upload property photos and videos (10MB max)',
              icon: Icons.photo_library_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyMediaScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: primaryCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: secondaryGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _openFullScreenImage(int index) {
    if (_media.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          media: _media,
          initialIndex: index,
          propertyId: widget.propertyId,
          accessToken: _accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _property['title']?.toString() ?? 'Property Details',
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
          IconButton(
            tooltip: 'Edit Sections',
            icon: const Icon(Icons.edit_note, color: primaryCyan),
            onPressed: _showSectionPicker,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: darkText),
            onPressed: _loadAllPropertyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryCyan))
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  color: primaryCyan,
                  onRefresh: _loadAllPropertyData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageCarousel(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusAndPriceCard(),
                              const SizedBox(height: 16),
                              _buildLocationCard(),
                              const SizedBox(height: 16),
                              _buildOverviewCard(),
                              const SizedBox(height: 16),
                              _buildFeaturesCard(),
                              const SizedBox(height: 16),
                              _buildAmenitiesCard(),
                              const SizedBox(height: 16),
                              _buildFinancialsCard(),
                              const SizedBox(height: 16),
                              _buildLegalDetailsCard(),
                              const SizedBox(height: 16),
                              _buildDocumentsCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryGray, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllPropertyData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryCyan),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_media.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No photos uploaded yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyMediaScreen(
                      propertyId: widget.propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadAllPropertyData();
              },
              icon: const Icon(Icons.add_photo_alternate, color: primaryCyan),
              label: const Text('Add Photos', style: TextStyle(color: primaryCyan)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryCyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 270,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _media.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = _media[index];
              final mediaId = item['id']?.toString() ?? item['mediaId']?.toString() ?? '';
              final isCover = item['isCover'] == true;
              final mediaType = (item['mediaType'] as num?)?.toInt() ?? 1;

              final imageUrl =
                  '${ApiConstants.baseUrl}/api/v1/properties/${widget.propertyId}/media/$mediaId/download';

              return GestureDetector(
                onTap: () => _openFullScreenImage(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      headers: _accessToken != null
                          ? {'Authorization': 'Bearer $_accessToken'}
                          : null,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(color: primaryCyan),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    if (isCover)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryCyan,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (mediaType == 2)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Video',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // Image counter pill
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
              '${_currentImageIndex + 1} / ${_media.length}',
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

  Widget _buildStatusAndPriceCard() {
    final title = _property['title']?.toString() ?? 'Untitled Property';
    final askingPrice = _property['askingPrice'];
    final isNegotiable = _property['isNegotiable'] == true;
    final referenceNo = _property['referenceNo']?.toString();

    final statusId = (_property['status'] as num?)?.toInt() ?? 1;
    final statusName = _getPropertyStatusName();
    final statusVisuals = _getStatusVisuals(statusId, statusName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dynamic Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusVisuals.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusVisuals.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusVisuals.icon,
                      size: 16,
                      color: statusVisuals.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusVisuals.text,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (referenceNo != null && referenceNo.isNotEmpty)
                Text(
                  'Ref: $referenceNo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryGray,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: darkText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'LKR ${_formatCurrency(askingPrice)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryCyan,
                ),
              ),
              if (isNegotiable) ...[
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

  Widget _buildLocationCard() {
    final addressLine1 = _property['addressLine1']?.toString() ?? '';
    final addressLine2 = _property['addressLine2']?.toString() ?? '';
    final city = _property['city']?.toString() ?? '';
    final postalCode = _property['postalCode']?.toString() ?? '';
    final latitude = _property['latitude'];
    final longitude = _property['longitude'];

    final fullAddress = [
      if (addressLine1.isNotEmpty) addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (city.isNotEmpty) city,
      if (postalCode.isNotEmpty) postalCode,
    ].join(', ');

    return _buildCard(
      title: 'Location Information',
      icon: Icons.location_on_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyBasicScreen(
                propertyId: widget.propertyId,
                initialData: _property,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.map_outlined, color: primaryCyan, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fullAddress.isEmpty ? 'Address not specified' : fullAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 10),
            Text(
              'Coordinates: $latitude, $longitude',
              style: const TextStyle(fontSize: 12, color: secondaryGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final propertyTypeId = (_property['propertyTypeId'] as num?)?.toInt() ?? 1;
    final listingTypeId = (_property['listingTypeId'] as num?)?.toInt() ?? 1;
    final description = _property['description']?.toString() ?? '';

    return _buildCard(
      title: 'Overview & Description',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadgeItem(
                label: 'Type',
                value: _propertyTypes[propertyTypeId] ?? 'Property',
                icon: Icons.home_outlined,
              ),
              const SizedBox(width: 12),
              _buildBadgeItem(
                label: 'Listing',
                value: _listingTypes[listingTypeId] ?? 'For Sale',
                icon: Icons.sell_outlined,
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryCyan, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: secondaryGray),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';

    return _buildCard(
      title: 'Property Features (${_features.length})',
      icon: Icons.star_outline_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyFeaturesScreen(
                propertyId: widget.propertyId,
                propertyType: typeName,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: _features.isEmpty
          ? const Text(
              'No features selected yet.',
              style: TextStyle(color: secondaryGray, fontSize: 13),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _features.map((f) {
                final featureId = (f['featureId'] ?? f['FeatureId'] ?? f['id']) as num?;
                final featureName = f['featureName']?.toString() ??
                    f['FeatureName']?.toString() ??
                    'Feature';
                final icon = featureId != null
                    ? (_featureIcons[featureId.toInt()] ?? Icons.check_circle_outline)
                    : Icons.check_circle_outline;

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
                        featureName,
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
    );
  }

  Widget _buildAmenitiesCard() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';

    return _buildCard(
      title: 'Property Amenities (${_amenities.length})',
      icon: Icons.pool_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyAmenitiesScreen(
                propertyId: widget.propertyId,
                propertyType: typeName,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: _amenities.isEmpty
          ? const Text(
              'No amenities selected yet.',
              style: TextStyle(color: secondaryGray, fontSize: 13),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenities.map((a) {
                final amenityId = (a['amenityId'] ?? a['AmenityId'] ?? a['id']) as num?;
                final amenityName = a['amenityName']?.toString() ??
                    a['AmenityName']?.toString() ??
                    'Amenity';
                final icon = amenityId != null
                    ? (_amenityIcons[amenityId.toInt()] ?? Icons.verified_outlined)
                    : Icons.verified_outlined;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: primaryCyan),
                      const SizedBox(width: 6),
                      Text(
                        amenityName,
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
    );
  }

  Widget _buildFinancialsCard() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';
    final fin = _financials;

    return _buildCard(
      title: 'Financials & Charges',
      icon: Icons.payments_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyFinancialsScreen(
                propertyId: widget.propertyId,
                propertyType: typeName,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: fin == null
          ? const Text(
              'No financial details entered yet.',
              style: TextStyle(color: secondaryGray, fontSize: 13),
            )
          : Column(
              children: [
                _buildInfoRow(
                  label: 'Maintenance Fee',
                  value:
                      'LKR ${_formatCurrency(fin['maintenanceFee'])} / ${_periodNames[(fin['maintenanceFeePeriod'] as num?)?.toInt()] ?? 'Monthly'}',
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  label: 'Sinking Fund',
                  value:
                      'LKR ${_formatCurrency(fin['sinkingFundAmount'])} / ${_periodNames[(fin['sinkingFundPeriod'] as num?)?.toInt()] ?? 'Monthly'}',
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  label: 'Utility Bills Status',
                  value: fin['billsUpToDate'] == true ? 'Up to Date' : 'Pending Bills',
                  valueColor: fin['billsUpToDate'] == true
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
                if (fin['hasOutstandingCharges'] == true) ...[
                  const Divider(height: 18),
                  _buildInfoRow(
                    label: 'Outstanding Amount',
                    value: 'LKR ${_formatCurrency(fin['outstandingAmount'])}',
                    valueColor: Colors.red.shade700,
                  ),
                  if (fin['outstandingDescription'] != null &&
                      fin['outstandingDescription'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Note: ${fin['outstandingDescription']}',
                        style: const TextStyle(fontSize: 12, color: secondaryGray),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _buildLegalDetailsCard() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';
    final legal = _legalDetails;

    return _buildCard(
      title: 'Legal Details',
      icon: Icons.gavel_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyLegalDetailsScreen(
                propertyId: widget.propertyId,
                propertyType: typeName,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: legal == null
          ? const Text(
              'No legal details entered yet.',
              style: TextStyle(color: secondaryGray, fontSize: 13),
            )
          : Column(
              children: [
                _buildInfoRow(
                  label: 'Ownership Type',
                  value: _ownershipTypes[(legal['ownershipType'] as num?)?.toInt()] ??
                      'Freehold',
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  label: 'Mortgage',
                  value: legal['hasMortgage'] == true
                      ? 'Yes (${legal['mortgageProvider'] ?? 'Provider not specified'})'
                      : 'None / Cleared',
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  label: 'Legal Disputes / Issues',
                  value: legal['hasLegalIssues'] == true
                      ? 'Disclosed (${legal['legalIssueDescription'] ?? ''})'
                      : 'None / Clear Title',
                  valueColor: legal['hasLegalIssues'] == true
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  label: 'Legal Verification',
                  value: legal['legalVerified'] == true ? 'Verified' : 'Pending',
                  valueColor: legal['legalVerified'] == true
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentsCard() {
    final typeName = _propertyTypes[_property['propertyTypeId']] ?? 'Property';

    return _buildCard(
      title: 'Legal & Official Documents (${_documents.length})',
      icon: Icons.folder_shared_outlined,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18, color: primaryCyan),
        tooltip: 'Manage Documents',
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDocumentsScreen(
                propertyId: widget.propertyId,
                propertyType: typeName,
              ),
            ),
          );
          if (res == true || mounted) _loadAllPropertyData();
        },
      ),
      child: _documents.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No documents uploaded yet. Uploading deeds and approvals helps buyers verify your listing faster.',
                  style: TextStyle(color: secondaryGray, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDocumentsScreen(
                          propertyId: widget.propertyId,
                          propertyType: typeName,
                        ),
                      ),
                    );
                    if (res == true || mounted) _loadAllPropertyData();
                  },
                  icon: const Icon(Icons.upload_file, size: 16, color: primaryCyan),
                  label: const Text(
                    'Upload Documents',
                    style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          : Column(
              children: _documents.map((doc) {
                final typeId = (doc['documentTypeId'] as num?)?.toInt() ?? 1;
                final docType = kPropertyDocumentTypes.firstWhere(
                  (t) => t.id == typeId,
                  orElse: () => PropertyDocumentType(
                    id: typeId,
                    name: 'Document #$typeId',
                    description: '',
                    icon: Icons.description_outlined,
                  ),
                );
                final fileName = doc['originalFileName']?.toString() ?? 'Document';
                final bytes = doc['fileSizeBytes'];
                final num b = bytes is num ? bytes : num.tryParse(bytes?.toString() ?? '0') ?? 0;
                final sizeText = b >= (1024 * 1024)
                    ? '${(b / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '${(b / 1024).toStringAsFixed(0)} KB';
                final status = doc['status'] as num? ?? 1;

                Color badgeBg;
                Color badgeFg;
                String badgeText;
                switch (status.toInt()) {
                  case 2:
                    badgeBg = Colors.amber.shade50;
                    badgeFg = Colors.amber.shade900;
                    badgeText = 'Under Review';
                    break;
                  case 3:
                    badgeBg = Colors.green.shade50;
                    badgeFg = Colors.green.shade700;
                    badgeText = 'Verified';
                    break;
                  case 4:
                    badgeBg = Colors.red.shade50;
                    badgeFg = Colors.red.shade700;
                    badgeText = 'Rejected';
                    break;
                  default:
                    badgeBg = const Color(0xFFE0F7FA);
                    badgeFg = const Color(0xFF00838F);
                    badgeText = 'Uploaded';
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(docType.icon, color: primaryCyan, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docType.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$fileName ($sizeText)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: secondaryGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(icon, color: primaryCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    final isDraft = _isDraft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showSectionPicker,
                icon: const Icon(Icons.edit_outlined, color: primaryCyan),
                label: const Text(
                  'Edit Sections',
                  style: TextStyle(
                    color: primaryCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: primaryCyan, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (isDraft) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : _publishProperty,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.publish, color: Colors.white),
                  label: Text(
                    _isPublishing ? 'Publishing...' : 'Publish Listing',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: primaryCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> media;
  final int initialIndex;
  final String propertyId;
  final String? accessToken;

  const _FullScreenImageViewer({
    required this.media,
    required this.initialIndex,
    required this.propertyId,
    this.accessToken,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.media.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.media.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final item = widget.media[index];
          final mediaId = item['id']?.toString() ?? item['mediaId']?.toString() ?? '';
          final imageUrl =
              '${ApiConstants.baseUrl}/api/v1/properties/${widget.propertyId}/media/$mediaId/download';

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                imageUrl,
                headers: widget.accessToken != null
                    ? {'Authorization': 'Bearer ${widget.accessToken}'}
                    : null,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, prog) {
                  if (prog == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 60, color: Colors.white54),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
