import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zogo_realtor/core/constants/api_constants.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_basic_screen.dart';


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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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

        final status = _read(
          property,
          ['status', 'propertyStatus', 'listingStatus'],
          fallback: 'Draft',
        );

        final price = _read(
          property,
          ['price', 'askingPrice', 'amount'],
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}