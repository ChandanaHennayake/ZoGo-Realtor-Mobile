import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_amenities_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_basic_screen.dart';

class PropertyFeaturesScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyFeaturesScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyFeaturesScreen> createState() => _PropertyFeaturesScreenState();
}

class _PropertyFeaturesScreenState extends State<PropertyFeaturesScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();
  final SellerService _sellerService = SellerService();

  bool _isLoading = true;
  bool _isSaving = false;

  // Master options
  List<Map<String, dynamic>> _condominiums = [];
  List<Map<String, dynamic>> _apartmentTypes = [];
  List<Map<String, dynamic>> _furnishingTypes = [];
  List<Map<String, dynamic>> _viewTypes = [];
  List<Map<String, dynamic>> _masterFeatures = [];

  // Apartment Details State
  String? _selectedCondominiumId; // GUID or null
  int? _selectedApartmentTypeId;
  int? _selectedFurnishingTypeId;
  int? _selectedViewTypeId;

  final TextEditingController _floorNumberController = TextEditingController();
  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _floorAreaController = TextEditingController();

  bool _isCornerUnit = false;
  int _bedrooms = 2;
  int _masterBedrooms = 1;
  int _bathrooms = 2;
  int _attachedBathrooms = 1;
  int _balconies = 1;

  // Utility Space Toggles
  bool _hasMaidRoom = false;
  bool _hasMaidBathroom = false;
  bool _hasLaundryArea = false;
  bool _hasStorageRoom = false;
  bool _hasWalkInCloset = false;
  bool _hasDriversRoom = false;

  // Selected Feature IDs (from Features master table)
  final Set<int> _selectedFeatureIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _floorNumberController.dispose();
    _unitNumberController.dispose();
    _floorAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _sellerService.getCondominiums(),
        _sellerService.getApartmentTypes(),
        _sellerService.getFurnishingTypes(),
        _sellerService.getViewTypes(),
        _sellerService.getFeatures(),
        _sellerService.getApartmentDetails(widget.propertyId),
        _sellerService.getPropertyFeatures(widget.propertyId),
      ]);

      _condominiums = futures[0] as List<Map<String, dynamic>>;
      _apartmentTypes = futures[1] as List<Map<String, dynamic>>;
      _furnishingTypes = futures[2] as List<Map<String, dynamic>>;
      _viewTypes = futures[3] as List<Map<String, dynamic>>;
      _masterFeatures = futures[4] as List<Map<String, dynamic>>;

      final aptData = futures[5] as Map<String, dynamic>?;
      if (aptData != null) {
        _selectedCondominiumId = aptData['condominiumId']?.toString();
        _selectedApartmentTypeId = (aptData['apartmentTypeId'] as num?)?.toInt();
        _selectedFurnishingTypeId = (aptData['furnishingTypeId'] as num?)?.toInt();
        _selectedViewTypeId = (aptData['viewTypeId'] as num?)?.toInt();

        if (aptData['floorNumber'] != null) {
          _floorNumberController.text = aptData['floorNumber'].toString();
        }
        if (aptData['unitNumber'] != null) {
          _unitNumberController.text = aptData['unitNumber'].toString();
        }
        if (aptData['floorAreaSqFt'] != null) {
          _floorAreaController.text = aptData['floorAreaSqFt'].toString();
        }

        _isCornerUnit = aptData['isCornerUnit'] == true;
        _bedrooms = (aptData['bedrooms'] as num?)?.toInt() ?? 2;
        _masterBedrooms = (aptData['masterBedrooms'] as num?)?.toInt() ?? 1;
        _bathrooms = (aptData['bathrooms'] as num?)?.toInt() ?? 2;
        _attachedBathrooms = (aptData['attachedBathrooms'] as num?)?.toInt() ?? 1;
        _balconies = (aptData['balconies'] as num?)?.toInt() ?? 1;

        _hasMaidRoom = aptData['hasMaidRoom'] == true;
        _hasMaidBathroom = aptData['hasMaidBathroom'] == true;
        _hasLaundryArea = aptData['hasLaundryArea'] == true;
        _hasStorageRoom = aptData['hasStorageRoom'] == true;
        _hasWalkInCloset = aptData['hasWalkInCloset'] == true;
        _hasDriversRoom = aptData['hasDriversRoom'] == true;
      } else {
        // Defaults from loaded masters
        if (_apartmentTypes.isNotEmpty) {
          _selectedApartmentTypeId = (_apartmentTypes.first['id'] as num?)?.toInt();
        }
        if (_furnishingTypes.isNotEmpty) {
          _selectedFurnishingTypeId = (_furnishingTypes.first['id'] as num?)?.toInt();
        }
        if (_viewTypes.isNotEmpty) {
          _selectedViewTypeId = (_viewTypes.first['id'] as num?)?.toInt();
        }
      }

      final existingFeatures = futures[6] as List<Map<String, dynamic>>;
      for (final f in existingFeatures) {
        final id = (f['featureId'] ?? f['FeatureId'] ?? f['id']) as num?;
        if (id != null) {
          _selectedFeatureIds.add(id.toInt());
        }
      }
    } catch (e) {
      debugPrint('Error loading Section 02 data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAndProceed({bool exitAfterSave = false}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct errors before proceeding.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double? area = double.tryParse(_floorAreaController.text.trim());
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid floor area (SqFt).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int? floorNum = int.tryParse(_floorNumberController.text.trim());
      final String? unitNum = _unitNumberController.text.trim().isEmpty ? null : _unitNumberController.text.trim();

      final aptPayload = {
        'condominiumId': (_selectedCondominiumId != null && _selectedCondominiumId!.isNotEmpty) ? _selectedCondominiumId : null,
        'apartmentTypeId': _selectedApartmentTypeId,
        'floorNumber': floorNum,
        'unitNumber': unitNum,
        'isCornerUnit': _isCornerUnit,
        'floorAreaSqFt': area,
        'bedrooms': _bedrooms,
        'masterBedrooms': _masterBedrooms,
        'bathrooms': _bathrooms,
        'attachedBathrooms': _attachedBathrooms,
        'balconies': _balconies,
        'furnishingTypeId': _selectedFurnishingTypeId,
        'viewTypeId': _selectedViewTypeId,
        'hasMaidRoom': _hasMaidRoom,
        'hasMaidBathroom': _hasMaidBathroom,
        'hasLaundryArea': _hasLaundryArea,
        'hasStorageRoom': _hasStorageRoom,
        'hasWalkInCloset': _hasWalkInCloset,
        'hasDriversRoom': _hasDriversRoom,
      };

      await Future.wait([
        _sellerService.saveApartmentDetails(widget.propertyId, aptPayload),
        _sellerService.syncPropertyFeatures(widget.propertyId, _selectedFeatureIds),
      ]);

      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property details & features saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _sellerService.setDraftStep(widget.propertyId, exitAfterSave ? 2 : 3);
      if (!mounted) return;

      if (exitAfterSave) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyAmenitiesScreen(
            propertyId: widget.propertyId,
            propertyType: widget.propertyType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving details: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // UI BUILD
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
          'Property Details & Features',
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
                      'Loading property details & master features...',
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgress(),
                            const SizedBox(height: 24),

                            const Text(
                              'Section 02 — Property Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Configure unit specifications, floor area, layout, furnishings, views, and specific interior features.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // 1. Building & Project Information
                            _buildSectionCard(
                              title: 'Apartment & Building Specification',
                              icon: Icons.apartment_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Condominium / Project Name'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String?>(
                                    value: _condominiums.any((c) => c['id']?.toString() == _selectedCondominiumId)
                                        ? _selectedCondominiumId
                                        : null,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      hintText: 'Select Condominium Project (or None)',
                                      prefixIcon: Icons.business_outlined,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Stand-alone / Independent Building'),
                                      ),
                                      ..._condominiums.map((c) {
                                        final id = c['id']?.toString();
                                        final name = c['name']?.toString() ?? 'Condo';
                                        return DropdownMenuItem<String?>(
                                          value: id,
                                          child: Text(name),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCondominiumId = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildLabel('Apartment Type', required: true),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _apartmentTypes.any((a) => (a['id'] as num?)?.toInt() == _selectedApartmentTypeId)
                                        ? _selectedApartmentTypeId
                                        : null,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      hintText: 'Select Apartment Type',
                                      prefixIcon: Icons.roofing_outlined,
                                    ),
                                    items: _apartmentTypes.map((a) {
                                      final id = (a['id'] as num).toInt();
                                      final name = a['name']?.toString() ?? 'Type';
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedApartmentTypeId = val;
                                      });
                                    },
                                    validator: (val) => val == null ? 'Apartment type is required.' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel('Floor No.'),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _floorNumberController,
                                              keyboardType: TextInputType.number,
                                              decoration: _inputDecoration(
                                                hintText: 'e.g. 14',
                                                prefixIcon: Icons.layers_outlined,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel('Unit No.'),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _unitNumberController,
                                              decoration: _inputDecoration(
                                                hintText: 'e.g. 14-B',
                                                prefixIcon: Icons.tag_outlined,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Corner Unit',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            Text(
                                              'Has extra windows and natural light',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Switch.adaptive(
                                          value: _isCornerUnit,
                                          activeTrackColor: primaryCyan,
                                          onChanged: (val) {
                                            setState(() => _isCornerUnit = val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 2. Space Dimensions & Quantities
                            _buildSectionCard(
                              title: 'Space Details & Dimensions',
                              icon: Icons.square_foot_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Total Floor Area (Sq.Ft.)', required: true),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _floorAreaController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _inputDecoration(
                                      hintText: 'e.g. 1250',
                                      prefixIcon: Icons.straighten_outlined,
                                    ),
                                    validator: (val) {
                                      final text = val?.trim() ?? '';
                                      if (text.isEmpty) return 'Floor area is required.';
                                      final num = double.tryParse(text);
                                      if (num == null || num <= 0) return 'Enter a valid area in SqFt.';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildCounterRow(
                                    label: 'Bedrooms',
                                    value: _bedrooms,
                                    icon: Icons.bed_outlined,
                                    onChanged: (v) => setState(() => _bedrooms = v),
                                    min: 0,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildCounterRow(
                                    label: 'Master Bedrooms',
                                    value: _masterBedrooms,
                                    icon: Icons.single_bed_outlined,
                                    onChanged: (v) => setState(() => _masterBedrooms = v),
                                    min: 0,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildCounterRow(
                                    label: 'Bathrooms',
                                    value: _bathrooms,
                                    icon: Icons.bathtub_outlined,
                                    onChanged: (v) => setState(() => _bathrooms = v),
                                    min: 0,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildCounterRow(
                                    label: 'Attached Bathrooms',
                                    value: _attachedBathrooms,
                                    icon: Icons.shower_outlined,
                                    onChanged: (v) => setState(() => _attachedBathrooms = v),
                                    min: 0,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildCounterRow(
                                    label: 'Balconies',
                                    value: _balconies,
                                    icon: Icons.balcony_outlined,
                                    onChanged: (v) => setState(() => _balconies = v),
                                    min: 0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 3. View & Furnishing
                            _buildSectionCard(
                              title: 'View & Furnishing',
                              icon: Icons.panorama_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Furnishing Type'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _furnishingTypes.any((f) => (f['id'] as num?)?.toInt() == _selectedFurnishingTypeId)
                                        ? _selectedFurnishingTypeId
                                        : null,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      hintText: 'Select Furnishing Status',
                                      prefixIcon: Icons.chair_outlined,
                                    ),
                                    items: _furnishingTypes.map((f) {
                                      final id = (f['id'] as num).toInt();
                                      final name = f['name']?.toString() ?? 'Furnishing';
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedFurnishingTypeId = val);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildLabel('View Type'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _viewTypes.any((v) => (v['id'] as num?)?.toInt() == _selectedViewTypeId)
                                        ? _selectedViewTypeId
                                        : null,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      hintText: 'Select View Type',
                                      prefixIcon: Icons.visibility_outlined,
                                    ),
                                    items: _viewTypes.map((v) {
                                      final id = (v['id'] as num).toInt();
                                      final name = v['name']?.toString() ?? 'View';
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedViewTypeId = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 4. Utility & Additional Spaces
                            _buildSectionCard(
                              title: 'Utility & Staff Spaces',
                              icon: Icons.home_repair_service_outlined,
                              child: Column(
                                children: [
                                  _buildToggleTile(
                                    title: "Maid's Room",
                                    subtitle: 'Dedicated room for household help',
                                    value: _hasMaidRoom,
                                    onChanged: (v) => setState(() => _hasMaidRoom = v),
                                  ),
                                  _buildToggleTile(
                                    title: "Maid's Bathroom",
                                    subtitle: 'Separate bathroom for domestic staff',
                                    value: _hasMaidBathroom,
                                    onChanged: (v) => setState(() => _hasMaidBathroom = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Laundry Area',
                                    subtitle: 'Dedicated space for washer & drying',
                                    value: _hasLaundryArea,
                                    onChanged: (v) => setState(() => _hasLaundryArea = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Storage Room',
                                    subtitle: 'Enclosed storage or pantry room',
                                    value: _hasStorageRoom,
                                    onChanged: (v) => setState(() => _hasStorageRoom = v),
                                  ),
                                  _buildToggleTile(
                                    title: 'Walk-In Closet',
                                    subtitle: 'Spacious dressing wardrobe area',
                                    value: _hasWalkInCloset,
                                    onChanged: (v) => setState(() => _hasWalkInCloset = v),
                                  ),
                                  _buildToggleTile(
                                    title: "Driver's Room",
                                    subtitle: 'Allocated rest area for chauffeur',
                                    value: _hasDriversRoom,
                                    onChanged: (v) => setState(() => _hasDriversRoom = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 5. Categorized Feature Clusters (from Features master table)
                            _buildFeatureCategorySection(
                              title: 'Selling Purpose',
                              category: 'SellingPurpose',
                              icon: Icons.sell_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Living & Dining Layout',
                              category: 'LivingDiningLayout',
                              icon: Icons.weekend_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Kitchen Types',
                              category: 'KitchenType',
                              icon: Icons.soup_kitchen_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Additional Spaces & Rooms',
                              category: 'AdditionalSpace',
                              icon: Icons.meeting_room_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Furniture Inclusions',
                              category: 'Furniture',
                              icon: Icons.chair_alt_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Kitchen Appliances',
                              category: 'KitchenAppliance',
                              icon: Icons.kitchen_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Laundry Equipment',
                              category: 'LaundryAppliance',
                              icon: Icons.local_laundry_service_outlined,
                            ),
                            const SizedBox(height: 18),

                            _buildFeatureCategorySection(
                              title: 'Comfort, Electronics & Smart Features',
                              category: 'ComfortElectronics',
                              icon: Icons.devices_other_outlined,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Save & Next Button
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  Widget _buildFeatureCategorySection({
    required String title,
    required String category,
    required IconData icon,
  }) {
    final features = _masterFeatures.where((f) {
      final cat = f['category']?.toString() ?? '';
      return cat.toLowerCase() == category.toLowerCase();
    }).toList();

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      title: title,
      icon: icon,
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: features.map((f) {
          final int id = (f['id'] as num).toInt();
          final String name = f['name']?.toString() ?? '';
          final bool isSelected = _selectedFeatureIds.contains(id);

          return FilterChip(
            label: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryCyan : const Color(0xFF374151),
              ),
            ),
            selected: isSelected,
            selectedColor: primaryCyan.withValues(alpha: 0.12),
            backgroundColor: const Color(0xFFF9FAFB),
            checkmarkColor: primaryCyan,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? primaryCyan : const Color(0xFFE5E7EB),
                width: isSelected ? 1.6 : 1,
              ),
            ),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedFeatureIds.add(id);
                } else {
                  _selectedFeatureIds.remove(id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required IconData icon,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 20,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                color: value > min ? primaryCyan : const Color(0xFFD1D5DB),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: value < max ? primaryCyan : const Color(0xFFD1D5DB),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: primaryCyan,
            onChanged: onChanged,
          ),
        ],
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
          _buildStepItem(number: '2', title: 'Details', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '3', title: 'Facilities', isCompleted: false, isActive: false),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryCyan, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
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
                        builder: (context) => PropertyBasicScreen(propertyId: widget.propertyId),
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
                onPressed: _isSaving ? null : () => _saveAndProceed(exitAfterSave: true),
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
                onPressed: _isSaving ? null : () => _saveAndProceed(exitAfterSave: false),
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