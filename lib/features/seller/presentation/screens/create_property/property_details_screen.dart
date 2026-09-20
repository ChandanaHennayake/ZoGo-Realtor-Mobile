import 'package:flutter/material.dart';

import 'property_location_screen.dart';
import 'property_features_screen.dart';

class PropertyDetailsResult {
  final PropertyLocationResult locationData;
  final double? propertyArea;
  final String areaUnit;
  final int bedrooms;
  final int bathrooms;
  final int parkingSpaces;
  final int floors;
  final int? floorNumber;
  final String furnishing;
  final String condition;
  final int? yearBuilt;

  const PropertyDetailsResult({
    required this.locationData,
    required this.propertyArea,
    required this.areaUnit,
    required this.bedrooms,
    required this.bathrooms,
    required this.parkingSpaces,
    required this.floors,
    required this.floorNumber,
    required this.furnishing,
    required this.condition,
    required this.yearBuilt,
  });
}

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyLocationResult locationData;

  const PropertyDetailsScreen({
    super.key,
    required this.locationData,
  });

  @override
  State<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _areaUnit = 'sq.ft';

  int _bedrooms = 0;
  int _bathrooms = 0;
  int _parkingSpaces = 0;
  int _floors = 1;
  int _floorNumber = 1;

  String _furnishing = 'Unfurnished';
  String _condition = 'Good';

  @override
  void dispose() {
    _areaController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool get _isApartment {
    return widget.locationData.propertyType.toLowerCase() == 'apartment';
  }

  bool get _isLand {
    return widget.locationData.propertyType.toLowerCase() == 'land';
  }

  void _increaseValue(
    int currentValue,
    void Function(int value) onChanged,
  ) {
    onChanged(currentValue + 1);
  }

  void _decreaseValue(
    int currentValue,
    void Function(int value) onChanged,
  ) {
    if (currentValue > 0) {
      onChanged(currentValue - 1);
    }
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = PropertyDetailsResult(
      locationData: widget.locationData,
      propertyArea: double.tryParse(
        _areaController.text.trim(),
      ),
      areaUnit: _areaUnit,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      parkingSpaces: _parkingSpaces,
      floors: _floors,
      floorNumber: _isApartment ? _floorNumber : null,
      furnishing: _furnishing,
      condition: _condition,
      yearBuilt: int.tryParse(
        _yearController.text.trim(),
      ),
    );

    final featuresResult =
        await Navigator.push<PropertyFeaturesResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyFeaturesScreen(
          detailsData: result,
        ),
      ),
    );

    if (featuresResult != null && mounted) {
      Navigator.pop(context, featuresResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Property Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProgressIndicator(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tell us more about your property',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Add some details to help buyers understand your property better.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        'Property Size',
                        Icons.straighten_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildAreaField(),

                      const SizedBox(height: 28),

                      if (!_isLand) ...[
                        _buildSectionTitle(
                          'Rooms',
                          Icons.bed_outlined,
                        ),

                        const SizedBox(height: 12),

                        _buildCounterCard(
                          title: 'Bedrooms',
                          subtitle: 'Number of bedrooms',
                          icon: Icons.bed_outlined,
                          value: _bedrooms,
                          onDecrease: () {
                            _decreaseValue(
                              _bedrooms,
                              (value) {
                                setState(() => _bedrooms = value);
                              },
                            );
                          },
                          onIncrease: () {
                            _increaseValue(
                              _bedrooms,
                              (value) {
                                setState(() => _bedrooms = value);
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildCounterCard(
                          title: 'Bathrooms',
                          subtitle: 'Number of bathrooms',
                          icon: Icons.bathtub_outlined,
                          value: _bathrooms,
                          onDecrease: () {
                            _decreaseValue(
                              _bathrooms,
                              (value) {
                                setState(() => _bathrooms = value);
                              },
                            );
                          },
                          onIncrease: () {
                            _increaseValue(
                              _bathrooms,
                              (value) {
                                setState(() => _bathrooms = value);
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 28),
                      ],

                      _buildSectionTitle(
                        'Parking & Floors',
                        Icons.local_parking_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildCounterCard(
                        title: 'Parking Spaces',
                        subtitle: 'Available parking spaces',
                        icon: Icons.local_parking_outlined,
                        value: _parkingSpaces,
                        onDecrease: () {
                          _decreaseValue(
                            _parkingSpaces,
                            (value) {
                              setState(() => _parkingSpaces = value);
                            },
                          );
                        },
                        onIncrease: () {
                          _increaseValue(
                            _parkingSpaces,
                            (value) {
                              setState(() => _parkingSpaces = value);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildCounterCard(
                        title: 'Number of Floors',
                        subtitle: 'Total floors in the property',
                        icon: Icons.layers_outlined,
                        value: _floors,
                        minimumValue: 1,
                        onDecrease: () {
                          if (_floors > 1) {
                            setState(() {
                              _floors--;

                              if (_floorNumber > _floors) {
                                _floorNumber = _floors;
                              }
                            });
                          }
                        },
                        onIncrease: () {
                          setState(() => _floors++);
                        },
                      ),

                      if (_isApartment) ...[
                        const SizedBox(height: 12),

                        _buildCounterCard(
                          title: 'Floor Number',
                          subtitle:
                              'Which floor is the apartment on?',
                          icon: Icons.apartment_outlined,
                          value: _floorNumber,
                          minimumValue: 1,
                          onDecrease: () {
                            if (_floorNumber > 1) {
                              setState(() => _floorNumber--);
                            }
                          },
                          onIncrease: () {
                            if (_floorNumber < _floors) {
                              setState(() => _floorNumber++);
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        'Property Condition',
                        Icons.home_work_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildDropdownCard(
                        value: _condition,
                        items: const [
                          'New',
                          'Excellent',
                          'Good',
                          'Needs Renovation',
                        ],
                        icon: Icons.home_work_outlined,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _condition = value);
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      if (!_isLand) ...[
                        _buildSectionTitle(
                          'Furnishing',
                          Icons.chair_outlined,
                        ),

                        const SizedBox(height: 12),

                        _buildFurnishingSelector(),

                        const SizedBox(height: 28),
                      ],

                      _buildSectionTitle(
                        'Year Built',
                        Icons.calendar_today_outlined,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: _inputDecoration(
                          hintText: 'e.g. 2020',
                          prefixIcon:
                              Icons.calendar_today_outlined,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return null;
                          }

                          final year = int.tryParse(text);

                          if (year == null) {
                            return 'Enter a valid year';
                          }

                          if (year < 1800 ||
                              year > DateTime.now().year) {
                            return 'Enter a valid year';
                          }

                          return null;
                        },
                      ),

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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _buildProgressItem(
            number: '1',
            title: 'Type',
            completed: true,
            active: false,
          ),

          _buildProgressLine(true),

          _buildProgressItem(
            number: '2',
            title: 'Basic',
            completed: true,
            active: false,
          ),

          _buildProgressLine(true),

          _buildProgressItem(
            number: '3',
            title: 'Location',
            completed: true,
            active: false,
          ),

          _buildProgressLine(true),

          _buildProgressItem(
            number: '4',
            title: 'Details',
            completed: false,
            active: true,
          ),

          _buildProgressLine(false),

          _buildProgressItem(
            number: '5',
            title: 'Features',
            completed: false,
            active: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String number,
    required String title,
    required bool completed,
    required bool active,
  }) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: completed || active
                ? primaryColor
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed || active
                  ? primaryColor
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Center(
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
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : Colors.black54,
                    ),
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
                    ? FontWeight.w600
                    : FontWeight.w500,
            color: active || completed
                ? primaryColor
                : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool completed) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(
          left: 5,
          right: 5,
          bottom: 18,
        ),
        color: completed
            ? primaryColor
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _areaController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _inputDecoration(
              hintText: 'e.g. 1500',
              prefixIcon: Icons.straighten_outlined,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.isEmpty) {
                return 'Enter property area';
              }

              final area = double.tryParse(text);

              if (area == null || area <= 0) {
                return 'Enter a valid area';
              }

              return null;
            },
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 115,
          child: DropdownButtonFormField<String>(
            initialValue: _areaUnit,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sq.ft',
                child: Text('sq.ft'),
              ),
              DropdownMenuItem(
                value: 'perches',
                child: Text('Perches'),
              ),
              DropdownMenuItem(
                value: 'acres',
                child: Text('Acres'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _areaUnit = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCounterCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    int minimumValue = 0,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          _buildCounterButton(
            icon: Icons.remove,
            enabled: value > minimumValue,
            onTap: onDecrease,
          ),

          SizedBox(
            width: 42,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          _buildCounterButton(
            icon: Icons.add,
            enabled: true,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Colors.black87
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 23,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (item) =>
                          DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnishingSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFurnishingOption(
            title: 'Unfurnished',
            icon: Icons.weekend_outlined,
            selected: _furnishing == 'Unfurnished',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFurnishingOption(
            title: 'Furnished',
            icon: Icons.chair_outlined,
            selected: _furnishing == 'Furnished',
          ),
        ),
      ],
    );
  }

  Widget _buildFurnishingOption({
    required String title,
    required IconData icon,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _furnishing = title;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? primaryColor
                  : Colors.black45,
              size: 22,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: selected
                      ? primaryColor
                      : Colors.black87,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 19,
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.black38,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: primaryColor,
        size: 21,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can update these details before publishing your property.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}