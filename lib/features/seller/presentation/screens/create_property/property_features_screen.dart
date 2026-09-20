import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_financials_screen.dart';
import 'property_details_screen.dart';

class PropertyFeaturesResult {
  final PropertyDetailsResult detailsData;
  final List<String> selectedFeatures;

  const PropertyFeaturesResult({
    required this.detailsData,
    required this.selectedFeatures,
  });
}

class PropertyFeaturesScreen extends StatefulWidget {
  final PropertyDetailsResult detailsData;

  const PropertyFeaturesScreen({
    super.key,
    required this.detailsData,
  });

  @override
  State<PropertyFeaturesScreen> createState() =>
      _PropertyFeaturesScreenState();
}

class _PropertyFeaturesScreenState
    extends State<PropertyFeaturesScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);

  final Set<String> _selectedFeatures = {};

  final List<Map<String, dynamic>> _features = [
    {
      'name': 'Swimming Pool',
      'icon': Icons.pool_outlined,
    },
    {
      'name': 'Garden',
      'icon': Icons.yard_outlined,
    },
    {
      'name': 'Balcony',
      'icon': Icons.balcony_outlined,
    },
    {
      'name': 'Parking',
      'icon': Icons.local_parking_outlined,
    },
    {
      'name': 'Security',
      'icon': Icons.security_outlined,
    },
    {
      'name': 'CCTV',
      'icon': Icons.videocam_outlined,
    },
    {
      'name': 'Air Conditioning',
      'icon': Icons.ac_unit_outlined,
    },
    {
      'name': 'Elevator',
      'icon': Icons.elevator_outlined,
    },
    {
      'name': 'Generator',
      'icon': Icons.electrical_services_outlined,
    },
    {
      'name': 'Water Supply',
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Hot Water',
      'icon': Icons.hot_tub_outlined,
    },
    {
      'name': 'Furnished',
      'icon': Icons.weekend_outlined,
    },
    {
      'name': 'Gym',
      'icon': Icons.fitness_center_outlined,
    },
    {
      'name': 'Gated Community',
      'icon': Icons.fence_outlined,
    },
    {
      'name': 'Road Access',
      'icon': Icons.add_road_outlined,
    },
    {
      'name': 'Fenced',
      'icon': Icons.fence_outlined,
    },
  ];

  void _toggleFeature(String feature) {
    setState(() {
      if (_selectedFeatures.contains(feature)) {
        _selectedFeatures.remove(feature);
      } else {
        _selectedFeatures.add(feature);
      }
    });
  }

Future<void> _continue() async {
  FocusScope.of(context).unfocus();

  final result = PropertyFeaturesResult(
    detailsData: widget.detailsData,
    selectedFeatures: _selectedFeatures.toList(),
  );

  final financialResult =
      await Navigator.push<PropertyFinancialsResult>(
    context,
    MaterialPageRoute(
      builder: (_) => PropertyFinancialsScreen(
        featuresData: result,
      ),
    ),
  );

  if (financialResult != null && mounted) {
    Navigator.pop(context, financialResult);
  }
}
  @override
  Widget build(BuildContext context) {
    final propertyType =
        widget.detailsData.locationData.propertyType;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Features',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    const Text(
                      'What does your property offer?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Select all the features and amenities '
                      'available at your property.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildPropertyTypeCard(propertyType),

                    const SizedBox(height: 24),

                    const Text(
                      'Features & Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureGrid(),

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
    final steps = [
      'Type',
      'Basic',
      'Location',
      'Details',
      'Features',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: List.generate(
          steps.length,
          (index) {
            final isActive = index == 4;
            final isCompleted = index < 4;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive || isCompleted
                              ? primaryColor
                              : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.black45,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? primaryColor
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),

                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.only(
                          bottom: 20,
                          left: 4,
                          right: 4,
                        ),
                        color: index < 4
                            ? primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
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
              Icons.home_work_outlined,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property Type',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildFeatureGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _features.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final feature = _features[index];
        final name = feature['name'] as String;
        final icon = feature['icon'] as IconData;

        final isSelected =
            _selectedFeatures.contains(name);

        return InkWell(
          onTap: () => _toggleFeature(name),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : Colors.grey.shade200,
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
                    color: isSelected
                        ? primaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: isSelected
                        ? Colors.white
                        : Colors.black54,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),

                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: 20,
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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'You can select multiple features. '
              'These details will help buyers understand '
              'what your property offers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
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
      child: SizedBox(
        width: double.infinity,
        height: 54,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}