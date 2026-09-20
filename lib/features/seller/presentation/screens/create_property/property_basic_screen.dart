import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_location_screen.dart';

class PropertyBasicResult {
  final String propertyType;
  final String title;
  final String description;

  const PropertyBasicResult({
    required this.propertyType,
    required this.title,
    required this.description,
  });
}

class PropertyBasicScreen extends StatefulWidget {
  const PropertyBasicScreen({
    super.key,
    required this.propertyType,
  });

  final String propertyType;

  @override
  State<PropertyBasicScreen> createState() =>
      _PropertyBasicScreenState();
}

class _PropertyBasicScreenState
    extends State<PropertyBasicScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // CONTINUE
  // ============================================================

 void _continue() async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) {
    return;
  }

  final result = await Navigator.push<PropertyLocationResult>(
    context,
    MaterialPageRoute(
      builder: (context) => PropertyLocationScreen(
        propertyType: widget.propertyType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    ),
  );

  if (!mounted) {
    return;
  }

  if (result == null) {
    return;
  }

  debugPrint(
    'Property Type: ${result.propertyType}',
  );

  debugPrint(
    'Property Title: ${result.title}',
  );

  debugPrint(
    'Property Description: ${result.description}',
  );

  debugPrint(
    'Address: ${result.address}',
  );

  debugPrint(
    'City: ${result.city}',
  );

  debugPrint(
    'District: ${result.district}',
  );

  debugPrint(
    'Province: ${result.province}',
  );

  debugPrint(
    'Postal Code: ${result.postalCode}',
  );

  debugPrint(
    'Latitude: ${result.latitude}',
  );

  debugPrint(
    'Longitude: ${result.longitude}',
  );

  // Next step:
  // Property Details
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
          'Basic Information',
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
                        'Tell us about your property',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Add the basic information buyers will see '
                        'when viewing your property.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildLabel(
                              'Property Type',
                              required: true,
                            ),

                            const SizedBox(height: 10),

                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    primaryCyan.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      primaryCyan.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          primaryCyan.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.home_work_outlined,
                                      color: primaryCyan,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      widget.propertyType,
                                      style:
                                          const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.check_circle,
                                    color: primaryCyan,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            _buildLabel(
                              'Property Title',
                              required: true,
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _titleController,
                              textInputAction:
                                  TextInputAction.next,
                              maxLength: 150,
                              decoration:
                                  _inputDecoration(
                                hintText:
                                    'Enter property title',
                                prefixIcon:
                                    Icons.title_outlined,
                              ),
                              validator: (value) {
                                final text =
                                    value?.trim() ?? '';

                                if (text.isEmpty) {
                                  return 'Property title is required.';
                                }

                                if (text.length < 3) {
                                  return 'Title must contain at least 3 characters.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            _buildLabel(
                              'Description',
                              required: true,
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  _descriptionController,
                              maxLines: 6,
                              minLines: 5,
                              maxLength: 2000,
                              textInputAction:
                                  TextInputAction.newline,
                              decoration:
                                  _inputDecoration(
                                hintText:
                                    'Describe your property',
                                prefixIcon:
                                    Icons
                                        .description_outlined,
                                alignPrefixIcon: true,
                              ),
                              validator: (value) {
                                final text =
                                    value?.trim() ?? '';

                                if (text.isEmpty) {
                                  return 'Property description is required.';
                                }

                                if (text.length < 10) {
                                  return 'Description must contain at least 10 characters.';
                                }

                                return null;
                              },
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
          completed: false,
          active: true,
        ),

        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFFE5E7EB),
          ),
        ),

        _buildStep(
          number: '3',
          title: 'Location',
          completed: false,
          active: false,
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
    bool required = false,
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
                bottom: 82,
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
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryCyan.withValues(alpha: 0.07),
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
              'You can update your property information '
              'later before submitting the listing.',
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
              borderRadius: BorderRadius.circular(16),
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