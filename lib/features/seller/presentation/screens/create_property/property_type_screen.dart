import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_basic_screen.dart';

class PropertyTypeScreen extends StatefulWidget {
  const PropertyTypeScreen({
    super.key,
  });

  @override
  State<PropertyTypeScreen> createState() => _PropertyTypeScreenState();
}

class _PropertyTypeScreenState extends State<PropertyTypeScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  int? _selectedIndex;

  final List<_PropertyTypeOption> _propertyTypes = const [
    _PropertyTypeOption(
      title: 'House',
      description: 'Residential houses and homes',
      icon: Icons.home_outlined,
    ),
    _PropertyTypeOption(
      title: 'Apartment',
      description: 'Apartments and condominiums',
      icon: Icons.apartment_outlined,
    ),
    _PropertyTypeOption(
      title: 'Land',
      description: 'Residential and other land',
      icon: Icons.landscape_outlined,
    ),
    _PropertyTypeOption(
      title: 'Commercial',
      description: 'Commercial properties',
      icon: Icons.storefront_outlined,
    ),
  ];

  void _selectPropertyType(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _continue() async {
  if (_selectedIndex == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a property type.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final selectedType =
      _propertyTypes[_selectedIndex!].title;

  final result = await Navigator.push<PropertyBasicResult>(
    context,
    MaterialPageRoute(
      builder: (context) => PropertyBasicScreen(
        propertyType: selectedType,
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

  // Next step will receive this data
  // and create the property using the
  // existing backend DTO.
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'List Property',
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
                  28,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What are you listing?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Select the type of property you want to list.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 28),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _propertyTypes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildPropertyTypeCard(
                          index,
                          _propertyTypes[index],
                        );
                      },
                    ),
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

  Widget _buildPropertyTypeCard(
    int index,
    _PropertyTypeOption option,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectPropertyType(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primaryCyan
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryCyan.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryCyan.withValues(alpha: 0.12)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                option.icon,
                size: 28,
                color: isSelected
                    ? primaryCyan
                    : const Color(0xFF6B7280),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? primaryCyan
                          : const Color(0xFF1A1A1A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    option.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? primaryCyan
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected
                    ? primaryCyan
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final canContinue = _selectedIndex != null;

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
          onPressed: canContinue ? _continue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                const Color(0xFFD1D5DB),
            disabledForegroundColor:
                const Color(0xFF9CA3AF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Continue',
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

class _PropertyTypeOption {
  final String title;
  final String description;
  final IconData icon;

  const _PropertyTypeOption({
    required this.title,
    required this.description,
    required this.icon,
  });
}