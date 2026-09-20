import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_details_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_features_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_financials_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_legal_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_location_screen.dart';

import 'property_media_screen.dart';

class PropertyReviewScreen extends StatefulWidget {
  final PropertyMediaResult mediaData;

  const PropertyReviewScreen({
    super.key,
    required this.mediaData,
  });

  @override
  State<PropertyReviewScreen> createState() => _PropertyReviewScreenState();
}

class _PropertyReviewScreenState extends State<PropertyReviewScreen> {
  bool _isSubmitting = false;

  Color get _primaryColor => const Color(0xFF00C6D4);

  PropertyLegalDetailsResult get _legalData =>
      widget.mediaData.legalData;

  PropertyFinancialsResult get _financialData =>
      _legalData.financialData;

  PropertyFeaturesResult get _featuresData =>
      _financialData.featuresData;

  PropertyDetailsResult get _detailsData =>
      _featuresData.detailsData;

  PropertyLocationResult get _locationData =>
      _detailsData.locationData;

  Future<void> _submitProperty() async {
    setState(() {
      _isSubmitting = true;
    });

    // UI ONLY FOR NOW.
    //
    // Backend integration will be added later:
    //
    // 1. Create property
    // 2. Get propertyId
    // 3. Save features
    // 4. Save financial details
    // 5. Save legal details
    // 6. Upload photos
    // 7. Upload documents
    //
    // Do not call the media API yet because it requires
    // a real propertyId.

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ready to Submit'),
          content: const Text(
            'Your property information has been collected successfully. '
            'Backend submission will be connected next.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _displayValue(String value) {
    return value.trim().isEmpty ? 'Not provided' : value.trim();
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return 'Not provided';
    }

    return value % 1 == 0
        ? value.toInt().toString()
        : value.toString();
  }

  String _formatBool(bool value) {
    return value ? 'Yes' : 'No';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFB),
      appBar: AppBar(
        title: const Text('Review Property'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
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
                  12,
                  20,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    _buildBasicSection(),
                    const SizedBox(height: 14),

                    _buildLocationSection(),
                    const SizedBox(height: 14),

                    _buildDetailsSection(),
                    const SizedBox(height: 14),

                    _buildFeaturesSection(),
                    const SizedBox(height: 14),

                    _buildFinancialSection(),
                    const SizedBox(height: 14),

                    _buildLegalSection(),
                    const SizedBox(height: 14),

                    _buildMediaSection(),
                    const SizedBox(height: 20),

                    _buildFinalInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
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
      'Legal',
      'Media',
      'Review',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            steps.length,
            (index) {
              final isLast = index == steps.length - 1;

              return Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          index == steps.length - 1
                              ? Icons.check
                              : Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      width: 25,
                      height: 2,
                      margin: const EdgeInsets.only(
                        left: 5,
                        right: 5,
                        bottom: 18,
                      ),
                      color: _primaryColor,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your property',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please check all the information before submitting your property.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicSection() {
    return _buildSectionCard(
      icon: Icons.home_outlined,
      title: 'Basic Information',
      children: [
        _buildRow(
          'Property Type',
          _locationData.propertyType,
        ),
        _buildRow(
          'Title',
          _locationData.title,
        ),
        _buildRow(
          'Description',
          _locationData.description,
          multiline: true,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      icon: Icons.location_on_outlined,
      title: 'Location',
      children: [
        _buildRow(
          'Address',
          _locationData.address,
          multiline: true,
        ),
        _buildRow(
          'City',
          _locationData.city,
        ),
        _buildRow(
          'District',
          _locationData.district,
        ),
        _buildRow(
          'Province',
          _locationData.province,
        ),
        _buildRow(
          'Postal Code',
          _displayValue(_locationData.postalCode),
        ),
        _buildRow(
          'Latitude',
          _formatNumber(_locationData.latitude),
        ),
        _buildRow(
          'Longitude',
          _formatNumber(_locationData.longitude),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _buildSectionCard(
      icon: Icons.home_work_outlined,
      title: 'Property Details',
      children: [
        _buildRow(
          'Property Area',
          _detailsData.propertyArea == null
              ? 'Not provided'
              : '${_formatNumber(_detailsData.propertyArea)} ${_detailsData.areaUnit}',
        ),
        if (_detailsData.bedrooms > 0)
          _buildRow(
            'Bedrooms',
            _detailsData.bedrooms.toString(),
          ),
        if (_detailsData.bathrooms > 0)
          _buildRow(
            'Bathrooms',
            _detailsData.bathrooms.toString(),
          ),
        _buildRow(
          'Parking Spaces',
          _detailsData.parkingSpaces.toString(),
        ),
        _buildRow(
          'Floors',
          _detailsData.floors.toString(),
        ),
        if (_detailsData.floorNumber != null)
          _buildRow(
            'Floor Number',
            _detailsData.floorNumber.toString(),
          ),
        _buildRow(
          'Furnishing',
          _detailsData.furnishing,
        ),
        _buildRow(
          'Condition',
          _detailsData.condition,
        ),
        _buildRow(
          'Year Built',
          _detailsData.yearBuilt?.toString() ?? 'Not provided',
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return _buildSectionCard(
      icon: Icons.star_border,
      title: 'Features',
      children: [
        if (_featuresData.selectedFeatures.isEmpty)
          _buildRow(
            'Selected Features',
            'No features selected',
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _featuresData.selectedFeatures
                  .map(
                    (feature) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return _buildSectionCard(
      icon: Icons.payments_outlined,
      title: 'Financial Details',
      children: [
        _buildRow(
          'Selling Price',
          _displayValue(_financialData.sellingPrice),
        ),
        _buildRow(
          'Price Negotiable',
          _formatBool(_financialData.priceNegotiable),
        ),
        _buildRow(
          'Monthly Rent',
          _displayValue(_financialData.monthlyRent),
        ),
        _buildRow(
          'Advance Payment',
          _displayValue(_financialData.advancePayment),
        ),
        _buildRow(
          'Maintenance Fee',
          _displayValue(_financialData.maintenanceFee),
        ),
        _buildRow(
          'Other Charges',
          _displayValue(_financialData.otherCharges),
        ),
        if (_financialData.financialNotes.trim().isNotEmpty)
          _buildRow(
            'Notes',
            _financialData.financialNotes,
            multiline: true,
          ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return _buildSectionCard(
      icon: Icons.gavel_outlined,
      title: 'Legal Details',
      children: [
        _buildRow(
          'Ownership Type',
          _legalData.ownershipType,
        ),
        _buildRow(
          'Deed Number',
          _displayValue(_legalData.deedNumber),
        ),
        _buildRow(
          'Deed Date',
          _displayValue(_legalData.deedDate),
        ),
        _buildRow(
          'Land Registry Number',
          _displayValue(_legalData.landRegistryNumber),
        ),
        _buildRow(
          'Survey Plan Number',
          _displayValue(_legalData.surveyPlanNumber),
        ),
        _buildRow(
          'Local Authority',
          _displayValue(_legalData.localAuthority),
        ),
        _buildRow(
          'Assessment Number',
          _displayValue(_legalData.assessmentNumber),
        ),
        _buildRow(
          'Clear Title',
          _formatBool(_legalData.clearTitle),
        ),
        _buildRow(
          'Legal Dispute',
          _formatBool(_legalData.legalDispute),
        ),
        if (_legalData.legalNotes.trim().isNotEmpty)
          _buildRow(
            'Legal Notes',
            _legalData.legalNotes,
            multiline: true,
          ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return _buildSectionCard(
      icon: Icons.photo_library_outlined,
      title: 'Property Media',
      children: [
        _buildRow(
          'Photos',
          '${widget.mediaData.photos.length} photo(s)',
        ),
        _buildRow(
          'Documents',
          '${widget.mediaData.documents.length} document(s)',
        ),
        if (widget.mediaData.photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.mediaData.photos.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final file = widget.mediaData.photos[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: multiline ? null : 2,
              overflow:
                  multiline ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please make sure all property information is '
              'correct before submitting. You can update '
              'eligible information later.',
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
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : _submitProperty,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                _primaryColor.withValues(alpha: 0.5),
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
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text(
                      'Submit Property',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}