import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_media_screen.dart';

import 'property_financials_screen.dart';

class PropertyLegalDetailsResult {
  final PropertyFinancialsResult financialData;

  final String ownershipType;
  final String deedNumber;
  final String deedDate;
  final String landRegistryNumber;
  final String surveyPlanNumber;
  final String localAuthority;
  final String assessmentNumber;
  final bool clearTitle;
  final bool legalDispute;
  final String legalNotes;

  const PropertyLegalDetailsResult({
    required this.financialData,
    required this.ownershipType,
    required this.deedNumber,
    required this.deedDate,
    required this.landRegistryNumber,
    required this.surveyPlanNumber,
    required this.localAuthority,
    required this.assessmentNumber,
    required this.clearTitle,
    required this.legalDispute,
    required this.legalNotes,
  });
}

class PropertyLegalDetailsScreen extends StatefulWidget {
  final PropertyFinancialsResult financialData;

  const PropertyLegalDetailsScreen({
    super.key,
    required this.financialData,
  });

  @override
  State<PropertyLegalDetailsScreen> createState() =>
      _PropertyLegalDetailsScreenState();
}

class _PropertyLegalDetailsScreenState
    extends State<PropertyLegalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _deedNumberController = TextEditingController();
  final _deedDateController = TextEditingController();
  final _landRegistryController = TextEditingController();
  final _surveyPlanController = TextEditingController();
  final _localAuthorityController = TextEditingController();
  final _assessmentNumberController = TextEditingController();
  final _legalNotesController = TextEditingController();

  String _ownershipType = 'Freehold';
  bool _clearTitle = true;
  bool _legalDispute = false;

  static const Color primaryColor = Color(0xFF00C6D4);

  @override
  void dispose() {
    _deedNumberController.dispose();
    _deedDateController.dispose();
    _landRegistryController.dispose();
    _surveyPlanController.dispose();
    _localAuthorityController.dispose();
    _assessmentNumberController.dispose();
    _legalNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeedDate() async {
    FocusScope.of(context).unfocus();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    setState(() {
      _deedDateController.text = '$day/$month/$year';
    });
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = PropertyLegalDetailsResult(
      financialData: widget.financialData,
      ownershipType: _ownershipType,
      deedNumber: _deedNumberController.text.trim(),
      deedDate: _deedDateController.text.trim(),
      landRegistryNumber: _landRegistryController.text.trim(),
      surveyPlanNumber: _surveyPlanController.text.trim(),
      localAuthority: _localAuthorityController.text.trim(),
      assessmentNumber: _assessmentNumberController.text.trim(),
      clearTitle: _clearTitle,
      legalDispute: _legalDispute,
      legalNotes: _legalNotesController.text.trim(),
    );

final mediaResult =
    await Navigator.push<PropertyMediaResult>(
  context,
  MaterialPageRoute(
    builder: (_) => PropertyMediaScreen(
      legalData: result,
    ),
  ),
);

if (mediaResult != null && mounted) {
  Navigator.pop(context, mediaResult);
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Legal Details',
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
                        'Tell us about the legal details',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Provide the ownership and legal information related to your property.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Ownership',
                        Icons.person_outline,
                      ),

                      const SizedBox(height: 12),

                      _buildOwnershipDropdown(),

                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _deedNumberController,
                        label: 'Deed Number',
                        hint: 'Enter deed number',
                      ),

                      const SizedBox(height: 12),

                      _buildDateField(),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Property Documents',
                        Icons.description_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _landRegistryController,
                        label: 'Land Registry Number',
                        hint: 'Enter land registry number',
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _surveyPlanController,
                        label: 'Survey Plan Number',
                        hint: 'Enter survey plan number',
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Local Authority',
                        Icons.account_balance_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _localAuthorityController,
                        label: 'Local Authority',
                        hint: 'Enter local authority',
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _assessmentNumberController,
                        label: 'Assessment Number',
                        hint: 'Enter assessment number',
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Legal Status',
                        Icons.gavel_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildSwitchCard(
                        title: 'Clear Title',
                        subtitle:
                            'The property has a clear title with no known ownership issues.',
                        value: _clearTitle,
                        onChanged: (value) {
                          setState(() {
                            _clearTitle = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildSwitchCard(
                        title: 'Legal Dispute',
                        subtitle:
                            'There is a current or known legal dispute related to this property.',
                        value: _legalDispute,
                        onChanged: (value) {
                          setState(() {
                            _legalDispute = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'Additional Information',
                        Icons.notes_outlined,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _legalNotesController,
                        label: 'Legal Notes',
                        hint:
                            'Add any additional legal information',
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
    const steps = [
      'Type',
      'Basic',
      'Location',
      'Details',
      'Features',
      'Financial',
      'Legal',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: List.generate(
          steps.length,
          (index) {
            final isActive = index == 6;
            final isCompleted = index < 6;

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
                        width: 27,
                        height: 27,
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
                                  size: 15,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
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
                            color: index < 6
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
                      fontSize: 9,
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

  Widget _buildOwnershipDropdown() {
    return DropdownButtonFormField<String>(
      value: _ownershipType,
      decoration: InputDecoration(
        labelText: 'Ownership Type',
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
      ),
      items: const [
        DropdownMenuItem(
          value: 'Freehold',
          child: Text('Freehold'),
        ),
        DropdownMenuItem(
          value: 'Leasehold',
          child: Text('Leasehold'),
        ),
        DropdownMenuItem(
          value: 'Joint Ownership',
          child: Text('Joint Ownership'),
        ),
        DropdownMenuItem(
          value: 'Other',
          child: Text('Other'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _ownershipType = value;
        });
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _deedDateController,
      readOnly: true,
      onTap: _selectDeedDate,
      decoration: InputDecoration(
        labelText: 'Deed Date',
        hintText: 'Select deed date',
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: primaryColor,
        ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 3,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
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
              'Make sure the legal information you provide is accurate. You can review the details before submitting the property.',
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