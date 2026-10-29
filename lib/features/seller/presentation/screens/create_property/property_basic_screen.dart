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

  String? _activePropertyId;

  // GlobalKeys for mandatory field scrolling/locating
  final GlobalKey _propertyTypeKey = GlobalKey();
  final GlobalKey _listingTypeKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();
  final GlobalKey _provinceKey = GlobalKey();
  final GlobalKey _districtKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();
  final GlobalKey _addressLine1Key = GlobalKey();

  // Inline error states for mandatory fields
  String? _propertyTypeError;
  String? _listingTypeError;
  String? _titleError;
  String? _priceError;
  String? _provinceError;
  String? _districtError;
  String? _cityError;
  String? _addressLine1Error;

  bool _isSubmitting = false;
  bool _isLoadingMasters = true;

  // Property Type & Listing Type (Master driven)
  int? _selectedPropertyTypeId;
  int? _selectedListingTypeId;

  // Basic Information
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();

  // Financials
  final TextEditingController _askingPriceController = TextEditingController();
  bool _isNegotiable = true;

  // Location Information (Master driven)
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  int? _selectedDivisionalSecretariatId;
  int? _selectedGnDivisionId;
  int? _selectedCityId;
  String? _selectedCityName;

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _divisionalSecretariats = [];
  List<Map<String, dynamic>> _gnDivisions = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _propertyTypes = [];
  List<Map<String, dynamic>> _listingTypes = [];

  bool _isLoadingDistricts = false;
  bool _isLoadingDivisionalSecretariats = false;
  bool _isLoadingGnDivisions = false;
  bool _isLoadingCities = false;

  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activePropertyId = widget.propertyId;
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoadingMasters = true);
    try {
      final results = await Future.wait([
        _sellerService.getPropertyTypes(),
        _sellerService.getListingTypes(),
        _sellerService.getProvinces(),
      ]);

      _propertyTypes = results[0];
      _listingTypes = results[1];
      _provinces = results[2];

      if (_propertyTypes.isNotEmpty && _selectedPropertyTypeId == null) {
        // Default to Apartment if available (code 'APARTMENT' or id 3), else first
        final apt = _propertyTypes.firstWhere(
          (p) {
            final code = p['code']?.toString().toUpperCase() ?? '';
            final name = p['name']?.toString().toUpperCase() ?? '';
            return code == 'APARTMENT' || name.contains('APARTMENT');
          },
          orElse: () => _propertyTypes.first,
        );
        _selectedPropertyTypeId = (apt['id'] as num?)?.toInt();
      }

      if (_listingTypes.isNotEmpty && _selectedListingTypeId == null) {
        _selectedListingTypeId = (_listingTypes.first['id'] as num?)?.toInt();
      }

      if (widget.initialData != null) {
        await _populateFromData(widget.initialData!);
      } else if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        await _loadProperty();
      } else {
        // Default province: Western (id 1) or first available
        if (_provinces.isNotEmpty) {
          final defProv = _provinces.firstWhere(
            (p) => (p['id'] as num?)?.toInt() == 1,
            orElse: () => _provinces.first,
          );
          _selectedProvinceId = (defProv['id'] as num?)?.toInt();
          await _loadDistrictsForSelectedProvince();
        }
      }

      if (_referenceNoController.text.trim().isEmpty) {
        try {
          final nextRef = await _sellerService.getNextReferenceNumber();
          if (nextRef.isNotEmpty && mounted) {
            _referenceNoController.text = nextRef;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error initializing master data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMasters = false);
      }
    }
  }

  Future<void> _loadDistrictsForSelectedProvince({
    int? preselectDistrictId,
    int? preselectDsId,
    int? preselectGnId,
    int? preselectCityId,
    String? preselectCityName,
  }) async {
    if (_selectedProvinceId == null) return;
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _divisionalSecretariats = [];
      _gnDivisions = [];
      _cities = [];
    });

    try {
      final districts = await _sellerService.getDistricts(provinceId: _selectedProvinceId);
      if (!mounted) return;

      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;

        if (preselectDistrictId != null && districts.any((d) => (d['id'] as num?)?.toInt() == preselectDistrictId)) {
          _selectedDistrictId = preselectDistrictId;
        } else if (districts.isNotEmpty) {
          _selectedDistrictId = (districts.first['id'] as num?)?.toInt();
        } else {
          _selectedDistrictId = null;
        }
      });

      if (_selectedDistrictId != null) {
        await Future.wait([
          _loadCitiesForSelectedDistrict(preselectCityId: preselectCityId, preselectCityName: preselectCityName),
          _loadDivisionalSecretariatsForSelectedDistrict(preselectDsId: preselectDsId, preselectGnId: preselectGnId),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadDivisionalSecretariatsForSelectedDistrict({
    int? preselectDsId,
    int? preselectGnId,
  }) async {
    if (_selectedDistrictId == null) return;
    setState(() {
      _isLoadingDivisionalSecretariats = true;
      _divisionalSecretariats = [];
      _gnDivisions = [];
    });

    try {
      final dsList = await _sellerService.getDivisionalSecretariats(_selectedDistrictId!);
      if (!mounted) return;

      setState(() {
        _divisionalSecretariats = dsList;
        _isLoadingDivisionalSecretariats = false;

        if (preselectDsId != null && dsList.any((d) => (d['id'] as num?)?.toInt() == preselectDsId)) {
          _selectedDivisionalSecretariatId = preselectDsId;
        } else if (dsList.isNotEmpty) {
          _selectedDivisionalSecretariatId = (dsList.first['id'] as num?)?.toInt();
        } else {
          _selectedDivisionalSecretariatId = null;
        }
      });

      if (_selectedDivisionalSecretariatId != null) {
        await _loadGnDivisionsForSelectedDs(preselectGnId: preselectGnId);
      }
    } catch (e) {
      debugPrint('Error loading DS divisions: $e');
      if (mounted) setState(() => _isLoadingDivisionalSecretariats = false);
    }
  }

  Future<void> _loadGnDivisionsForSelectedDs({int? preselectGnId}) async {
    if (_selectedDivisionalSecretariatId == null) return;
    setState(() {
      _isLoadingGnDivisions = true;
      _gnDivisions = [];
    });

    try {
      final gnList = await _sellerService.getGramaNiladhariDivisions(_selectedDivisionalSecretariatId!);
      if (!mounted) return;

      setState(() {
        _gnDivisions = gnList;
        _isLoadingGnDivisions = false;

        if (preselectGnId != null && gnList.any((g) => (g['id'] as num?)?.toInt() == preselectGnId)) {
          _selectedGnDivisionId = preselectGnId;
        } else if (gnList.isNotEmpty) {
          _selectedGnDivisionId = (gnList.first['id'] as num?)?.toInt();
        } else {
          _selectedGnDivisionId = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading GN divisions: $e');
      if (mounted) setState(() => _isLoadingGnDivisions = false);
    }
  }

  Future<void> _loadCitiesForSelectedDistrict({int? preselectCityId, String? preselectCityName}) async {
    if (_selectedDistrictId == null) return;
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final cities = await _sellerService.getCitiesByDistrict(_selectedDistrictId!);
      if (!mounted) return;

      setState(() {
        _cities = cities;
        _isLoadingCities = false;

        if (preselectCityId != null && cities.any((c) => (c['id'] as num?)?.toInt() == preselectCityId)) {
          _selectedCityId = preselectCityId;
          _selectedCityName = preselectCityName ?? cities.firstWhere((c) => (c['id'] as num?)?.toInt() == preselectCityId)['name']?.toString();
        } else if (cities.isNotEmpty) {
          _selectedCityId = (cities.first['id'] as num?)?.toInt();
          _selectedCityName = cities.first['name']?.toString();
        } else {
          _selectedCityId = null;
          _selectedCityName = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  Future<void> _populateFromData(Map<String, dynamic> data) async {
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
    final dId = (data['districtId'] as num?)?.toInt();
    final dsId = (data['divisionalSecretariatId'] as num?)?.toInt();
    final gnId = (data['gnDivisionId'] as num?)?.toInt();
    final cId = (data['cityId'] as num?)?.toInt();
    final cName = data['city']?.toString();

    _addressLine1Controller.text = data['addressLine1']?.toString() ?? '';
    _addressLine2Controller.text = data['addressLine2']?.toString() ?? '';
    _postalCodeController.text = data['postalCode']?.toString() ?? '';
    if (data['latitude'] != null) {
      _latitudeController.text = data['latitude'].toString();
    }
    if (data['longitude'] != null) {
      _longitudeController.text = data['longitude'].toString();
    }

    if (_selectedProvinceId != null) {
      await _loadDistrictsForSelectedProvince(
        preselectDistrictId: dId,
        preselectDsId: dsId,
        preselectGnId: gnId,
        preselectCityId: cId,
        preselectCityName: cName,
      );
    }
  }

  Future<void> _loadProperty() async {
    try {
      final data = await _sellerService.getPropertyById(widget.propertyId!);
      if (mounted) {
        await _populateFromData(data);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceNoController.dispose();
    _askingPriceController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  IconData _getPropertyTypeIcon(String? code, String? name) {
    final c = (code ?? name ?? '').toUpperCase();
    if (c.contains('HOUSE') || c.contains('VILLA')) return Icons.home_outlined;
    if (c.contains('APARTMENT') || c.contains('CONDO')) return Icons.apartment_outlined;
    if (c.contains('LAND') || c.contains('PLOT')) return Icons.landscape_outlined;
    if (c.contains('COMMERCIAL') || c.contains('OFFICE') || c.contains('RETAIL')) return Icons.storefront_outlined;
    return Icons.business_outlined;
  }

  String _getPropertyTypeName(int? id) {
    if (id == null) return 'Property';
    final match = _propertyTypes.firstWhere(
      (element) => (element['id'] as num?)?.toInt() == id,
      orElse: () => {'name': 'Property'},
    );
    return match['name']?.toString() ?? 'Property';
  }

  // ============================================================
  // SAVE AND NEXT / SAVE AND EXIT
  // ============================================================

  Future<void> _saveAndNext({bool exitAfterSave = false}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _propertyTypeError = null;
      _listingTypeError = null;
      _titleError = null;
      _priceError = null;
      _provinceError = null;
      _districtError = null;
      _cityError = null;
      _addressLine1Error = null;
    });

    GlobalKey? firstMissingKey;
    String? firstMissingLabel;

    if (_selectedPropertyTypeId == null) {
      _propertyTypeError = 'Please select a property type.';
      firstMissingKey ??= _propertyTypeKey;
      firstMissingLabel ??= 'Property Type';
    }

    if (_selectedListingTypeId == null) {
      _listingTypeError = 'Please select a listing type.';
      firstMissingKey ??= _listingTypeKey;
      firstMissingLabel ??= 'Listing Type';
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _titleError = 'Property title is required.';
      firstMissingKey ??= _titleKey;
      firstMissingLabel ??= 'Property Title';
    } else if (title.length < 3) {
      _titleError = 'Title must contain at least 3 characters.';
      firstMissingKey ??= _titleKey;
      firstMissingLabel ??= 'Property Title';
    }

    final double? askingPrice = double.tryParse(_askingPriceController.text.trim());
    if (askingPrice == null || askingPrice <= 0) {
      _priceError = 'Please enter a valid asking price.';
      firstMissingKey ??= _priceKey;
      firstMissingLabel ??= 'Asking Price';
    }

    if (_selectedProvinceId == null) {
      _provinceError = 'Please select a province.';
      firstMissingKey ??= _provinceKey;
      firstMissingLabel ??= 'Province';
    }

    if (_selectedDistrictId == null) {
      _districtError = 'Please select a district.';
      firstMissingKey ??= _districtKey;
      firstMissingLabel ??= 'District';
    }

    if (_selectedCityId == null || _selectedCityId! <= 0) {
      _cityError = 'Please select a city.';
      firstMissingKey ??= _cityKey;
      firstMissingLabel ??= 'City';
    }

    final addr1 = _addressLine1Controller.text.trim();
    if (addr1.isEmpty) {
      _addressLine1Error = 'Address line 1 is required.';
      firstMissingKey ??= _addressLine1Key;
      firstMissingLabel ??= 'Address Line 1';
    }

    if (firstMissingKey != null) {
      setState(() {});
      if (firstMissingKey.currentContext != null) {
        Scrollable.ensureVisible(
          firstMissingKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Missing required field: $firstMissingLabel. Please complete the highlighted field.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? latitude = double.tryParse(_latitudeController.text.trim());
    final double? longitude = double.tryParse(_longitudeController.text.trim());

    final Map<String, dynamic> payload = {
      'referenceNo': _referenceNoController.text.trim(),
      'propertyTypeId': _selectedPropertyTypeId,
      'listingTypeId': _selectedListingTypeId,
      'title': title,
      'description': _descriptionController.text.trim(),
      'provinceId': _selectedProvinceId,
      'districtId': _selectedDistrictId,
      'divisionalSecretariatId': _selectedDivisionalSecretariatId,
      'gnDivisionId': _selectedGnDivisionId,
      'cityId': _selectedCityId,
      'city': _selectedCityName,
      'addressLine1': addr1,
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

      if (_activePropertyId != null && _activePropertyId!.isNotEmpty) {
        await _sellerService.updateProperty(_activePropertyId!, payload);
        propertyId = _activePropertyId!;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing basic details updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        final response = await _sellerService.createProperty(payload);
        propertyId = response['propertyId']?.toString() ?? '';
        _activePropertyId = propertyId;
        if (response['referenceNo'] != null) {
          _referenceNoController.text = response['referenceNo'].toString();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing draft created successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      await _sellerService.setDraftStep(propertyId, exitAfterSave ? 1 : 2);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (exitAfterSave) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      // Navigate to the next page: Property Features screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyFeaturesScreen(
            propertyId: propertyId,
            propertyType: _getPropertyTypeName(_selectedPropertyTypeId),
          ),
        ),
      );
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
        child: _isLoadingMasters
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryCyan),
                    SizedBox(height: 16),
                    Text(
                      'Loading master options from database...',
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
                              'Section 01 — Property Location & Basics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Select property type, listing purpose, and define the complete administrative location hierarchy.',
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
                                  Container(
                                    key: _propertyTypeKey,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: _propertyTypeError != null
                                          ? Border.all(color: Colors.redAccent, width: 1.5)
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Property Type', required: true),
                                        const SizedBox(height: 10),
                                        _buildPropertyTypeSelector(),
                                        _buildFieldError(_propertyTypeError),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    key: _listingTypeKey,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: _listingTypeError != null
                                          ? Border.all(color: Colors.redAccent, width: 1.5)
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Listing Type', required: true),
                                        const SizedBox(height: 10),
                                        _buildListingTypeSelector(),
                                        _buildFieldError(_listingTypeError),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Section 2: Property Overview
                            _buildSectionCard(
                              title: 'Property Overview',
                              icon: Icons.description_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    key: _titleKey,
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
                                          onChanged: (_) {
                                            if (_titleError != null) {
                                              setState(() => _titleError = null);
                                            }
                                          },
                                        ),
                                        _buildFieldError(_titleError),
                                      ],
                                    ),
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
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel('Listing Reference Code (Official)'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _referenceNoController,
                                    readOnly: true,
                                    decoration: _inputDecoration(
                                      hintText: 'Auto-assigned upon save',
                                      prefixIcon: Icons.lock_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Unique reference number assigned by system upon saving.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
                                  Container(
                                    key: _priceKey,
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
                                          onChanged: (_) {
                                            if (_priceError != null) {
                                              setState(() => _priceError = null);
                                            }
                                          },
                                        ),
                                        _buildFieldError(_priceError),
                                      ],
                                    ),
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

                            // Section 4: Location Details (Master Driven Cascades)
                            _buildSectionCard(
                              title: 'Location & Hierarchy',
                              icon: Icons.location_on_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    key: _provinceKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Province', required: true),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<int>(
                                          value: _provinces.any((p) => (p['id'] as num?)?.toInt() == _selectedProvinceId)
                                              ? _selectedProvinceId
                                              : null,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            hintText: 'Select Province',
                                            prefixIcon: Icons.map_outlined,
                                          ),
                                          items: _provinces.map((p) {
                                            final id = (p['id'] as num).toInt();
                                            final name = p['name']?.toString() ?? '';
                                            return DropdownMenuItem<int>(
                                              value: id,
                                              child: Text(name),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null && val != _selectedProvinceId) {
                                              setState(() {
                                                _selectedProvinceId = val;
                                                _provinceError = null;
                                              });
                                              _loadDistrictsForSelectedProvince();
                                            }
                                          },
                                        ),
                                        _buildFieldError(_provinceError),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    key: _districtKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('District', required: true),
                                        const SizedBox(height: 8),
                                        _isLoadingDistricts
                                            ? _buildLoadingBox('Loading districts...')
                                            : DropdownButtonFormField<int>(
                                                value: _districts.any((d) => (d['id'] as num?)?.toInt() == _selectedDistrictId)
                                                    ? _selectedDistrictId
                                                    : null,
                                                isExpanded: true,
                                                decoration: _inputDecoration(
                                                  hintText: _districts.isEmpty ? 'No districts available' : 'Select District',
                                                  prefixIcon: Icons.location_city_outlined,
                                                ),
                                                items: _districts.map((d) {
                                                  final id = (d['id'] as num).toInt();
                                                  final name = d['name']?.toString() ?? '';
                                                  return DropdownMenuItem<int>(
                                                    value: id,
                                                    child: Text(name),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null && val != _selectedDistrictId) {
                                                    setState(() {
                                                      _selectedDistrictId = val;
                                                      _districtError = null;
                                                    });
                                                    Future.wait([
                                                      _loadCitiesForSelectedDistrict(),
                                                      _loadDivisionalSecretariatsForSelectedDistrict(),
                                                    ]);
                                                  }
                                                },
                                              ),
                                        _buildFieldError(_districtError),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Divisional Secretariat (DS Division)
                                  _buildLabel('Divisional Secretariat (DS Division)'),
                                  const SizedBox(height: 8),
                                  _isLoadingDivisionalSecretariats
                                      ? _buildLoadingBox('Loading DS divisions...')
                                      : DropdownButtonFormField<int>(
                                          value: _divisionalSecretariats.any((ds) => (ds['id'] as num?)?.toInt() == _selectedDivisionalSecretariatId)
                                              ? _selectedDivisionalSecretariatId
                                              : null,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            hintText: _divisionalSecretariats.isEmpty ? 'No DS divisions available' : 'Select DS Division',
                                            prefixIcon: Icons.account_balance_outlined,
                                          ),
                                          items: _divisionalSecretariats.map((ds) {
                                            final id = (ds['id'] as num).toInt();
                                            final name = ds['name']?.toString() ?? '';
                                            return DropdownMenuItem<int>(
                                              value: id,
                                              child: Text(name),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null && val != _selectedDivisionalSecretariatId) {
                                              setState(() {
                                                _selectedDivisionalSecretariatId = val;
                                              });
                                              _loadGnDivisionsForSelectedDs();
                                            }
                                          },
                                        ),
                                  const SizedBox(height: 16),

                                  // Grama Niladhari Division (GN Division)
                                  _buildLabel('Grama Niladhari Division (GN Division)'),
                                  const SizedBox(height: 8),
                                  _isLoadingGnDivisions
                                      ? _buildLoadingBox('Loading GN divisions...')
                                      : DropdownButtonFormField<int>(
                                          value: _gnDivisions.any((gn) => (gn['id'] as num?)?.toInt() == _selectedGnDivisionId)
                                              ? _selectedGnDivisionId
                                              : null,
                                          isExpanded: true,
                                          decoration: _inputDecoration(
                                            hintText: _gnDivisions.isEmpty ? 'No GN divisions available' : 'Select GN Division',
                                            prefixIcon: Icons.how_to_reg_outlined,
                                          ),
                                          items: _gnDivisions.map((gn) {
                                            final id = (gn['id'] as num).toInt();
                                            final name = gn['name']?.toString() ?? '';
                                            final gnNum = gn['gnNumber']?.toString();
                                            final displayText = (gnNum != null && gnNum.isNotEmpty) ? '$name ($gnNum)' : name;
                                            return DropdownMenuItem<int>(
                                              value: id,
                                              child: Text(displayText),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedGnDivisionId = val;
                                            });
                                          },
                                        ),
                                  const SizedBox(height: 16),

                                  // City
                                  Container(
                                    key: _cityKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('City', required: true),
                                        const SizedBox(height: 8),
                                        _isLoadingCities
                                            ? _buildLoadingBox('Loading cities...')
                                            : DropdownButtonFormField<int>(
                                                value: _cities.any((c) => (c['id'] as num?)?.toInt() == _selectedCityId)
                                                    ? _selectedCityId
                                                    : null,
                                                isExpanded: true,
                                                decoration: _inputDecoration(
                                                  hintText: _cities.isEmpty ? 'No cities available' : 'Select City',
                                                  prefixIcon: Icons.apartment_outlined,
                                                ),
                                                items: _cities.map((city) {
                                                  final id = (city['id'] as num?)?.toInt() ?? 0;
                                                  final name = city['name']?.toString() ?? '';
                                                  return DropdownMenuItem<int>(
                                                    value: id,
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF1A1A1A),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _selectedCityId = val;
                                                      _cityError = null;
                                                      final found = _cities.firstWhere(
                                                        (c) => (c['id'] as num?)?.toInt() == val,
                                                        orElse: () => {'name': ''},
                                                      );
                                                      _selectedCityName = found['name']?.toString();
                                                    });
                                                  }
                                                },
                                              ),
                                        _buildFieldError(_cityError),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    key: _addressLine1Key,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Address Line 1', required: true),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _addressLine1Controller,
                                          textInputAction: TextInputAction.next,
                                          decoration: _inputDecoration(
                                            hintText: 'House / Building No, Street Name',
                                            prefixIcon: Icons.home_outlined,
                                          ),
                                          onChanged: (_) {
                                            if (_addressLine1Error != null) {
                                              setState(() => _addressLine1Error = null);
                                            }
                                          },
                                        ),
                                        _buildFieldError(_addressLine1Error),
                                      ],
                                    ),
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

  Widget _buildLoadingBox(String text) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
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
          _buildStepItem(number: '1', title: 'Basic', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '2', title: 'Details', isCompleted: false, isActive: false),
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

  Widget _buildPropertyTypeSelector() {
    if (_propertyTypes.isEmpty) {
      return const Text(
        'No property types loaded from master table.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      );
    }

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
        final int id = (item['id'] as num).toInt();
        final String title = item['name']?.toString() ?? 'Type';
        final String? code = item['code']?.toString();
        final IconData icon = _getPropertyTypeIcon(code, title);
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    if (_listingTypes.isEmpty) {
      return const Text(
        'No listing types available.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      );
    }

    return Row(
      children: _listingTypes.map((t) {
        final int id = (t['id'] as num).toInt();
        final String name = t['name']?.toString() ?? 'Listing';
        final bool isSelected = _selectedListingTypeId == id;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedListingTypeId = id;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildFieldError(String? error) {
    if (error == null || error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _saveAndNext(exitAfterSave: true),
                style: OutlinedButton.styleFrom(
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryCyan,
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
                onPressed: _isSubmitting ? null : () => _saveAndNext(exitAfterSave: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryCyan.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
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
                            child: Text(
                              'Save & Next',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16),
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