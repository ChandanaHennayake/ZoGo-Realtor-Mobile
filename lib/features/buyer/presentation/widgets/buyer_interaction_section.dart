import 'package:flutter/material.dart';
import '../../data/services/buyer_offer_service.dart';
import '../../data/services/buyer_property_interaction_service.dart';
import '../../data/services/buyer_visit_service.dart';
import '../../models/buyer_property_interaction.dart';
import '../../models/property_visit_model.dart';
import '../../../../core/workflow/workflow_button_policy.dart';
import 'visit_request_contact_sheet.dart';

class BuyerInteractionSection extends StatefulWidget {
  final String propertyId;
  final String? propertyTitle;
  final int? districtId;
  final String? districtName;
  final String? agentName;
  final String? agentPhoneNumber;
  final String? agentUserId;
  final BuyerPropertyInteractionService? interactionService;
  final BuyerVisitService? visitService;
  final BuyerOfferService? offerService;
  final ValueChanged<BuyerPropertyInteraction?>? onInteractionChanged;

  const BuyerInteractionSection({
    super.key,
    required this.propertyId,
    this.propertyTitle,
    this.districtId,
    this.districtName,
    this.agentName,
    this.agentPhoneNumber,
    this.agentUserId,
    this.interactionService,
    this.visitService,
    this.offerService,
    this.onInteractionChanged,
  });

  @override
  State<BuyerInteractionSection> createState() =>
      BuyerInteractionSectionState();
}

class BuyerInteractionSectionState extends State<BuyerInteractionSection> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  late final BuyerPropertyInteractionService _service;
  late final BuyerVisitService _visitService;
  late final BuyerOfferService _offerService;
  bool _isLoading = true;
  bool _isUpdating = false;
  BuyerPropertyInteraction? _currentInteraction;
  PropertyVisitModel? _activeVisit;

  @override
  void initState() {
    super.initState();
    _service = widget.interactionService ?? BuyerPropertyInteractionService();
    _visitService = widget.visitService ?? BuyerVisitService();
    _offerService = widget.offerService ?? BuyerOfferService();
    _loadCurrentInteraction();
  }

  Future<void> reload() async {
    await _loadCurrentInteraction();
  }

  Future<void> _loadCurrentInteraction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interaction = await _service.getInteraction(widget.propertyId);
      PropertyVisitModel? visit;
      try {
        final visits = await _visitService.getMyVisits();
        final match = visits.where((v) => v.propertyId.toLowerCase() == widget.propertyId.toLowerCase()).toList();
        if (match.isNotEmpty) {
          visit = match.first;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _currentInteraction = interaction;
        _activeVisit = visit;
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

  Future<void> _handleRequestDocuments() async {
    if (_isUpdating) return;

    final prev = _currentInteraction;
    final optimistic = BuyerPropertyInteraction(
      propertyId: widget.propertyId,
      currentStatus: BuyerPropertyInteraction.statusDocumentsRequested,
      currentStatusName: 'Documents Requested',
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isUpdating = true;
      _currentInteraction = optimistic;
    });

    try {
      final updated = await _service.requestDocuments(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _currentInteraction = updated;
        _isUpdating = false;
      });
      widget.onInteractionChanged?.call(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Documents requested successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF8B5CF6),
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
          content: Text('$e'),
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

            if (_activeVisit != null && (status == BuyerPropertyInteraction.statusVisitRequested || status == BuyerPropertyInteraction.statusVisited)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6D4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C6D4).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C6D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: Color(0xFF00C6D4), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visit Scheduled by Realtor',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Date: ${_activeVisit!.scheduledAt.year}-${_activeVisit!.scheduledAt.month.toString().padLeft(2, '0')}-${_activeVisit!.scheduledAt.day.toString().padLeft(2, '0')}  |  ${_activeVisit!.timeSlot}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF0097A7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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

            Builder(builder: (context) {
              final isClosed = WorkflowButtonPolicy.isClosed(status);
              final visitAction = WorkflowButtonPolicy.getBuyerVisitAction(
                interactionStatus: status,
                isUpdating: _isUpdating,
              );
              final docAction = WorkflowButtonPolicy.getBuyerDocumentAction(
                interactionStatus: status,
                isUpdating: _isUpdating,
              );
              final offerAction = WorkflowButtonPolicy.getBuyerOfferAction(
                interactionStatus: status,
                isUpdating: _isUpdating,
              );

              if (isClosed) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == BuyerPropertyInteraction.statusSold
                            ? Icons.verified_rounded
                            : status == BuyerPropertyInteraction.statusRejected
                                ? Icons.cancel_rounded
                                : Icons.info_outline_rounded,
                        color: stageColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == BuyerPropertyInteraction.statusSold
                                  ? 'Sale Completed'
                                  : status == BuyerPropertyInteraction.statusRejected
                                      ? 'Inquiry Rejected'
                                      : 'Inquiry Cancelled',
                              style: TextStyle(
                                color: stageColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status == BuyerPropertyInteraction.statusSold
                                  ? 'This property inquiry has concluded successfully with a sale.'
                                  : status == BuyerPropertyInteraction.statusRejected
                                      ? 'This inquiry has been declined by the agent or seller.'
                                      : 'This inquiry was cancelled and is no longer active.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (visitAction.isVisible)
                        _buildActionButton(
                          label: visitAction.label,
                          icon: visitAction.icon ?? Icons.calendar_month_outlined,
                          color: visitAction.color,
                          isEnabled: visitAction.isEnabled,
                          disabledReason: visitAction.disabledReason,
                          isCurrent: status == BuyerPropertyInteraction.statusVisitRequested,
                          onTap: _handleRequestVisit,
                        ),
                      if (docAction.isVisible)
                        _buildActionButton(
                          label: docAction.label,
                          icon: docAction.icon ?? Icons.description_outlined,
                          color: docAction.color,
                          isEnabled: docAction.isEnabled,
                          disabledReason: docAction.disabledReason,
                          isCurrent: status == BuyerPropertyInteraction.statusDocumentsRequested,
                          onTap: _handleRequestDocuments,
                        ),
                      if (offerAction.isVisible)
                        _buildActionButton(
                          label: offerAction.label,
                          icon: offerAction.icon ?? Icons.local_offer_outlined,
                          color: offerAction.color,
                          isEnabled: offerAction.isEnabled,
                          disabledReason: offerAction.disabledReason,
                          isCurrent: status == BuyerPropertyInteraction.statusOfferSubmitted,
                          onTap: _handleSubmitOffer,
                        ),
                      _buildActionButton(
                        label: 'Not Interested',
                        icon: Icons.close_rounded,
                        color: const Color(0xFF6B7280),
                        isEnabled: !_isUpdating && status != BuyerPropertyInteraction.statusNotInterested,
                        onTap: () => _handleUpdateInteraction(
                          BuyerPropertyInteraction.statusNotInterested,
                          'Marked as not interested',
                        ),
                      ),
                    ],
                  ),
                  if (!docAction.isEnabled && docAction.disabledReason != null && status < BuyerPropertyInteraction.statusVisited) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            docAction.disabledReason!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _handleRequestVisit() async {
    await VisitRequestContactSheet.show(
      context: context,
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle ?? 'Property Visit',
      agentName: widget.agentName,
      agentPhoneNumber: widget.agentPhoneNumber,
      agentUserId: widget.agentUserId,
      districtId: widget.districtId,
      districtName: widget.districtName,
      onScheduleAlternative: null,
      onInteractionUpdated: (updated) {
        if (!mounted) return;
        if (updated != null) {
          setState(() {
            _currentInteraction = updated;
          });
          widget.onInteractionChanged?.call(updated);
        }
      },
    );
  }

  Future<void> _handleSubmitOffer() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 7));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: Color(0xFFEC4899), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Submit Formal Offer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Offer Amount (LKR)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 45000000',
                  prefixText: 'LKR ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: darkText),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Offer Validity Expiry',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: expiryDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      expiryDate = picked;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFEC4899), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Valid until: ${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      const Text('Change', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proposal Terms or Contingencies (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Subject to title clearance, 10% advance upon deed signing...',
                  hintStyle: const TextStyle(fontSize: 12, color: secondaryGray),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final raw = amountController.text.replaceAll(',', '').trim();
                    final parsed = double.tryParse(raw);
                    if (parsed == null || parsed <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid offer amount.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Submit Offer to Seller', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text.replaceAll(',', '').trim()) ?? 0;
      setState(() {
        _isUpdating = true;
      });

      try {
        await _offerService.submitOffer(
          propertyId: widget.propertyId,
          offerAmount: amount,
          buyerNotes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          expiresAt: expiryDate,
        );

        await _handleUpdateInteraction(
          BuyerPropertyInteraction.statusOfferSubmitted,
          'Offer submitted',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Offer of LKR ${amount.toStringAsFixed(0)} submitted successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit offer: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }
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
    required bool isEnabled,
    String? disabledReason,
    VoidCallback? onTap,
    bool isCurrent = false,
  }) {
    final button = OutlinedButton.icon(
      onPressed: isEnabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: const Color(0xFF94A3B8),
        side: BorderSide(
          color: isCurrent
              ? color
              : isEnabled
                  ? color.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
          width: isCurrent ? 2 : 1,
        ),
        backgroundColor: isCurrent
            ? color.withValues(alpha: 0.1)
            : !isEnabled
                ? const Color(0xFFF8FAFC)
                : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16, color: isEnabled ? color : const Color(0xFF94A3B8)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          color: isEnabled ? color : const Color(0xFF94A3B8),
        ),
      ),
    );

    if (disabledReason != null && !isEnabled) {
      return Tooltip(
        message: disabledReason,
        child: button,
      );
    }

    return button;
  }
}
