import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zogo_realtor/features/seller/data/services/seller_service.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/create_property/property_legal_details_screen.dart';

class PropertyFinancialsScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyType;

  const PropertyFinancialsScreen({
    super.key,
    required this.propertyId,
    this.propertyType,
  });

  @override
  State<PropertyFinancialsScreen> createState() =>
      _PropertyFinancialsScreenState();
}

class _PropertyFinancialsScreenState extends State<PropertyFinancialsScreen> {
  static const Color primaryColor = Color(0xFF00C6D4);

  final _formKey = GlobalKey<FormState>();
  final SellerService _sellerService = SellerService();

  final TextEditingController _maintenanceFeeController =
      TextEditingController();
  final TextEditingController _sinkingFundAmountController =
      TextEditingController();
  final TextEditingController _outstandingAmountController =
      TextEditingController();
  final TextEditingController _outstandingDescriptionController =
      TextEditingController();

  int _maintenanceFeePeriod = 1; // 1: Monthly, 2: Quarterly, 3: Half-Yearly, 4: Annually
  int _sinkingFundPeriod = 1;

  bool _billsUpToDate = true;
  bool _hasOutstandingCharges = false;

  bool _isLoading = true;
  bool _isSaving = false;

  static const Map<int, String> _periodOptions = {
    1: 'Monthly',
    2: 'Quarterly',
    3: 'Half-Yearly',
    4: 'Annually',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingFinancials();
  }

  @override
  void dispose() {
    _maintenanceFeeController.dispose();
    _sinkingFundAmountController.dispose();
    _outstandingAmountController.dispose();
    _outstandingDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFinancials() async {
    try {
      final data =
          await _sellerService.getPropertyFinancials(widget.propertyId);
      if (data != null && mounted) {
        setState(() {
          if (data['maintenanceFee'] != null) {
            _maintenanceFeeController.text =
                data['maintenanceFee'].toString();
          }
          if (data['maintenanceFeePeriod'] != null) {
            _maintenanceFeePeriod =
                (data['maintenanceFeePeriod'] as num).toInt();
          }
          if (data['sinkingFundAmount'] != null) {
            _sinkingFundAmountController.text =
                data['sinkingFundAmount'].toString();
          }
          if (data['sinkingFundPeriod'] != null) {
            _sinkingFundPeriod =
                (data['sinkingFundPeriod'] as num).toInt();
          }
          if (data['billsUpToDate'] != null) {
            _billsUpToDate = data['billsUpToDate'] == true;
          }
          if (data['hasOutstandingCharges'] != null) {
            _hasOutstandingCharges =
                data['hasOutstandingCharges'] == true;
          }
          if (data['outstandingAmount'] != null) {
            _outstandingAmountController.text =
                data['outstandingAmount'].toString();
          }
          if (data['outstandingDescription'] != null) {
            _outstandingDescriptionController.text =
                data['outstandingDescription'].toString();
          }
        });
      }
    } catch (_) {
      // Non-blocking if financials do not exist yet
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveFinancials({bool exitAfterSave = false}) async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final maintenanceFee = _maintenanceFeeController.text.trim().isNotEmpty
          ? double.tryParse(_maintenanceFeeController.text.trim())
          : null;
      final sinkingFundAmount =
          _sinkingFundAmountController.text.trim().isNotEmpty
              ? double.tryParse(_sinkingFundAmountController.text.trim())
              : null;
      final outstandingAmount = _hasOutstandingCharges &&
              _outstandingAmountController.text.trim().isNotEmpty
          ? double.tryParse(_outstandingAmountController.text.trim())
          : null;

      final payload = <String, dynamic>{
        'maintenanceFee': maintenanceFee,
        'maintenanceFeePeriod':
            maintenanceFee != null ? _maintenanceFeePeriod : null,
        'sinkingFundAmount': sinkingFundAmount,
        'sinkingFundPeriod':
            sinkingFundAmount != null ? _sinkingFundPeriod : null,
        'billsUpToDate': _billsUpToDate,
        'hasOutstandingCharges': _hasOutstandingCharges,
        'outstandingAmount':
            _hasOutstandingCharges ? outstandingAmount : null,
        'outstandingDescription': _hasOutstandingCharges &&
                _outstandingDescriptionController.text.trim().isNotEmpty
            ? _outstandingDescriptionController.text.trim()
            : null,
      };

      await _sellerService.savePropertyFinancials(
        widget.propertyId,
        payload,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property financials saved successfully!'),
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

      // Navigate to Step 5: Legal Details
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyLegalDetailsScreen(
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
          content: Text('Failed to save financials: $e'),
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
          'Property Financials',
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
                              'Financial & Ongoing Dues',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Specify recurring maintenance fees, sinking fund contributions, and outstanding utility bills.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildPropertyTypeCard(typeName),
                            const SizedBox(height: 24),

                            // Maintenance Fee Section
                            _buildSectionHeader(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Maintenance Fee',
                              subtitle:
                                  'Recurring fee for common area upkeep and cleaning',
                            ),
                            const SizedBox(height: 12),
                            _buildAmountWithPeriodField(
                              controller: _maintenanceFeeController,
                              label: 'Maintenance Fee (LKR)',
                              hint: 'e.g. 15000 (optional)',
                              selectedPeriod: _maintenanceFeePeriod,
                              onPeriodChanged: (val) {
                                setState(() {
                                  _maintenanceFeePeriod = val;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Sinking Fund Section
                            _buildSectionHeader(
                              icon: Icons.savings_outlined,
                              title: 'Sinking Fund',
                              subtitle:
                                  'Reserve fund for major future repairs and capital improvements',
                            ),
                            const SizedBox(height: 12),
                            _buildAmountWithPeriodField(
                              controller: _sinkingFundAmountController,
                              label: 'Sinking Fund (LKR)',
                              hint: 'e.g. 5000 (optional)',
                              selectedPeriod: _sinkingFundPeriod,
                              onPeriodChanged: (val) {
                                setState(() {
                                  _sinkingFundPeriod = val;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Bills Up-to-Date Switch
                            _buildSectionHeader(
                              icon: Icons.receipt_long_outlined,
                              title: 'Utility & Municipal Dues',
                              subtitle:
                                  'Confirmation regarding utility status',
                            ),
                            const SizedBox(height: 12),
                            _buildBillsSwitchCard(),
                            const SizedBox(height: 20),

                            // Outstanding Charges Section
                            _buildOutstandingSwitchCard(),
                            if (_hasOutstandingCharges) ...[
                              const SizedBox(height: 14),
                              _buildOutstandingForm(),
                            ],

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
          _buildStepItem(number: '4', title: 'Financials', isCompleted: false, isActive: true),
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
              Icons.account_balance_wallet_outlined,
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

  Widget _buildAmountWithPeriodField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int selectedPeriod,
    required ValueChanged<int> onPeriodChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: primaryColor,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Billing Frequency',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: _periodOptions.entries.map((entry) {
              final isSelected = entry.key == selectedPeriod;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onPeriodChanged(entry.key),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? primaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsSwitchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: _billsUpToDate,
        onChanged: (val) {
          setState(() {
            _billsUpToDate = val;
          });
        },
        activeThumbColor: primaryColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Utility Bills Up-to-Date',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Electricity, water, and municipal assessment taxes are fully settled.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildOutstandingSwitchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasOutstandingCharges
              ? Colors.orange.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        value: _hasOutstandingCharges,
        onChanged: (val) {
          setState(() {
            _hasOutstandingCharges = val;
            if (!val) {
              _outstandingAmountController.clear();
              _outstandingDescriptionController.clear();
            }
          });
        },
        activeThumbColor: Colors.orange.shade700,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Has Outstanding Charges',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Turn on if there are any pending maintenance or legal arrears.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildOutstandingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Outstanding Dues Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _outstandingAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (_hasOutstandingCharges &&
                  (value == null || value.trim().isEmpty)) {
                return 'Please enter the outstanding amount';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Outstanding Amount (LKR) *',
              hintText: 'e.g. 45000',
              prefixIcon: Icon(
                Icons.money_off_outlined,
                color: Colors.orange.shade700,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orange.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _outstandingDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description / Notes',
              hintText: 'e.g. Unpaid condo maintenance for August & September',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orange.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5),
              ),
            ),
          ),
        ],
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
              'Accurate financial disclosure ensures transparency, increases trust with prospective buyers, and accelerates deal closing.',
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
                onPressed: _isSaving ? null : () => _saveFinancials(exitAfterSave: true),
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
                onPressed: _isSaving ? null : () => _saveFinancials(exitAfterSave: false),
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
                              'Next: Legal Details',
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
