import 'package:flutter/material.dart';
import '../../data/services/buyer_property_interest_service.dart';
import '../../models/property_interest.dart';

class PropertyInterestSection extends StatefulWidget {
  final String propertyId;
  final BuyerPropertyInterestService? interestService;
  final ValueChanged<PropertyInterest?>? onInterestChanged;

  const PropertyInterestSection({
    super.key,
    required this.propertyId,
    this.interestService,
    this.onInterestChanged,
  });

  @override
  State<PropertyInterestSection> createState() =>
      _PropertyInterestSectionState();
}

class _PropertyInterestSectionState extends State<PropertyInterestSection> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  late final BuyerPropertyInterestService _service;
  bool _isLoading = true;
  bool _isUpdating = false;
  PropertyInterest? _currentInterest;

  @override
  void initState() {
    super.initState();
    _service = widget.interestService ?? BuyerPropertyInterestService();
    _loadCurrentInterest();
  }

  Future<void> _loadCurrentInterest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interest = await _service.getInterest(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _currentInterest = interest;
        _isLoading = false;
      });
      widget.onInterestChanged?.call(interest);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSelectStatus(int status) async {
    if (_isUpdating) return;

    final prevInterest = _currentInterest;

    // Optimistic state
    final optimistic = PropertyInterest(
      propertyId: widget.propertyId,
      status: status,
      statusName: PropertyInterest.resolveStatusName(status),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isUpdating = true;
      _currentInterest = optimistic;
    });

    try {
      final updated = await _service.setInterest(widget.propertyId, status);
      if (!mounted) return;
      setState(() {
        _currentInterest = updated;
        _isUpdating = false;
      });
      widget.onInterestChanged?.call(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Interest marked as: ${updated.statusName}'),
            ],
          ),
          backgroundColor: updated.color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Revert on error
      setState(() {
        _currentInterest = prevInterest;
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update interest: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = _currentInterest?.status;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 20,
                  color: primaryCyan,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Interest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Let the seller know how you feel about this property',
                      style: TextStyle(fontSize: 12, color: secondaryGray),
                    ),
                  ],
                ),
              ),
              if (_isUpdating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryCyan,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryCyan,
                ),
              ),
            )
          else ...[
            // Interest Options
            Row(
              children: [
                _buildInterestButton(
                  title: 'Interested',
                  icon: Icons.thumb_up_rounded,
                  status: PropertyInterest.statusInterested,
                  activeColor: const Color(0xFF10B981),
                  isSelected: selectedStatus == PropertyInterest.statusInterested,
                ),
                const SizedBox(width: 8),
                _buildInterestButton(
                  title: 'Considering',
                  icon: Icons.hourglass_top_rounded,
                  status: PropertyInterest.statusConsidering,
                  activeColor: const Color(0xFFF59E0B),
                  isSelected: selectedStatus == PropertyInterest.statusConsidering,
                ),
                const SizedBox(width: 8),
                _buildInterestButton(
                  title: 'Not Interested',
                  icon: Icons.thumb_down_rounded,
                  status: PropertyInterest.statusNotInterested,
                  activeColor: const Color(0xFF6B7280),
                  isSelected: selectedStatus == PropertyInterest.statusNotInterested,
                ),
              ],
            ),

            if (_currentInterest != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentInterest!.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _currentInterest!.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: _currentInterest!.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your status is currently set to "${_currentInterest!.statusName}".',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentInterest!.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInterestButton({
    required String title,
    required IconData icon,
    required int status,
    required Color activeColor,
    required bool isSelected,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isUpdating ? null : () => _handleSelectStatus(status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeColor : Colors.grey.shade300,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : const Color(0xFF6B7280),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? activeColor : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
