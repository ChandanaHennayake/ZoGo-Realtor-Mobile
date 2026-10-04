import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_features_screen.dart';

class PropertyBasicScreen extends StatefulWidget {
  final String? propertyId;
  final Map<String, dynamic>? initialData;

  const PropertyBasicScreen({
    super.key,
    this.propertyId,
    this.initialData,
  });

  @override
  State<PropertyBasicScreen> createState() => _PropertyBasicScreenState();
}

class _PropertyBasicScreenState extends State<PropertyBasicScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();
  final SellerService _sellerService = SellerService();

  bool _isSubmitting = false;

  // Property Type (1: House, 2: Apartment, 3: Land, 4: Commercial)
  int _selectedPropertyTypeId = 1;

  // Listing Type (1: For Sale, 2: For Rent)
  int _selectedListingTypeId = 1;

  // Basic Information
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();

  // Financials
  final TextEditingController _askingPriceController = TextEditingController();
  bool _isNegotiable = true;

  // Location Information
  int _selectedProvinceId = 2; // Default: Central
  int _selectedDistrictId = 5; // Default: Matale
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _cityIdController = TextEditingController(text: '5003');
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  static const Map<int, String> _provinces = {
    1: 'Western Province',
    2: 'Central Province',
    3: 'Southern Province',
    4: 'Northern Province',
    5: 'Eastern Province',
    6: 'North Western Province',
    7: 'North Central Province',
    8: 'Uva Province',
    9: 'Sabaragamuwa Province',
  };

  static const Map<int, List<Map<String, dynamic>>> _districtsByProvince = {
    1: [
      {'id': 1, 'name': 'Colombo'},
      {'id': 2, 'name': 'Gampaha'},
      {'id': 3, 'name': 'Kalutara'},
    ],
    2: [
      {'id': 4, 'name': 'Kandy'},
      {'id': 5, 'name': 'Matale'},
      {'id': 6, 'name': 'Nuwara Eliya'},
    ],
    3: [
      {'id': 7, 'name': 'Galle'},
      {'id': 8, 'name': 'Matara'},
      {'id': 9, 'name': 'Hambantota'},
    ],
    4: [
      {'id': 10, 'name': 'Jaffna'},
      {'id': 11, 'name': 'Kilinochchi'},
      {'id': 12, 'name': 'Mannar'},
      {'id': 13, 'name': 'Vavuniya'},
      {'id': 14, 'name': 'Mullaitivu'},
    ],
    5: [
      {'id': 15, 'name': 'Batticaloa'},
      {'id': 16, 'name': 'Ampara'},
      {'id': 17, 'name': 'Trincomalee'},
    ],
    6: [
      {'id': 18, 'name': 'Kurunegala'},
      {'id': 19, 'name': 'Puttalam'},
    ],
    7: [
      {'id': 20, 'name': 'Anuradhapura'},
      {'id': 21, 'name': 'Polonnaruwa'},
    ],
    8: [
      {'id': 22, 'name': 'Badulla'},
      {'id': 23, 'name': 'Monaragala'},
    ],
    9: [
      {'id': 24, 'name': 'Ratnapura'},
      {'id': 25, 'name': 'Kegalle'},
    ],
  };

  final List<Map<String, dynamic>> _propertyTypes = const [
    {'id': 1, 'title': 'House', 'icon': Icons.home_outlined},
    {'id': 2, 'title': 'Apartment', 'icon': Icons.apartment_outlined},
    {'id': 3, 'title': 'Land', 'icon': Icons.landscape_outlined},
    {'id': 4, 'title': 'Commercial', 'icon': Icons.storefront_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _populateFromData(widget.initialData!);
    } else if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
      _loadProperty();
    }
  }

  void _populateFromData(Map<String, dynamic> data) {
    if (data['propertyTypeId'] != null) {
      _selectedPropertyTypeId = (data['propertyTypeId'] as num).toInt();
    }
    if (data['listingTypeId'] != null) {
      _selectedListingTypeId = (data['listingTypeId'] as num).toInt();
    }
    _titleController.text = data['title']?.toString() ?? '';
    _descriptionController.text = data['description']?.toString() ?? '';
    _referenceNoController.text = data['referenceNo']?.toString() ?? '';
    if (data['askingPrice'] != null) {
      _askingPriceController.text = data['askingPrice'].toString();
    }
    if (data['isNegotiable'] != null) {
      _isNegotiable = data['isNegotiable'] == true;
    }
    if (data['provinceId'] != null) {
      _selectedProvinceId = (data['provinceId'] as num).toInt();
    }
    if (data['districtId'] != null) {
      _selectedDistrictId = (data['districtId'] as num).toInt();
    }
    _cityController.text = data['city']?.toString() ?? '';
    if (data['cityId'] != null) {
      _cityIdController.text = data['cityId'].toString();
    }
    _addressLine1Controller.text = data['addressLine1']?.toString() ?? '';
    _addressLine2Controller.text = data['addressLine2']?.toString() ?? '';
    _postalCodeController.text = data['postalCode']?.toString() ?? '';
    if (data['latitude'] != null) {
      _latitudeController.text = data['latitude'].toString();
    }
    if (data['longitude'] != null) {
      _longitudeController.text = data['longitude'].toString();
    }
  }

  Future<void> _loadProperty() async {
    try {
      final data = await _sellerService.getPropertyById(widget.propertyId!);
      if (mounted) {
        setState(() {
          _populateFromData(data);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceNoController.dispose();
    _askingPriceController.dispose();
    _cityController.dispose();
    _cityIdController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _getPropertyTypeName(int id) {
    final match = _propertyTypes.firstWhere(
      (element) => element['id'] == id,
      orElse: () => {'title': 'Property'},
    );
    return match['title'] as String;
  }

  // ============================================================
  // SAVE AND NEXT
  // ============================================================

  Future<void> _saveAndNext() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form before proceeding.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double? askingPrice = double.tryParse(_askingPriceController.text.trim());
    if (askingPrice == null || askingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid asking price.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int cityId = int.tryParse(_cityIdController.text.trim()) ?? 0;
    final double? latitude = double.tryParse(_latitudeController.text.trim());
    final double? longitude = double.tryParse(_longitudeController.text.trim());

    final Map<String, dynamic> payload = {
      'referenceNo': _referenceNoController.text.trim(),
      'propertyTypeId': _selectedPropertyTypeId,
      'listingTypeId': _selectedListingTypeId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'provinceId': _selectedProvinceId,
      'districtId': _selectedDistrictId,
      'divisionalSecretariatId': null,
      'gnDivisionId': null,
      'cityId': cityId,
      'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      'addressLine1': _addressLine1Controller.text.trim(),
      'addressLine2': _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
      'postalCode': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'askingPrice': askingPrice,
      'isNegotiable': _isNegotiable,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      String propertyId;

      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        await _sellerService.updateProperty(widget.propertyId!, payload);
        propertyId = widget.propertyId!;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property basic details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final response = await _sellerService.createProperty(payload);
        propertyId = response['propertyId']?.toString() ?? '';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property basic details saved successfully! ID: $propertyId'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Navigate to the next page: Property Features screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyFeaturesScreen(
            propertyId: propertyId,
            propertyType: _getPropertyTypeName(_selectedPropertyTypeId),
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving property: $e'),

          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
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
          'Add Property Details',
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
        child: Column(
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
                        'Basic Property Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Provide the core details of your property to save it to your listings.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Section 1: Property Type & Listing Type
                      _buildSectionCard(
                        title: 'Property & Listing Type',
                        icon: Icons.category_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Property Type', required: true),
                            const SizedBox(height: 10),
                            _buildPropertyTypeSelector(),
                            const SizedBox(height: 20),
                            _buildLabel('Listing Type', required: true),
                            const SizedBox(height: 10),
                            _buildListingTypeSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section 2: Property Description
                      _buildSectionCard(
                        title: 'Property Overview',
                        icon: Icons.description_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Property Title', required: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              textInputAction: TextInputAction.next,
                              maxLength: 150,
                              decoration: _inputDecoration(
                                hintText: 'e.g. Modern Luxury 3 Bedroom Apartment',
                                prefixIcon: Icons.title_outlined,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Property title is required.';
                                if (text.length < 3) return 'Title must contain at least 3 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('Description', required: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              minLines: 3,
                              maxLength: 2000,
                              textInputAction: TextInputAction.newline,
                              decoration: _inputDecoration(
                                hintText: 'Detailed description of your property...',
                                prefixIcon: Icons.notes_outlined,
                                alignPrefixIcon: true,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Property description is required.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildLabel('Reference No (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _referenceNoController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'Leave empty for auto-generated reference',
                                prefixIcon: Icons.tag_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section 3: Pricing & Terms
                      _buildSectionCard(
                        title: 'Pricing & Terms',
                        icon: Icons.attach_money_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Asking Price (LKR)', required: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _askingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'e.g. 25000000',
                                prefixIcon: Icons.payments_outlined,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Asking price is required.';
                                final num = double.tryParse(text);
                                if (num == null || num <= 0) return 'Enter a valid asking price.';
                                return null;
                              },
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
                                        'Price is Negotiable',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        'Allow buyers to propose offers',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: _isNegotiable,
                                    activeTrackColor: primaryCyan,
                                    onChanged: (val) {
                                      setState(() {
                                        _isNegotiable = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section 4: Location Details
                      _buildSectionCard(
                        title: 'Location Details',
                        icon: Icons.location_on_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Province', required: true),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedProvinceId,
                              decoration: _inputDecoration(
                                hintText: 'Select Province',
                                prefixIcon: Icons.map_outlined,
                              ),
                              items: _provinces.entries.map((e) {
                                return DropdownMenuItem<int>(
                                  value: e.key,
                                  child: Text(e.value),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedProvinceId = val;
                                    final districts = _districtsByProvince[val] ?? [];
                                    if (districts.isNotEmpty) {
                                      _selectedDistrictId = districts.first['id'] as int;
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('District', required: true),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedDistrictId,
                              decoration: _inputDecoration(
                                hintText: 'Select District',
                                prefixIcon: Icons.location_city_outlined,
                              ),
                              items: (_districtsByProvince[_selectedProvinceId] ?? []).map((d) {
                                return DropdownMenuItem<int>(
                                  value: d['id'] as int,
                                  child: Text(d['name'] as String),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDistrictId = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('City Name'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _cityController,
                                        textInputAction: TextInputAction.next,
                                        decoration: _inputDecoration(
                                          hintText: 'e.g. Kandy',
                                          prefixIcon: Icons.apartment_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('City ID'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _cityIdController,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        decoration: _inputDecoration(
                                          hintText: '5003',
                                          prefixIcon: Icons.numbers_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Address Line 1', required: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressLine1Controller,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'House / Building No, Street Name',
                                prefixIcon: Icons.home_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address line 1 is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Address Line 2 (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressLine2Controller,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'Apartment, Suite, Unit, etc.',
                                prefixIcon: Icons.signpost_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Postal Code (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'e.g. 20000',
                                prefixIcon: Icons.markunread_mailbox_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Latitude (Opt)'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _latitudeController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.next,
                                        decoration: _inputDecoration(
                                          hintText: '6.9271',
                                          prefixIcon: Icons.my_location_outlined,
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
                                      _buildLabel('Longitude (Opt)'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _longitudeController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.done,
                                        decoration: _inputDecoration(
                                          hintText: '79.8612',
                                          prefixIcon: Icons.my_location_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _buildStepItem(number: '1', title: 'Basic', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '2', title: 'Features', isCompleted: false, isActive: false),
          _buildStepLine(false),
          _buildStepItem(number: '3', title: 'Amenities', isCompleted: false, isActive: false),
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

  Widget _buildPropertyTypeSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _propertyTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final item = _propertyTypes[index];
        final int id = item['id'] as int;
        final String title = item['title'] as String;
        final IconData icon = item['icon'] as IconData;
        final bool isSelected = _selectedPropertyTypeId == id;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedPropertyTypeId = id;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryCyan.withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryCyan : const Color(0xFFE5E7EB),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? primaryCyan : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryCyan : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: primaryCyan),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingTypeSelector() {
    final types = [
      {'id': 1, 'name': 'For Sale'},
      {'id': 2, 'name': 'For Rent'},
    ];

    return Row(
      children: types.map((t) {
        final int id = t['id'] as int;
        final String name = t['name'] as String;
        final bool isSelected = _selectedListingTypeId == id;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedListingTypeId = id;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: id == 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryCyan : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? primaryCyan : const Color(0xFFE5E7EB),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    bool alignPrefixIcon = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      prefixIcon: alignPrefixIcon
          ? Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
            )
          : Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _saveAndNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primaryCyan.withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save and Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}