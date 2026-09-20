import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_details_screen.dart';

class PropertyLocationResult {
  final String propertyType;
  final String title;
  final String description;

  final String address;
  final String city;
  final String district;
  final String province;
  final String postalCode;

  final double? latitude;
  final double? longitude;

  const PropertyLocationResult({
    required this.propertyType,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });
}

class PropertyLocationScreen extends StatefulWidget {
  const PropertyLocationScreen({
    super.key,
    required this.propertyType,
    required this.title,
    required this.description,
  });

  final String propertyType;
  final String title;
  final String description;

  @override
  State<PropertyLocationScreen> createState() =>
      _PropertyLocationScreenState();
}

class _PropertyLocationScreenState
    extends State<PropertyLocationScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _districtController =
      TextEditingController();

  final TextEditingController _provinceController =
      TextEditingController();

  final TextEditingController _postalCodeController =
      TextEditingController();

  final TextEditingController _latitudeController =
      TextEditingController();

  final TextEditingController _longitudeController =
      TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.tryParse(
      _latitudeController.text.trim(),
    );

    final longitude = double.tryParse(
      _longitudeController.text.trim(),
    );

    final result = PropertyLocationResult(
      propertyType: widget.propertyType,
      title: widget.title,
      description: widget.description,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    final detailsResult =
        await Navigator.push<PropertyDetailsResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(
          locationData: result,
        ),
      ),
    );

    if (detailsResult != null && mounted) {
      Navigator.pop(context, detailsResult);
    }
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
          'Property Location',
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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildProgress(),

                      const SizedBox(height: 28),

                      const Text(
                        'Where is your property?',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Provide the location details of your property.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ====================================================
                      // ADDRESS SECTION
                      // ====================================================

                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  _addressController,
                              maxLines: 3,
                              minLines: 2,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText:
                                    'Enter property address',
                                prefixIcon:
                                    Icons.location_on_outlined,
                                alignPrefixIcon: true,
                              ),
                              validator: (value) {
                                final text =
                                    value?.trim() ?? '';

                                if (text.isEmpty) {
                                  return 'Address is required.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildLabel('City'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _cityController,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'Enter city',
                                prefixIcon:
                                    Icons.location_city_outlined,
                              ),
                              validator: (value) {
                                if ((value?.trim() ?? '')
                                    .isEmpty) {
                                  return 'City is required.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildLabel('District'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  _districtController,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText:
                                    'Enter district',
                                prefixIcon:
                                    Icons.map_outlined,
                              ),
                              validator: (value) {
                                if ((value?.trim() ?? '')
                                    .isEmpty) {
                                  return 'District is required.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildLabel('Province'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  _provinceController,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText:
                                    'Enter province',
                                prefixIcon:
                                    Icons.public_outlined,
                              ),
                              validator: (value) {
                                if ((value?.trim() ?? '')
                                    .isEmpty) {
                                  return 'Province is required.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildLabel(
                              'Postal Code',
                              required: false,
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  _postalCodeController,
                              keyboardType:
                                  TextInputType.number,
                              textInputAction:
                                  TextInputAction.done,
                              maxLength: 5,
                              decoration: _inputDecoration(
                                hintText:
                                    'Enter postal code',
                                prefixIcon:
                                    Icons
                                        .markunread_mailbox_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ====================================================
                      // MAP LOCATION SECTION
                      // ====================================================

                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Map Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Add coordinates if they are available.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _buildCoordinateField(
                                    controller:
                                        _latitudeController,
                                    label: 'Latitude',
                                    hint: 'e.g. 6.9271',
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child:
                                      _buildCoordinateField(
                                    controller:
                                        _longitudeController,
                                    label: 'Longitude',
                                    hint: 'e.g. 79.8612',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF3F4F6),
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 42,
                                    color:
                                        Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Map location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                      color:
                                          Color(0xFF6B7280),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Map integration can be connected later.',
                                    textAlign:
                                        TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),

            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgress() {
    return Row(
      children: [
        _buildStep(
          number: '1',
          title: 'Type',
          completed: true,
          active: false,
        ),

        Expanded(
          child: Container(
            height: 2,
            color: primaryCyan,
          ),
        ),

        _buildStep(
          number: '2',
          title: 'Basic',
          completed: true,
          active: false,
        ),

        Expanded(
          child: Container(
            height: 2,
            color: primaryCyan,
          ),
        ),

        _buildStep(
          number: '3',
          title: 'Location',
          completed: false,
          active: true,
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required bool completed,
    required bool active,
  }) {
    final Color circleColor;

    if (completed || active) {
      circleColor = primaryCyan;
    } else {
      circleColor = const Color(0xFFE5E7EB);
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: completed
              ? const Icon(
                  Icons.check,
                  size: 17,
                  color: Colors.white,
                )
              : Text(
                  number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : const Color(0xFF9CA3AF),
                  ),
                ),
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                active || completed
                    ? FontWeight.w700
                    : FontWeight.w500,
            color:
                active || completed
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
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
      ),
      child: child,
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text, {
    bool required = true,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
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

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool alignPrefixIcon = false,
  }) {
    return InputDecoration(
      hintText: hintText,

      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),

      prefixIcon: alignPrefixIcon
          ? Padding(
              padding: const EdgeInsets.only(
                bottom: 38,
              ),
              child: Icon(
                prefixIcon,
                color: const Color(0xFF9CA3AF),
                size: 21,
              ),
            )
          : Icon(
              prefixIcon,
              color: const Color(0xFF9CA3AF),
              size: 21,
            ),

      filled: true,

      fillColor: const Color(0xFFF9FAFB),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryCyan,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  // ============================================================
  // COORDINATE FIELD
  // ============================================================

  Widget _buildCoordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: _inputDecoration(
            hintText: hint,
            prefixIcon:
                Icons.my_location_outlined,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return null;
            }

            if (double.tryParse(text) == null) {
              return 'Invalid';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            primaryCyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryCyan,
            size: 21,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Make sure the location information is accurate. '
              'This information will be used for your property listing.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF5F6875),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
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
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Next Step',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}