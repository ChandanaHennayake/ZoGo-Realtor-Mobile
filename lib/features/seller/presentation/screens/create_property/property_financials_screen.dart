import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_legal_screen.dart';

import 'property_features_screen.dart';

class PropertyFinancialsResult {
  final PropertyFeaturesResult featuresData;

  final String sellingPrice;
  final bool priceNegotiable;
  final String monthlyRent;
  final String advancePayment;
  final String maintenanceFee;
  final String otherCharges;
  final String financialNotes;

  const PropertyFinancialsResult({
    required this.featuresData,
    required this.sellingPrice,
    required this.priceNegotiable,
    required this.monthlyRent,
    required this.advancePayment,
    required this.maintenanceFee,
    required this.otherCharges,
    required this.financialNotes,
  });
}

class PropertyFinancialsScreen extends StatefulWidget {
  final PropertyFeaturesResult featuresData;

  const PropertyFinancialsScreen({
    super.key,
    required this.featuresData,
  });

  @override
  State<PropertyFinancialsScreen> createState() =>
      _PropertyFinancialsScreenState();
}

class _PropertyFinancialsScreenState
    extends State<PropertyFinancialsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _sellingPriceController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _advancePaymentController = TextEditingController();
  final _maintenanceFeeController = TextEditingController();
  final _otherChargesController = TextEditingController();
  final _financialNotesController = TextEditingController();

  bool _priceNegotiable = false;

  static const Color primaryColor = Color(0xFF00C6D4);

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _monthlyRentController.dispose();
    _advancePaymentController.dispose();
    _maintenanceFeeController.dispose();
    _otherChargesController.dispose();
    _financialNotesController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = PropertyFinancialsResult(
      featuresData: widget.featuresData,
      sellingPrice: _sellingPriceController.text.trim(),
      priceNegotiable: _priceNegotiable,
      monthlyRent: _monthlyRentController.text.trim(),
      advancePayment: _advancePaymentController.text.trim(),
      maintenanceFee: _maintenanceFeeController.text.trim(),
      otherCharges: _otherChargesController.text.trim(),
      financialNotes: _financialNotesController.text.trim(),
    );

 final legalResult =
    await Navigator.push<PropertyLegalDetailsResult>(
  context,
  MaterialPageRoute(
    builder: (_) => PropertyLegalDetailsScreen(
      financialData: result,
    ),
  ),
);

if (legalResult != null && mounted) {
  Navigator.pop(context, legalResult);
}
  }

  @override
  Widget build(BuildContext context) {
    final propertyType =
        widget.featuresData.detailsData.locationData.propertyType;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Financial Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProgress(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      const Text(
                        'Tell us about the financial details',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Add the pricing and other financial information for your $propertyType.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Pricing',
                        Icons.payments_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _sellingPriceController,
                        label: 'Selling Price',
                        hint: 'Enter selling price',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selling price is required';
                          }

                          final price = double.tryParse(
                            value.replaceAll(',', '').trim(),
                          );

                          if (price == null || price <= 0) {
                            return 'Enter a valid price';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildNegotiableCard(),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Additional Financial Information',
                        Icons.account_balance_wallet_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _monthlyRentController,
                        label: 'Monthly Rent',
                        hint: 'Enter monthly rent if applicable',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _advancePaymentController,
                        label: 'Advance Payment',
                        hint: 'Enter advance payment if applicable',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _maintenanceFeeController,
                        label: 'Maintenance Fee',
                        hint: 'Enter maintenance fee if applicable',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _otherChargesController,
                        label: 'Other Charges',
                        hint: 'Enter any other charges',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Notes',
                        Icons.notes_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _financialNotesController,
                        label: 'Financial Notes',
                        hint: 'Add any additional financial information',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 20),

                      _buildInfoCard(),

                      const SizedBox(height: 25),

                      SizedBox(
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
                          child: const Text(
                            'Next Step',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      'Financial',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(
        children: List.generate(
          steps.length,
          (index) {
            final isActive = index == 5;
            final isCompleted = index < 5;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),

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
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),

                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < 5
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isActive
                          ? primaryColor
                          : Colors.grey.shade600,
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

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNegotiableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: SwitchListTile(
        value: _priceNegotiable,
        onChanged: (value) {
          setState(() {
            _priceNegotiable = value;
          });
        },
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 3,
        ),
        title: const Text(
          'Price is negotiable',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Allow potential buyers to negotiate the listed price.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
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
              'You can review and update your property information before submitting the listing.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}