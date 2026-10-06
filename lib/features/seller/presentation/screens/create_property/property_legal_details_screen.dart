import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_documents_screen.dart';

class PropertyLegalDetailsScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyLegalDetailsScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyLegalDetailsScreen> createState() =>
      _PropertyLegalDetailsScreenState();
}

class _PropertyLegalDetailsScreenState
    extends State<PropertyLegalDetailsScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();
  final SellerService _sellerService = SellerService();

  final TextEditingController _mortgageProviderController =
      TextEditingController();
  final TextEditingController _legalIssueDescriptionController =
      TextEditingController();

  int _ownershipType = 1; // 1: Freehold, 2: Leasehold, 3: Condominium Title, 4: Joint Ownership
  bool _hasMortgage = false;
  bool _hasLegalIssues = false;
  bool _legalVerified = false;

  bool _isLoading = true;
  bool _isSaving = false;

  static const Map<int, String> _ownershipOptions = {
    1: 'Freehold',
    2: 'Leasehold',
    3: 'Condo / Strata Title',
    4: 'Joint Ownership',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingLegalDetails();
  }

  @override
  void dispose() {
    _mortgageProviderController.dispose();
    _legalIssueDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLegalDetails() async {
    try {
      final data =
          await _sellerService.getPropertyLegalDetails(widget.propertyId);
      if (data != null && mounted) {
        setState(() {
          if (data['ownershipType'] != null) {
            _ownershipType = (data['ownershipType'] as num).toInt();
          }
          if (data['hasMortgage'] != null) {
            _hasMortgage = data['hasMortgage'] == true;
          }
          if (data['mortgageProvider'] != null) {
            _mortgageProviderController.text =
                data['mortgageProvider'].toString();
          }
          if (data['hasLegalIssues'] != null) {
            _hasLegalIssues = data['hasLegalIssues'] == true;
          }
          if (data['legalIssueDescription'] != null) {
            _legalIssueDescriptionController.text =
                data['legalIssueDescription'].toString();
          }
          if (data['legalVerified'] != null) {
            _legalVerified = data['legalVerified'] == true;
          }
        });
      }
    } catch (_) {
      // Non-blocking if legal details do not exist yet
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLegalDetailsAndProceed({bool exitAfterSave = false}) async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = <String, dynamic>{
        'ownershipType': _ownershipType,
        'hasMortgage': _hasMortgage,
        'mortgageProvider': _hasMortgage &&
                _mortgageProviderController.text.trim().isNotEmpty
            ? _mortgageProviderController.text.trim()
            : null,
        'hasLegalIssues': _hasLegalIssues,
        'legalIssueDescription': _hasLegalIssues &&
                _legalIssueDescriptionController.text.trim().isNotEmpty
            ? _legalIssueDescriptionController.text.trim()
            : null,
        'legalVerified': _legalVerified,
        'verifiedBy': null,
        'verifiedAt': null,
      };

      await _sellerService.savePropertyLegalDetails(
        widget.propertyId,
        payload,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legal details saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (exitAfterSave) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
        return;
      }

      // Navigate to Next Step: Documents
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDocumentsScreen(
            propertyId: widget.propertyId,
            propertyType: widget.propertyType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save legal details: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeName = widget.propertyType ?? 'Property';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Property Legal Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : Column(
                children: [
                  _buildProgress(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Title & Legal Clearances',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Declare property deed type, bank mortgage status, and any active legal disputes.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildPropertyTypeCard(typeName),
                            const SizedBox(height: 24),

                            // Ownership Type Section
                            _buildSectionHeader(
                              icon: Icons.gavel_outlined,
                              title: 'Deed / Ownership Type',
                              subtitle:
                                  'Legal structure of ownership for this real estate',
                            ),
                            const SizedBox(height: 12),
                            _buildOwnershipTypeGrid(),
                            const SizedBox(height: 24),

                            // Mortgage Status
                            _buildMortgageCard(),
                            if (_hasMortgage) ...[
                              const SizedBox(height: 12),
                              _buildMortgageProviderField(),
                            ],
                            const SizedBox(height: 20),

                            // Legal Disputes
                            _buildLegalIssuesCard(),
                            if (_hasLegalIssues) ...[
                              const SizedBox(height: 12),
                              _buildLegalIssuesDescriptionField(),
                            ],
                            const SizedBox(height: 20),

                            // Legal Verification Status
                            _buildVerificationCard(),

                            const SizedBox(height: 24),
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

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          _buildStepItem(number: '1', title: 'Basic', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '2', title: 'Features', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '3', title: 'Amenities', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '4', title: 'Financials', isCompleted: true, isActive: false),
          _buildStepLine(true),
          _buildStepItem(number: '5', title: 'Legal', isCompleted: false, isActive: true),
          _buildStepLine(false),
          _buildStepItem(number: '6', title: 'Docs', isCompleted: false, isActive: false),
          _buildStepLine(false),
          _buildStepItem(number: '7', title: 'Media', isCompleted: false, isActive: false),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: isCompleted ? primaryColor : const Color(0xFFE5E7EB),
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
            color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black45,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? primaryColor : Colors.black87,
          ),
        ),
      ],
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
              Icons.policy_outlined,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property ID: ${widget.propertyId.length > 12 ? '${widget.propertyId.substring(0, 12)}...' : widget.propertyId}',
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 18),
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
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnershipTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _ownershipOptions.entries.map((entry) {
        final isSelected = _ownershipType == entry.key;
        return InkWell(
          onTap: () {
            setState(() {
              _ownershipType = entry.key;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.10)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMortgageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: _hasMortgage,
        onChanged: (val) {
          setState(() {
            _hasMortgage = val;
            if (!val) _mortgageProviderController.clear();
          });
        },
        activeThumbColor: primaryColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Active Bank Mortgage',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Is this property currently encumbered with a bank mortgage loan?',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildMortgageProviderField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: TextFormField(
        controller: _mortgageProviderController,
        validator: (value) {
          if (_hasMortgage && (value == null || value.trim().isEmpty)) {
            return 'Please enter the mortgage provider / bank name';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Mortgage Provider Bank *',
          hintText: 'e.g. Commercial Bank of Ceylon / HNB / BOC',
          prefixIcon: const Icon(
            Icons.account_balance_outlined,
            color: primaryColor,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalIssuesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasLegalIssues ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        value: _hasLegalIssues,
        onChanged: (val) {
          setState(() {
            _hasLegalIssues = val;
            if (!val) _legalIssueDescriptionController.clear();
          });
        },
        activeThumbColor: Colors.red.shade700,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Pending Legal Disputes or Issues',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Are there any pending boundary, inheritance, or title disputes?',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildLegalIssuesDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: TextFormField(
        controller: _legalIssueDescriptionController,
        maxLines: 2,
        validator: (value) {
          if (_hasLegalIssues && (value == null || value.trim().isEmpty)) {
            return 'Please provide a description of the legal dispute';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Dispute / Issue Description *',
          hintText: 'e.g. Partition case ongoing in district court',
          prefixIcon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: _legalVerified,
        onChanged: (val) {
          setState(() {
            _legalVerified = val;
          });
        },
        activeThumbColor: primaryColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Deed Verified by Legal Counsel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Confirm that title deeds and survey plans have been vetted by a registered attorney.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Clear legal title and honest mortgage disclosures are verified before contracts. Next, upload Title Deeds, Survey Plans, and municipal approvals.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
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
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _saveLegalDetailsAndProceed(exitAfterSave: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor, width: 1.5),
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
                      color: primaryColor,
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
                onPressed: _isSaving ? null : () => _saveLegalDetailsAndProceed(exitAfterSave: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Next: Documents',
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
