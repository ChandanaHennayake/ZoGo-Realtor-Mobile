import 'package:flutter/material.dart';
import '../../data/services/buyer_property_interaction_service.dart';
import '../../models/buyer_property_interaction.dart';

class BuyerInteractionSection extends StatefulWidget {
  final String propertyId;
  final BuyerPropertyInteractionService? interactionService;
  final ValueChanged<BuyerPropertyInteraction?>? onInteractionChanged;

  const BuyerInteractionSection({
    super.key,
    required this.propertyId,
    this.interactionService,
    this.onInteractionChanged,
  });

  @override
  State<BuyerInteractionSection> createState() =>
      _BuyerInteractionSectionState();
}

class _BuyerInteractionSectionState extends State<BuyerInteractionSection> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  late final BuyerPropertyInteractionService _service;
  bool _isLoading = true;
  bool _isUpdating = false;
  BuyerPropertyInteraction? _currentInteraction;

  @override
  void initState() {
    super.initState();
    _service = widget.interactionService ?? BuyerPropertyInteractionService();
    _loadCurrentInteraction();
  }

  Future<void> _loadCurrentInteraction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interaction = await _service.getInteraction(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _currentInteraction = interaction;
        _isLoading = false;
      });
      widget.onInteractionChanged?.call(interaction);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateInteraction(int status, String actionLabel) async {
    if (_isUpdating) return;

    final prev = _currentInteraction;
    final optimistic = BuyerPropertyInteraction(
      propertyId: widget.propertyId,
      currentStatus: status,
      currentStatusName: BuyerPropertyInteraction.resolveStatusName(status),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isUpdating = true;
      _currentInteraction = optimistic;
    });

    try {
      final updated = await _service.setInteraction(widget.propertyId, status);
      if (!mounted) return;
      setState(() {
        _currentInteraction = updated;
        _isUpdating = false;
      });
      widget.onInteractionChanged?.call(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$actionLabel: ${updated.currentStatusName}'),
            ],
          ),
          backgroundColor: updated.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentInteraction = prev;
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stage: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentInteraction?.currentStatus ?? 0;
    final statusName = _currentInteraction?.currentStatusName ?? 'Not Started';
    final stageColor = _currentInteraction?.color ?? primaryCyan;
    final stageIcon = _currentInteraction?.icon ?? Icons.timeline_rounded;

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
          // Section Title & Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
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
                      'Buyer Interaction Stage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your transaction timeline with this property',
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
            // Current Status Highlight Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stageColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stageIcon, color: stageColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Stage',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryGray,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: stageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Visual Progress Flow (Timeline Stepper)
            const Text(
              'Workflow Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildWorkflowSteps(status),

            const SizedBox(height: 18),

            // Available Buyer Actions
            const Text(
              'Available Actions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  label: 'Request Visit',
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF3B82F6),
                  targetStatus: BuyerPropertyInteraction.statusVisitRequested,
                  currentStatus: status,
                  actionName: 'Visit requested',
                ),
                _buildActionButton(
                  label: 'Request Documents',
                  icon: Icons.description_outlined,
                  color: const Color(0xFF8B5CF6),
                  targetStatus: BuyerPropertyInteraction.statusDocumentsRequested,
                  currentStatus: status,
                  actionName: 'Documents requested',
                ),
                _buildActionButton(
                  label: 'Submit Offer',
                  icon: Icons.local_offer_outlined,
                  color: const Color(0xFFEC4899),
                  targetStatus: BuyerPropertyInteraction.statusOfferSubmitted,
                  currentStatus: status,
                  actionName: 'Offer submitted',
                ),
                _buildActionButton(
                  label: 'Not Interested',
                  icon: Icons.close_rounded,
                  color: const Color(0xFF6B7280),
                  targetStatus: BuyerPropertyInteraction.statusNotInterested,
                  currentStatus: status,
                  actionName: 'Status updated to not interested',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowSteps(int currentStatus) {
    // 6 Primary Milestones
    final milestones = [
      (code: 1, label: 'Interested'),
      (code: 2, label: 'Visit Req.'),
      (code: 3, label: 'Visited'),
      (code: 4, label: 'Docs Req.'),
      (code: 5, label: 'Negotiate'),
      (code: 6, label: 'Offer Sent'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(milestones.length, (idx) {
          final m = milestones[idx];
          final isCompleted = currentStatus >= m.code && currentStatus != 9;
          final isCurrent = currentStatus == m.code;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? primaryCyan
                          : isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted && !isCurrent
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isCurrent
                          ? primaryCyan
                          : isCompleted
                              ? const Color(0xFF10B981)
                              : secondaryGray,
                    ),
                  ),
                ],
              ),
              if (idx < milestones.length - 1)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
                  color: currentStatus > m.code && currentStatus != 9
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required int targetStatus,
    required int currentStatus,
    required String actionName,
  }) {
    final isCurrent = currentStatus == targetStatus;

    return OutlinedButton.icon(
      onPressed: _isUpdating || isCurrent
          ? null
          : () => _handleUpdateInteraction(targetStatus, actionName),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: isCurrent ? color : color.withValues(alpha: 0.4),
          width: isCurrent ? 2 : 1,
        ),
        backgroundColor: isCurrent ? color.withValues(alpha: 0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
