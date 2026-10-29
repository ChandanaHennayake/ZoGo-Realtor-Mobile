import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_financials_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_features_screen.dart';

class PropertyAmenitiesScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyAmenitiesScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyAmenitiesScreen> createState() => _PropertyAmenitiesScreenState();
}

class _PropertyAmenitiesScreenState extends State<PropertyAmenitiesScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final SellerService _sellerService = SellerService();
  final Set<int> _selectedAmenityIds = {};

  List<Map<String, dynamic>> _masterAmenities = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _sellerService.getAmenities(),
        _sellerService.getPropertyAmenities(widget.propertyId),
      ]);

      _masterAmenities = futures[0];
      final existing = futures[1];

      for (final item in existing) {
        final id = (item['amenityId'] ?? item['AmenityId'] ?? item['id']) as num?;
        if (id != null) {
          _selectedAmenityIds.add(id.toInt());
        }
      }
    } catch (e) {
      debugPrint('Error loading amenities: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _categories {
    final set = <String>{'All'};
    for (final a in _masterAmenities) {
      final cat = a['category']?.toString();
      if (cat != null && cat.isNotEmpty) {
        set.add(cat);
      }
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredAmenities {
    if (_selectedCategory == 'All') return _masterAmenities;
    return _masterAmenities
        .where((a) => a['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _toggleAmenity(int id) {
    if (_isSaving) return;
    setState(() {
      if (_selectedAmenityIds.contains(id)) {
        _selectedAmenityIds.remove(id);
      } else {
        _selectedAmenityIds.add(id);
      }
    });
  }

  IconData _getAmenityIcon(String? iconName, String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('pool')) return Icons.pool_outlined;
    if (n.contains('gym') || n.contains('fitness')) return Icons.fitness_center_outlined;
    if (n.contains('secur') || n.contains('guard')) return Icons.shield_outlined;
    if (n.contains('cctv') || n.contains('surveil')) return Icons.videocam_outlined;
    if (n.contains('park') || n.contains('garage')) return Icons.local_parking_outlined;
    if (n.contains('elevat') || n.contains('lift')) return Icons.elevator_outlined;
    if (n.contains('power') || n.contains('generat') || n.contains('backup')) return Icons.bolt_outlined;
    if (n.contains('club') || n.contains('lounge')) return Icons.meeting_room_outlined;
    if (n.contains('play') || n.contains('kid')) return Icons.park_outlined;
    if (n.contains('garden') || n.contains('landscap')) return Icons.yard_outlined;
    if (n.contains('rooftop') || n.contains('deck') || n.contains('terrace')) return Icons.deck_outlined;
    if (n.contains('fire') || n.contains('alarm')) return Icons.fire_extinguisher_outlined;
    if (n.contains('ev') || n.contains('charg')) return Icons.ev_station_outlined;
    if (n.contains('sauna') || n.contains('spa') || n.contains('jacuzzi')) return Icons.hot_tub_outlined;
    if (n.contains('tennis') || n.contains('squash') || n.contains('badminton')) return Icons.sports_tennis_outlined;
    if (n.contains('cinema') || n.contains('theatre')) return Icons.theaters_outlined;
    if (n.contains('bbq')) return Icons.outdoor_grill_outlined;
    if (n.contains('concierge') || n.contains('recept')) return Icons.room_service_outlined;
    if (n.contains('water') || n.contains('tank')) return Icons.water_drop_outlined;
    if (n.contains('intercom')) return Icons.phone_in_talk_outlined;
    return Icons.domain_outlined;
  }

  Future<void> _saveAmenities({bool exitAfterSave = false}) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _sellerService.syncPropertyAmenities(
        widget.propertyId,
        _selectedAmenityIds,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Building facilities (${_selectedAmenityIds.length}) updated successfully!',
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );

      await _sellerService.setDraftStep(widget.propertyId, exitAfterSave ? 3 : 4);
      if (!mounted) return;

      if (exitAfterSave) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      // Navigate to Step 4: Financials
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyFinancialsScreen(
            propertyId: widget.propertyId,
            propertyType: widget.propertyType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save amenities: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeName = widget.propertyType ?? 'Apartment / Property';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Building Facilities & Amenities',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1A1A1A),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryCyan),
                    SizedBox(height: 16),
                    Text(
                      'Loading facilities from master table...',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgress(),
                          const SizedBox(height: 24),

                          const Text(
                            'Section 03 — Building Facilities',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Select the communal and building facilities available to residents (Basic, Lifestyle, Premium).',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildPropertyTypeCard(typeName),
                          const SizedBox(height: 18),

                          _buildCategoryFilter(),
                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCategory == 'All'
                                    ? 'All Facilities (${_filteredAmenities.length})'
                                    : '$_selectedCategory Facilities (${_filteredAmenities.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (_selectedAmenityIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryCyan.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_selectedAmenityIds.length} Selected',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryCyan,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildAmenityGrid(),
                          const SizedBox(height: 20),

                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _buildStepItem(number: '1', title: 'Basic', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '2', title: 'Details', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '3', title: 'Facilities', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '4', title: 'Financials', isCompleted: false, isActive: false),
          _buildStepLine(false),
          _buildStepItem(number: '5', title: 'Legal', isCompleted: false, isActive: false),
          _buildStepLine(false),
          _buildStepItem(number: '6', title: 'Media', isCompleted: false, isActive: false),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: isCompleted ? primaryCyan : const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? primaryCyan
                : (isCompleted ? primaryCyan : const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeCard(String propertyType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.domain_outlined,
              color: primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listing: ${widget.propertyId.length > 16 ? '${widget.propertyId.substring(0, 16)}...' : widget.propertyId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  propertyType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryCyan : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryCyan : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryCyan.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmenityGrid() {
    final list = _filteredAmenities;

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No amenities found for this category in the database.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final amenity = list[index];
        final id = (amenity['id'] as num).toInt();
        final name = amenity['name']?.toString() ?? 'Amenity';
        final cat = amenity['category']?.toString();
        final icon = _getAmenityIcon(amenity['icon']?.toString(), name);
        final isSelected = _selectedAmenityIds.contains(id);

        return InkWell(
          onTap: () => _toggleAmenity(id),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryCyan.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? primaryCyan : const Color(0xFFE5E7EB),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryCyan : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? primaryCyan : const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (cat != null && cat.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? primaryCyan.withValues(alpha: 0.8) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: primaryCyan,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryCyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select all amenities verified and operational in your condominium or housing complex.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyFeaturesScreen(
                          propertyId: widget.propertyId,
                          propertyType: widget.propertyType,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _saveAmenities(exitAfterSave: true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  side: const BorderSide(color: primaryCyan, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Save & Exit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryCyan,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveAmenities(exitAfterSave: false),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryCyan.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Save & Next',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 15),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
