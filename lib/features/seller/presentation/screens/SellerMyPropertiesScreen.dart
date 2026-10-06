import 'package:dio/dio.dart';
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
import 'package:zogo_realtor/features/seller/presentation/screens/seller_property_details_screen.dart';


/// Seller "My Properties" screen.
///
/// Backed by: GET /api/v1/properties/my
///
/// That endpoint sits behind [Authorize(Roles = "SEL")], so it returns 403
/// until the access token itself carries the SEL role claim.
class SellerMyPropertiesScreen extends StatefulWidget {
  const SellerMyPropertiesScreen({
    super.key,
    this.onListProperty,
    this.isEmbedded = false,
  });

  /// Optional override. When null, this screen pushes
  /// CreatePropertyScreen using its own (live) context.
  final VoidCallback? onListProperty;

  /// Whether this screen is displayed embedded within the main tabs
  final bool isEmbedded;

  @override
  State<SellerMyPropertiesScreen> createState() =>
      _SellerMyPropertiesScreenState();
}

class _SellerMyPropertiesScreenState extends State<SellerMyPropertiesScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  late final Dio _dio;
  final SecureStorageService _secureStorage = SecureStorageService();
  final SellerService _sellerService = SellerService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedStatusFilter = 0; // 0: All, or specific status ID from PropertyStatuses
  int? _selectedPropertyTypeId; // null: All, 1: House, 2: Apartment, 3: Land, 4: Commercial, 5: Villa
  String _sortBy = 'newest'; // 'newest', 'price_asc', 'price_desc', 'name_asc'
  List<Map<String, dynamic>> _propertyStatuses = SellerService.defaultPropertyStatuses;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _properties = const [];

  @override
  void initState() {
    super.initState();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      // Fetch properties & property statuses in parallel
      final results = await Future.wait([
        _dio.get(
          '/api/v1/properties/my',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          ),
        ),
        _sellerService.getPropertyStatuses().catchError((_) => SellerService.defaultPropertyStatuses),
      ]);

      final response = results[0] as Response;
      final statuses = results[1] as List<Map<String, dynamic>>;

      if (response.statusCode == 403) {
        throw Exception(
          'Your session does not carry the seller role yet. '
          'Please sign in again.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Could not load your properties (${response.statusCode}).',
        );
      }

      final data = response.data;

      final rawList = data is List
          ? data
          : (data is Map && data['items'] is List)
              ? data['items'] as List
              : (data is Map && data['data'] is List)
                  ? data['data'] as List
                  : const [];

      final parsed = rawList
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _properties = parsed;
        _propertyStatuses = statuses.isNotEmpty ? statuses : SellerService.defaultPropertyStatuses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

 Future<void> _openCreateProperty() async {
  final override = widget.onListProperty;

  if (override != null) {
    override();
    return;
  }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PropertyBasicScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      _loadProperties();
    }
  }

  /// Reads a value from a property map, ignoring key casing.
  String _read(
    Map<String, dynamic> item,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      for (final entry in item.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase() &&
            entry.value != null) {
          final text = entry.value.toString().trim();
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    return fallback;
  }

  bool _isPropertyDraft(Map<String, dynamic> property) {
    final rawStatus = property['status'] ?? property['propertyStatus'] ?? property['listingStatus'];
    if (rawStatus == null) return true;
    if (rawStatus == 1 || rawStatus == '1' || rawStatus.toString().toLowerCase() == 'draft') {
      return true;
    }
    return false;
  }

  int _getStatusCount(int statusId) {
    return _properties.where((p) {
      final s = (p['status'] as num?)?.toInt() ?? 1;
      return s == statusId;
    }).length;
  }

  String _getPropertyStatusName(Map<String, dynamic> property) {
    final rawName = property['statusName']?.toString();
    if (rawName != null && rawName.trim().isNotEmpty) {
      return rawName.trim();
    }
    final rawStatus = (property['status'] as num?)?.toInt() ?? 1;
    final match = _propertyStatuses.firstWhere(
      (s) => (s['id'] as num?)?.toInt() == rawStatus,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty && match['name'] != null) {
      return match['name'].toString();
    }
    return rawStatus == 1 ? 'Draft' : 'Status #$rawStatus';
  }

  ({Color bg, Color border, Color text, IconData icon}) _getStatusVisuals(int statusId, String statusName) {
    final lower = statusName.toLowerCase();
    if (statusId == 1 || lower.contains('draft')) {
      return (
        bg: Colors.amber.shade50,
        border: Colors.amber.shade400,
        text: Colors.amber.shade900,
        icon: Icons.edit_note_rounded,
      );
    } else if (statusId == 2 || lower.contains('published') || lower.contains('live')) {
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

  List<Map<String, dynamic>> get _filteredProperties {
    return _properties.where((item) {
      // 1. Dynamic Status filter
      if (_selectedStatusFilter != 0) {
        final itemStatus = (item['status'] as num?)?.toInt() ?? 1;
        if (itemStatus != _selectedStatusFilter) return false;
      }

      // 2. Property Type filter
      if (_selectedPropertyTypeId != null) {
        final rawTypeId = (item['propertyTypeId'] as num?)?.toInt() ??
            (item['typeId'] as num?)?.toInt();
        if (rawTypeId != _selectedPropertyTypeId) return false;
      }

      // 3. Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final title = _read(item, ['title', 'propertyTitle', 'name']).toLowerCase();
        final refNo = _read(item, ['referenceNo', 'referenceNumber', 'refNo']).toLowerCase();
        final city = _read(item, ['city', 'cityName', 'location', 'address']).toLowerCase();
        final id = _read(item, ['propertyId', 'id']).toLowerCase();

        final matches = title.contains(q) ||
            refNo.contains(q) ||
            city.contains(q) ||
            id.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'price_asc') {
          final pA = double.tryParse(_read(a, ['price', 'askingPrice']).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final pB = double.tryParse(_read(b, ['price', 'askingPrice']).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return pA.compareTo(pB);
        } else if (_sortBy == 'price_desc') {
          final pA = double.tryParse(_read(a, ['price', 'askingPrice']).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final pB = double.tryParse(_read(b, ['price', 'askingPrice']).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return pB.compareTo(pA);
        } else if (_sortBy == 'name_asc') {
          final tA = _read(a, ['title', 'propertyTitle', 'name']).toLowerCase();
          final tB = _read(b, ['title', 'propertyTitle', 'name']).toLowerCase();
          return tA.compareTo(tB);
        }
        return 0;
      });
  }

  Future<void> _openPropertyDetails(Map<String, dynamic> property) async {
    final propertyId = _read(property, ['propertyId', 'id']);
    if (propertyId.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerPropertyDetailsScreen(
          propertyId: propertyId,
          initialData: property,
        ),
      ),
    );

    if (result == true || mounted) {
      _loadProperties();
    }
  }

  Future<void> _publishDraftProperty(String propertyId) async {
    try {
      final success = await _sellerService.publishProperty(propertyId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property published successfully and is now live!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProperties();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish property: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showDraftActionsSheet(Map<String, dynamic> property) {
    final propertyId = _read(property, ['propertyId', 'id']);
    final title = _read(property, ['title', 'propertyTitle', 'name'], fallback: 'Draft Property');
    final typeId = (property['propertyTypeId'] as num?)?.toInt() ?? 1;
    const propertyTypes = {
      1: 'House',
      2: 'Apartment',
      3: 'Land',
      4: 'Commercial',
    };
    final typeName = propertyTypes[typeId] ?? 'Property';
    final statusId = (property['status'] as num?)?.toInt() ?? 1;
    final statusName = _getPropertyStatusName(property);
    final statusVisuals = _getStatusVisuals(statusId, statusName);

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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusVisuals.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusVisuals.border),
                  ),
                  child: Text(
                    statusName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusVisuals.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select any section below to start editing or resume your draft:',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            _buildSectionTile(
              stepNumber: 1,
              title: 'Basic Details',
              subtitle: 'Type, title, location, and asking price',
              icon: Icons.edit_note_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyBasicScreen(
                      propertyId: propertyId,
                      initialData: property,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
              },
            ),
            _buildSectionTile(
              stepNumber: 2,
              title: 'Property Features',
              subtitle: 'Pool, garden, balcony, parking, etc.',
              icon: Icons.star_outline_rounded,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyFeaturesScreen(
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
              },
            ),
            _buildSectionTile(
              stepNumber: 3,
              title: 'Property Amenities',
              subtitle: 'Security, clubhouse, elevator, generator, etc.',
              icon: Icons.pool_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyAmenitiesScreen(
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
              },
            ),
            _buildSectionTile(
              stepNumber: 4,
              title: 'Financials & Charges',
              subtitle: 'Maintenance, sinking fund, bills status',
              icon: Icons.payments_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyFinancialsScreen(
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
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
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
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
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
              },
            ),
            _buildSectionTile(
              stepNumber: 7,
              title: 'Photos & Media',
              subtitle: 'Images and videos (10MB limit per file)',
              icon: Icons.photo_library_outlined,
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyMediaScreen(
                      propertyId: propertyId,
                      propertyType: typeName,
                    ),
                  ),
                );
                if (res == true || mounted) _loadProperties();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openPropertyDetails(property);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: primaryCyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Preview',
                      style: TextStyle(
                        color: primaryCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _publishDraftProperty(propertyId);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: primaryCyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Publish Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: primaryCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isEmbedded,
        centerTitle: widget.isEmbedded,
        title: widget.isEmbedded
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'My Properties',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_properties.length}',
                      style: const TextStyle(
                        color: primaryCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )
            : const Text(
                'My Properties',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                ),
              ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadProperties,
          ),
          IconButton(
            tooltip: 'Sort Properties',
            icon: const Icon(Icons.sort_rounded, color: Color(0xFF1A1A1A)),
            onPressed: _showSortBottomSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProperty,
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'List Property',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryCyan,
          onRefresh: _loadProperties,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryCyan),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          const Icon(
            Icons.error_outline,
            size: 52,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadProperties,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    final filtered = _filteredProperties;
    final hasActiveFilter = _searchQuery.isNotEmpty ||
        _selectedStatusFilter != 0 ||
        _selectedPropertyTypeId != null ||
        _sortBy != 'newest';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Search and Filters Header
        SliverToBoxAdapter(
          child: _buildSearchAndFilters(),
        ),

        // 2. Results Header / Counter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} of ${_properties.length} properties',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (hasActiveFilter)
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryCyan,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 3. Properties List or Empty States
        if (_properties.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNoPropertiesEmptyState(),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNoSearchResultsState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 95),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildEnhancedPropertyCard(filtered[index]),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SEARCH & FILTERS
  // ============================================================

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by property name, ref no, city...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primaryCyan,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic Status Filter Tabs from PropertyStatuses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusTab(0, 'All', _properties.length),
                const SizedBox(width: 8),
                ..._propertyStatuses.map((st) {
                  final sId = (st['id'] as num?)?.toInt() ?? 0;
                  final sName = st['name']?.toString() ?? 'Status';
                  final count = _getStatusCount(sId);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatusTab(sId, sName, count),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Property Types Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(null, 'All Types'),
                _buildTypeChip(1, 'House'),
                _buildTypeChip(2, 'Apartment'),
                _buildTypeChip(3, 'Land'),
                _buildTypeChip(4, 'Commercial'),
                _buildTypeChip(5, 'Villa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(int statusIndex, String label, int count) {
    final isSelected = _selectedStatusFilter == statusIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusFilter = statusIndex;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryCyan : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryCyan : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(int? typeId, String label) {
    final isSelected = _selectedPropertyTypeId == typeId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedPropertyTypeId = isSelected ? null : typeId;
          });
        },
        selectedColor: primaryCyan.withValues(alpha: 0.15),
        checkmarkColor: primaryCyan,
        backgroundColor: const Color(0xFFF9FAFB),
        side: BorderSide(
          color: isSelected ? primaryCyan : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primaryCyan : const Color(0xFF374151),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedStatusFilter = 0;
      _selectedPropertyTypeId = null;
      _sortBy = 'newest';
    });
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sort Properties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(),
              _buildSortTile('newest', 'Newest First', Icons.access_time_rounded),
              _buildSortTile('name_asc', 'Property Name (A - Z)', Icons.sort_by_alpha_rounded),
              _buildSortTile('price_asc', 'Price: Low to High', Icons.arrow_upward_rounded),
              _buildSortTile('price_desc', 'Price: High to Low', Icons.arrow_downward_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile(String sortValue, String title, IconData icon) {
    final isSelected = _sortBy == sortValue;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryCyan : Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primaryCyan : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: primaryCyan)
          : null,
      onTap: () {
        setState(() {
          _sortBy = sortValue;
        });
        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // PROPERTY CARD DESIGN
  // ============================================================

  Widget _buildEnhancedPropertyCard(Map<String, dynamic> property) {
    final propertyId = _read(property, ['propertyId', 'id']);
    final title = _read(
      property,
      ['title', 'propertyTitle', 'name'],
      fallback: 'Untitled Property',
    );
    final refNo = _read(property, ['referenceNo', 'referenceNumber', 'refNo']);
    final location = _read(
      property,
      ['city', 'cityName', 'location', 'address'],
      fallback: 'Location pending',
    );
    final rawPrice = _read(property, ['price', 'askingPrice', 'amount']);
    final isDraft = _isPropertyDraft(property);
    final statusId = (property['status'] as num?)?.toInt() ?? 1;
    final statusName = _getPropertyStatusName(property);
    final statusVisuals = _getStatusVisuals(statusId, statusName);
    final typeId = (property['propertyTypeId'] as num?)?.toInt() ?? 1;

    const propertyTypes = {
      1: 'House',
      2: 'Apartment',
      3: 'Land',
      4: 'Commercial',
      5: 'Villa',
    };
    final typeName = propertyTypes[typeId] ?? 'Property';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isDraft) {
              _showDraftActionsSheet(property);
            } else {
              _openPropertyDetails(property);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar: Status + Ref No + Type
                Row(
                  children: [
                    // Dynamic Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                            size: 13,
                            color: statusVisuals.text,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusVisuals.text,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Property Type Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryCyan.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryCyan,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Reference Number
                    if (refNo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '#$refNo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Main Info Row: Icon & Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryCyan.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        color: primaryCyan,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
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
                          if (rawPrice.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              rawPrice.toLowerCase().contains('rs') || rawPrice.toLowerCase().contains('lkr')
                                  ? rawPrice
                                  : 'Rs. $rawPrice',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primaryCyan,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isDraft) ...[
                      // Continue Editing Button
                      OutlinedButton.icon(
                        onPressed: () => _showDraftActionsSheet(property),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: primaryCyan),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note, size: 16, color: primaryCyan),
                        label: const Text(
                          'Edit Draft',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 1-Click Publish Button
                      ElevatedButton.icon(
                        onPressed: () => _publishDraftProperty(propertyId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCyan,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: const Text(
                          'Publish',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => _openPropertyDetails(property),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          side: const BorderSide(color: primaryCyan),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16, color: primaryCyan),
                        label: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
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
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================

  Widget _buildNoPropertiesEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 42,
                color: primaryCyan,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No properties yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first listing to reach thousands of buyers on ZoGo Realtor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreateProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'List Your First Property',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching properties found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not find any properties matching "${_searchQuery.isNotEmpty ? _searchQuery : 'selected filters'}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryCyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16, color: primaryCyan),
              label: const Text(
                'Reset Search & Filters',
                style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}