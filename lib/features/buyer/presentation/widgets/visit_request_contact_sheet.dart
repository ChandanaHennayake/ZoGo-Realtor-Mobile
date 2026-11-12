import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/buyer_property_interaction_service.dart';
import '../../data/services/buyer_property_service.dart';
import '../../models/buyer_property_interaction.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class VisitRequestContactSheet extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String? agentName;
  final String? agentPhoneNumber;
  final String? agentUserId;
  final int? districtId;
  final String? districtName;
  final VoidCallback? onScheduleAlternative;
  final ValueChanged<BuyerPropertyInteraction?>? onInteractionUpdated;

  const VisitRequestContactSheet({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    this.agentName,
    this.agentPhoneNumber,
    this.agentUserId,
    this.districtId,
    this.districtName,
    this.onScheduleAlternative,
    this.onInteractionUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required String propertyId,
    required String propertyTitle,
    String? agentName,
    String? agentPhoneNumber,
    String? agentUserId,
    int? districtId,
    String? districtName,
    VoidCallback? onScheduleAlternative,
    ValueChanged<BuyerPropertyInteraction?>? onInteractionUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VisitRequestContactSheet(
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        agentName: agentName,
        agentPhoneNumber: agentPhoneNumber,
        agentUserId: agentUserId,
        districtId: districtId,
        districtName: districtName,
        onScheduleAlternative: onScheduleAlternative,
        onInteractionUpdated: onInteractionUpdated,
      ),
    );
  }

  @override
  State<VisitRequestContactSheet> createState() => _VisitRequestContactSheetState();
}

class _VisitRequestContactSheetState extends State<VisitRequestContactSheet> {
  static const Color slateDark = Color(0xFF0A0D14);
  static const Color slateCard = Color(0xFF161B26);
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color accentPurple = Color(0xFF6366F1);

  String? _agentName;
  String? _agentPhoneNumber;
  String? _agentUserId;
  bool _isLoadingAgent = false;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _agentName = widget.agentName;
    _agentPhoneNumber = widget.agentPhoneNumber;
    _agentUserId = widget.agentUserId;

    if (_agentPhoneNumber == null || _agentPhoneNumber!.isEmpty) {
      _loadAgentFromAccount();
    }
  }

  Future<void> _loadAgentFromAccount() async {
    setState(() {
      _isLoadingAgent = true;
    });

    try {
      final agentData = await BuyerPropertyService().getPropertyAgent(widget.propertyId);
      if (!mounted) return;
      if (agentData != null) {
        setState(() {
          _agentName = agentData['name']?.toString() ?? _agentName;
          _agentPhoneNumber = agentData['phoneNumber']?.toString() ?? _agentPhoneNumber;
          _agentUserId = agentData['userId']?.toString() ?? _agentUserId;
          _isLoadingAgent = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingAgent = false;
      });
    }
  }

  Future<void> _recordVisitRequested() async {
    try {
      final updated = await BuyerPropertyInteractionService().setInteraction(
        widget.propertyId,
        BuyerPropertyInteraction.statusVisitRequested,
      );
      widget.onInteractionUpdated?.call(updated);
    } catch (_) {}
  }

  Future<void> _handleCallAgent() async {
    final phone = _agentPhoneNumber ?? '0770000002';
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');

    setState(() {
      _isActionInProgress = true;
    });

    await _recordVisitRequested();

    if (!mounted) return;
    Navigator.of(context).pop();

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Connecting call to $_displayName ($phone)... Visit request noted.'),
              ),
            ],
          ),
          backgroundColor: primaryCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleChatAgent() async {
    setState(() {
      _isActionInProgress = true;
    });

    await _recordVisitRequested();

    if (!mounted) return;
    Navigator.of(context).pop();

    final recipientId = _agentUserId ?? 'agent_${widget.districtId ?? 1}';
    final recipientName = _displayName;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          propertyId: widget.propertyId,
          propertyTitle: widget.propertyTitle,
          recipientId: recipientId,
          recipientName: recipientName,
          recipientRole: 'agent',
          currentUserRole: 'buyer',
        ),
      ),
    );
  }

  String get _displayName {
    if (_agentName != null && _agentName!.trim().isNotEmpty) {
      return _agentName!.trim();
    }
    if (widget.districtName != null && widget.districtName!.trim().isNotEmpty) {
      return 'Assigned Realtor (${widget.districtName})';
    }
    return 'Assigned Property Realtor';
  }

  String get _displayPhone {
    if (_agentPhoneNumber != null && _agentPhoneNumber!.trim().isNotEmpty) {
      return _agentPhoneNumber!.trim();
    }
    return '077 000 0002';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: slateDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 
            (MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom + 14 
                : 28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryCyan.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.support_agent_rounded, color: primaryCyan, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Property Visit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose how you want to connect with the assigned agent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingAgent || _isActionInProgress)
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

          const SizedBox(height: 20),

          // Agent Profile Account Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: slateCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: primaryCyan.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.person_rounded,
                        color: primaryCyan,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: slateCard, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: accentPurple.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'VERIFIED AGENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFA5B4FC),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: primaryCyan),
                          const SizedBox(width: 5),
                          Text(
                            _displayPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE2E8F0),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      if (widget.districtName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'District: ${widget.districtName}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Select Option to Arrange Visit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Option 1: CALL AGENT (Primary)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isActionInProgress ? null : _handleCallAgent,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00C6D4),
                      Color(0xFF0097A7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Call Agent Mobile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dial $_displayPhone to schedule visit directly',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Option 2: CHAT WITH AGENT
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isActionInProgress ? null : _handleChatAgent,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: slateCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentPurple.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentPurple.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFFA5B4FC),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat with Agent',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Instant in-app messaging to discuss visit times',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.onScheduleAlternative != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onScheduleAlternative?.call();
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF94A3B8)),
                label: const Text(
                  'Or pick a date & time slot online',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
