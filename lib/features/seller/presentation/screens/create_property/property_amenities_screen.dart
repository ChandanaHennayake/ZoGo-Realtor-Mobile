import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_financials_screen.dart';

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
  static const Color primaryColor = Color(0xFF00C6D4);

  final SellerService _sellerService = SellerService();
  final Set<int> _selectedAmenityIds = {};
  String _selectedCategory = 'All';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAmenities();
  }

  Future<void> _loadExistingAmenities() async {
    try {
      final list = await _sellerService.getPropertyAmenities(widget.propertyId);
      if (!mounted) return;
      setState(() {
        for (final item in list) {
          final id = (item['amenityId'] ?? item['AmenityId'] ?? item['id']) as num?;
          if (id != null) {
            _selectedAmenityIds.add(id.toInt());
          }
        }
      });
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _amenities = const [
    {
      'id': 1,
      'name': 'Swimming Pool',
      'icon': Icons.pool_outlined,
      'category': 'Leisure',
    },
    {
      'id': 2,
      'name': 'Gym',
      'icon': Icons.fitness_center_outlined,
      'category': 'Fitness',
    },
    {
      'id': 3,
      'name': '24/7 Security',
      'icon': Icons.shield_outlined,
      'category': 'Safety',
    },
    {
      'id': 4,
      'name': 'Clubhouse',
      'icon': Icons.diversity_3_outlined,
      'category': 'Community',
    },
    {
      'id': 5,
      'name': 'Covered Parking',
      'icon': Icons.garage_outlined,
      'category': 'Parking',
    },
    {
      'id': 6,
      'name': 'Visitor Parking',
      'icon': Icons.local_parking_outlined,
      'category': 'Parking',
    },
    {
      'id': 7,
      'name': 'Play Area',
      'icon': Icons.park_outlined,
      'category': 'Community',
    },
    {
      'id': 8,
      'name': 'Power Backup',
      'icon': Icons.bolt_outlined,
      'category': 'Utilities',
    },
    {
      'id': 9,
      'name': 'Elevator',
      'icon': Icons.elevator_outlined,
      'category': 'Building',
    },
    {
      'id': 10,
      'name': 'CCTV Surveillance',
      'icon': Icons.videocam_outlined,
      'category': 'Safety',
    },
    {
      'id': 11,
      'name': 'Rooftop Terrace',
      'icon': Icons.deck_outlined,
      'category': 'Leisure',
    },
    {
      'id': 12,
      'name': 'Garden',
      'icon': Icons.yard_outlined,
      'category': 'Leisure',
    },
  ];

  List<String> get _categories {
    final set = <String>{'All'};
    for (final a in _amenities) {
      final cat = a['category'] as String?;
      if (cat != null) set.add(cat);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredAmenities {
    if (_selectedCategory == 'All') return _amenities;
    return _amenities
        .where((a) => a['category'] == _selectedCategory)
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

  Future<void> _saveAmenities({bool exitAfterSave = false}) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_selectedAmenityIds.isNotEmpty) {
        await _sellerService.addPropertyAmenities(
          widget.propertyId,
          _selectedAmenityIds.toList(),
        );
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (_selectedAmenityIds.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Amenities (${_selectedAmenityIds.length}) saved successfully!',
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (exitAfterSave) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
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
    final typeName = widget.propertyType ?? 'Property';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Amenities',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'What amenities are available?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the shared and community amenities available for this property.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildPropertyTypeCard(typeName),
                    const SizedBox(height: 20),
                    _buildCategoryFilter(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (_selectedAmenityIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedAmenityIds.length} selected',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAmenityGrid(),
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          _buildStepItem(number: '1', title: 'Basic', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '2', title: 'Features', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '3', title: 'Amenities', isCompleted: false, isActive: true),
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
        color: isCompleted ? primaryColor : const Color(0xFFE5E7EB),
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
            color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black45,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? primaryColor : Colors.black87,
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
        color: primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.domain_outlined,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property ID: ${widget.propertyId.length > 12 ? '${widget.propertyId.substring(0, 12)}...' : widget.propertyId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  propertyType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
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
      height: 36,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final amenity = list[index];
        final id = amenity['id'] as int;
        final name = amenity['name'] as String;
        final icon = amenity['icon'] as IconData;
        final isSelected = _selectedAmenityIds.contains(id);

        return InkWell(
          onTap: () => _toggleAmenity(id),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.black54,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (amenity['category'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          amenity['category'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: primaryColor,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select all amenities that apply. These will be highlighted on your listing to attract potential buyers and tenants.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final count = _selectedAmenityIds.length;
    final buttonText = count > 0
        ? 'Next: Financials ($count)'
        : 'Next: Financials';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _saveAmenities(exitAfterSave: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Save & Exit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveAmenities(exitAfterSave: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              buttonText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
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
