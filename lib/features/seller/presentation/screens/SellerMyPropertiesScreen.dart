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
  });

  /// Optional override. When null, this screen pushes
  /// CreatePropertyScreen using its own (live) context.
  final VoidCallback? onListProperty;

  @override
  State<SellerMyPropertiesScreen> createState() =>
      _SellerMyPropertiesScreenState();
}

class _SellerMyPropertiesScreenState extends State<SellerMyPropertiesScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  late final Dio _dio;
  final SecureStorageService _secureStorage = SecureStorageService();
  final SellerService _sellerService = SellerService();

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

      final response = await _dio.get(
        '/api/v1/properties/my',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    'DRAFT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
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
        centerTitle: true,
        title: const Text(
          'My Properties',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProperty,
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'List Property',
          style: TextStyle(fontWeight: FontWeight.w700),
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
            child: TextButton(
              onPressed: _loadProperties,
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: primaryCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_properties.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 46,
                color: primaryCyan,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No properties yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first listing to start reaching buyers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _properties.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final property = _properties[index];

        final title = _read(
          property,
          ['title', 'propertyTitle', 'name'],
          fallback: 'Untitled property',
        );

        final location = _read(
          property,
          ['city', 'location', 'address'],
          fallback: '—',
        );

        final isDraft = _isPropertyDraft(property);
        final status = isDraft ? 'Draft' : 'Published';

        final price = _read(
          property,
          ['price', 'askingPrice', 'amount'],
        );

        return Material(
          color: Colors.white,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_outlined,
                      color: primaryCyan,
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
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (price.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDraft
                              ? Colors.amber.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDraft
                                ? Colors.amber.shade300
                                : Colors.green.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDraft ? Icons.edit_note : Icons.check_circle,
                              size: 14,
                              color: isDraft
                                  ? Colors.amber.shade800
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDraft
                                    ? Colors.amber.shade900
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}