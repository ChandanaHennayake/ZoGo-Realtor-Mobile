import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/agent_service.dart';
import '../../models/agent_property_model.dart';
import '../../../buyer/presentation/screens/buyer_property_details_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class AgentInterestedLeadsScreen extends StatefulWidget {
  final AgentService? agentService;

  const AgentInterestedLeadsScreen({
    super.key,
    this.agentService,
  });

  @override
  State<AgentInterestedLeadsScreen> createState() => _AgentInterestedLeadsScreenState();
}

class _AgentInterestedLeadsScreenState extends State<AgentInterestedLeadsScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color purpleAccent = Color(0xFF6366F1);
  static const Color darkSlate = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF131823);

  late final AgentService _agentService;
  final TextEditingController _searchController = TextEditingController();

  List<AgentPropertyItem> _leads = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  int? _statusFilter; // null = all, 1 = Interested, 2 = Visit Requested, 3 = Visited

  @override
  void initState() {
    super.initState();
    _agentService = widget.agentService ?? AgentService();
    _loadLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _agentService.getInterestedProperties();
      if (!mounted) return;
      setState(() {
        _leads = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<AgentPropertyItem> get _filteredLeads {
    return _leads.where((item) {
      if (_statusFilter != null && item.interactionStatus != _statusFilter) {
        return false;
      }

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();

      final titleMatch = item.title.toLowerCase().contains(q);
      final districtMatch = item.districtName.toLowerCase().contains(q);
      final buyerMatch = item.buyerName.toLowerCase().contains(q);
      final buyerPhoneMatch = item.buyerPhone?.toLowerCase().contains(q) ?? false;
      final sellerMatch = item.sellerName.toLowerCase().contains(q);
      final refMatch = item.referenceNo?.toLowerCase().contains(q) ?? false;

      return titleMatch || districtMatch || buyerMatch || buyerPhoneMatch || sellerMatch || refMatch;
    }).toList();
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return 'LKR ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (amount >= 1000000) {
      final m = amount / 1000000;
      return 'LKR ${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 2)} M';
    } else if (amount >= 100000) {
      final lk = amount / 100000;
      return 'LKR ${lk.toStringAsFixed(lk.truncateToDouble() == lk ? 0 : 2)} Lakhs';
    }
    return 'LKR ${amount.toStringAsFixed(0)}';
  }

  Future<void> _makePhoneCall(String? phone, String recipientName) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number recorded for $recipientName.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openChat({
    required AgentPropertyItem item,
    required String recipientId,
    required String recipientName,
    required String? recipientPhone,
    required String recipientRole,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          propertyId: item.propertyId,
          propertyTitle: item.title,
          recipientId: recipientId,
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          recipientRole: recipientRole,
          currentUserRole: 'agent',
        ),
      ),
    );
  }

  Future<void> _handleRejectInquiry(AgentPropertyItem item) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.close_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Dismiss Inquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject buyer inquiry from ${item.buyerName} for "${item.title}"?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason for Dismissal *',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'e.g. Budget mismatch, buyer unresponsive',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryCyan),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm Dismissal'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _agentService.rejectInquiry(
      item.propertyId,
      buyerId: item.buyerUserId.isNotEmpty ? item.buyerUserId : null,
      reason: reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquiry dismissed.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadLeads();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to dismiss inquiry.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleMarkVisitRequested(AgentPropertyItem lead) async {
    final noteController = TextEditingController(text: 'Advisor requested property site visit');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = 'Morning (09:00 AM - 12:00 PM)';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white12),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: purpleAccent, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Mark Visit Requested',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a visit request for buyer ${lead.buyerName} for "${lead.title}". This will immediately update the buyer\'s portal and territory status.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Visit Date *', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (ctx, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: purpleAccent,
                                onPrimary: Colors.white,
                                surface: cardDark,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: cardDark,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: purpleAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: purpleAccent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          const Text('Change Date', style: TextStyle(color: purpleAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Preferred Time Slot *', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSlot,
                        isExpanded: true,
                        dropdownColor: cardDark,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: const [
                          DropdownMenuItem(
                            value: 'Morning (09:00 AM - 12:00 PM)',
                            child: Text('Morning (09:00 AM - 12:00 PM)'),
                          ),
                          DropdownMenuItem(
                            value: 'Afternoon (01:00 PM - 04:00 PM)',
                            child: Text('Afternoon (01:00 PM - 04:00 PM)'),
                          ),
                          DropdownMenuItem(
                            value: 'Evening (04:00 PM - 06:30 PM)',
                            child: Text('Evening (04:00 PM - 06:30 PM)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSlot = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Advisor Notes', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      hintText: 'Add note for buyer or seller...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Confirm Request', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    final success = await _agentService.markVisitRequested(
      lead.propertyId,
      buyerId: lead.buyerUserId,
      scheduledAt: selectedDate,
      timeSlot: selectedSlot,
      notes: noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit request created for ${lead.buyerName}. Visible in buyer portal!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadLeads();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update visit request status. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleMarkVisited(AgentPropertyItem lead) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Mark Property Visited', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm that buyer ${lead.buyerName} has completed their site visit for "${lead.title}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Visited'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _agentService.markVisited(
      lead.propertyId,
      buyerId: lead.buyerUserId.isNotEmpty ? lead.buyerUserId : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit marked as completed!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadLeads();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark visited.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: darkSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buyer Inquiries & Leads',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${_filteredLeads.length} active inquiries in your territory',
              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: darkSlate,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search buyer, phone, property or district...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All Leads (${_leads.length})', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Interested', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('Visit Requested', 2),
                      const SizedBox(width: 8),
                      _buildFilterChip('Visited', 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leads Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryCyan))
                : _errorMessage != null
                    ? _buildErrorView()
                    : _filteredLeads.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: primaryCyan,
                            onRefresh: _loadLeads,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                              itemCount: _filteredLeads.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildLeadCard(_filteredLeads[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? statusVal) {
    final isSelected = _statusFilter == statusVal;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = statusVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryCyan : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryCyan : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? darkSlate : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadCard(AgentPropertyItem lead) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lead.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: purpleAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: purpleAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        lead.districtName,
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatCurrency(lead.price),
                      style: const TextStyle(
                        color: primaryCyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (lead.referenceNo != null && lead.referenceNo!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        '#${lead.referenceNo}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lead.interactionStatusLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Interested Buyer Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryCyan.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryCyan.withValues(alpha: 0.2),
                        child: Text(
                          lead.buyerName.isNotEmpty ? lead.buyerName[0].toUpperCase() : 'B',
                          style: const TextStyle(color: primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lead.buyerName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('BUYER', style: TextStyle(color: primaryCyan, fontSize: 9, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: lead.buyerPhone != null ? () => _copyToClipboard(lead.buyerPhone!, 'Buyer Phone') : null,
                              child: Text(
                                lead.buyerPhone ?? 'No phone provided',
                                style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Buyer Action Buttons (Call / Chat)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(lead.buyerPhone, lead.buyerName),
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call Buyer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(
                            item: lead,
                            recipientId: lead.buyerUserId,
                            recipientName: lead.buyerName,
                            recipientPhone: lead.buyerPhone,
                            recipientRole: 'buyer',
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                          label: const Text('Chat Buyer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryCyan,
                            foregroundColor: darkSlate,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Advisor Workflow Action: Mark Visit Requested or Mark Visited
                  if (lead.interactionStatus != 3) ...[
                    Row(
                      children: [
                        if (lead.interactionStatus != 2) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleMarkVisitRequested(lead),
                              icon: const Icon(Icons.event_available_rounded, size: 16, color: purpleAccent),
                              label: const Text(
                                'Mark Visit Requested',
                                style: TextStyle(color: purpleAccent, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: purpleAccent.withValues(alpha: 0.6)),
                                backgroundColor: purpleAccent.withValues(alpha: 0.08),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleMarkVisited(lead),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text(
                                'Mark Completed (Visited)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Property Owner / Seller Contact Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: purpleAccent.withValues(alpha: 0.2),
                    child: Text(
                      lead.sellerName.isNotEmpty ? lead.sellerName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller: ${lead.sellerName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lead.sellerPhone ?? 'No phone provided',
                          style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  // Direct Call Seller
                  IconButton(
                    icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFA5B4FC), size: 20),
                    tooltip: 'Call Seller',
                    onPressed: () => _makePhoneCall(lead.sellerPhone, lead.sellerName),
                  ),
                  // Direct Chat Seller
                  IconButton(
                    icon: const Icon(Icons.chat_outlined, color: purpleAccent, size: 20),
                    tooltip: 'Chat Seller',
                    onPressed: () => _openChat(
                      item: lead,
                      recipientId: lead.sellerUserId,
                      recipientName: lead.sellerName,
                      recipientPhone: lead.sellerPhone,
                      recipientRole: 'seller',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar Actions: View Property & Dismiss Inquiry
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerPropertyDetailsScreen(propertyId: lead.propertyId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.white70),
                    label: const Text('View Property', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _handleRejectInquiry(lead),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Dismiss', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_outlined, color: primaryCyan, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Buyer Inquiries Found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No inquiries match "$_searchQuery". Try searching a different term.'
                  : 'Active leads from buyers who expressed interest or requested calls in your territory will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load inquiries',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeads,
              style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: darkSlate),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
