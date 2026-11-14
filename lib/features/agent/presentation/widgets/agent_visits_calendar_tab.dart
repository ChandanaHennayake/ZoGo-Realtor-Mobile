import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../buyer/models/property_visit_model.dart';
import '../../../buyer/presentation/screens/buyer_property_details_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../data/services/agent_service.dart';

class AgentVisitsCalendarTab extends StatefulWidget {
  final VoidCallback? onRefreshRequested;

  const AgentVisitsCalendarTab({
    super.key,
    this.onRefreshRequested,
  });

  @override
  State<AgentVisitsCalendarTab> createState() => _AgentVisitsCalendarTabState();
}

class _AgentVisitsCalendarTabState extends State<AgentVisitsCalendarTab> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final AgentService _agentService = AgentService();

  List<PropertyVisitModel> _allVisits = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Status Filter: 0: All, 1: Pending (Requested), 2: Confirmed, 3: Completed (Visited)
  int _selectedStatusFilter = 0;
  String? _processingVisitId;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  @override
  void dispose() {
    _agentService.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final visits = await _agentService.getAgentVisits();
      if (!mounted) return;
      setState(() {
        _allVisits = visits;
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<PropertyVisitModel> get _filteredVisits {
    return _allVisits.where((v) {
      // Date filter matching selected day
      final sameDay = _isSameDay(v.scheduledAt, _selectedDate);
      if (!sameDay) return false;

      // Status filter
      if (_selectedStatusFilter == 1) {
        return v.status == PropertyVisitModel.statusRequested;
      } else if (_selectedStatusFilter == 2) {
        return v.status == PropertyVisitModel.statusConfirmed;
      } else if (_selectedStatusFilter == 3) {
        return v.status == PropertyVisitModel.statusCompleted;
      }
      return true;
    }).toList();
  }

  Map<DateTime, List<PropertyVisitModel>> get _visitsByDateMap {
    final map = <DateTime, List<PropertyVisitModel>>{};
    for (final v in _allVisits) {
      final key = DateTime(v.scheduledAt.year, v.scheduledAt.month, v.scheduledAt.day);
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  Future<void> _handleConfirmVisit(PropertyVisitModel visit) async {
    setState(() => _processingVisitId = visit.visitId);
    try {
      final success = await _agentService.confirmVisit(visit.visitId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit confirmed successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadVisits();
      } else {
        throw Exception('Failed to confirm visit.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingVisitId = null);
    }
  }

  Future<void> _handleRejectVisit(PropertyVisitModel visit) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Reject Visit Request',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decline the visit request for ${visit.propertyTitle}?',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Provide a reason (e.g. Schedule conflict, property unavailable)...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryCyan),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a reason for rejection';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject Visit'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    setState(() => _processingVisitId = visit.visitId);
    try {
      final success = await _agentService.rejectVisit(
        visit.visitId,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit request rejected.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        _loadVisits();
      } else {
        throw Exception('Failed to reject visit.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingVisitId = null);
    }
  }

  Future<void> _handleMarkVisited(PropertyVisitModel visit) async {
    setState(() => _processingVisitId = visit.visitId);
    try {
      // Also complete the visit in DB
      final success = await _agentService.completeVisit(visit.visitId, notes: 'Completed by agent on site');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit marked as Completed / Visited!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadVisits();
      } else {
        // Fallback to property visit endpoint
        final res = await _agentService.markVisited(visit.propertyId, buyerId: visit.buyerId);
        if (!mounted) return;
        if (res) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit marked as Completed / Visited!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadVisits();
        } else {
          throw Exception('Failed to mark visited.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingVisitId = null);
    }
  }

  Future<void> _callUser(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available.'),
          backgroundColor: Colors.orangeAccent,
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
      debugPrint('Could not launch call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar Month Navigator & Grid
        _buildCalendarHeader(),

        // Status filter tabs
        _buildStatusFilterRow(),

        // Day Agenda Header
        Container(
          width: double.infinity,
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 16, color: primaryCyan),
              const SizedBox(width: 8),
              Text(
                'Visits for ${_formatDateHeader(_selectedDate)} (${_filteredVisits.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (!_isSameDay(_selectedDate, DateTime.now()))
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Go to Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryCyan,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Visits list
        Expanded(
          child: RefreshIndicator(
            color: primaryCyan,
            onRefresh: _loadVisits,
            child: _buildAgendaList(),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildCalendarHeader() {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final visitsMap = _visitsByDateMap;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              Text(
                '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                  });
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day of week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayHeader('M'),
              _WeekdayHeader('T'),
              _WeekdayHeader('W'),
              _WeekdayHeader('T'),
              _WeekdayHeader('F'),
              _WeekdayHeader('S'),
              _WeekdayHeader('S'),
            ],
          ),
          const SizedBox(height: 6),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + (firstDayWeekday - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - (firstDayWeekday - 1) + 1;
              final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = _isSameDay(dayDate, _selectedDate);
              final isToday = _isSameDay(dayDate, DateTime.now());

              final dayVisits = visitsMap[DateTime(dayDate.year, dayDate.month, dayDate.day)] ?? [];
              final hasPending = dayVisits.any((v) => v.status == PropertyVisitModel.statusRequested || v.status == PropertyVisitModel.statusConfirmed);
              final hasCompleted = dayVisits.any((v) => v.status == PropertyVisitModel.statusCompleted);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = dayDate;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryCyan
                        : (isToday ? primaryCyan.withValues(alpha: 0.12) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primaryCyan
                          : (isToday ? primaryCyan : Colors.transparent),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? primaryCyan : const Color(0xFF1E293B)),
                        ),
                      ),
                      if (dayVisits.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasPending)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasCompleted)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('All Visits', 0),
            const SizedBox(width: 8),
            _buildStatusChip('Pending (Requested)', 1, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            _buildStatusChip('Confirmed', 2, color: primaryCyan),
            const SizedBox(width: 8),
            _buildStatusChip('Visited (Completed)', 3, color: const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int filterValue, {Color? color}) {
    final isSel = _selectedStatusFilter == filterValue;
    final chipColor = color ?? primaryCyan;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatusFilter = filterValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? chipColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSel ? chipColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryCyan),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVisits,
                style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visits = _filteredVisits;

    if (visits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 32, color: primaryCyan),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No visits scheduled for ${_formatDateHeader(_selectedDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Select another calendar date with visit dots to inspect agenda appointments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: visits.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = visits[index];
        return _buildVisitAgendaCard(item);
      },
    );
  }

  Widget _buildVisitAgendaCard(PropertyVisitModel item) {
    final isProcessing = _processingVisitId == item.visitId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Header: Status badge & TimeSlot
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 14, color: item.color),
                      const SizedBox(width: 4),
                      Text(
                        item.statusName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  item.timeSlot.isNotEmpty ? item.timeSlot : 'Time slot open',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Property Title & District
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.propertyTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.propertyReferenceNo} • ${item.districtName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Buyer Info Row & Direct Call
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (item.buyerName != null && item.buyerName!.isNotEmpty)
                          ? item.buyerName![0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryCyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.buyerName ?? 'Interested Buyer',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (item.buyerPhone != null && item.buyerPhone!.isNotEmpty)
                            ? item.buyerPhone!
                            : 'Phone on request',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Direct Call Buyer
                IconButton.filled(
                  tooltip: 'Call Buyer',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  onPressed: () => _callUser(item.buyerPhone),
                ),
                const SizedBox(width: 8),

                // Chat Buyer
                IconButton.filled(
                  tooltip: 'Chat Buyer',
                  style: IconButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          propertyId: item.propertyId,
                          propertyTitle: item.propertyTitle,
                          recipientId: item.buyerId ?? 'buyer_${item.visitId}',
                          recipientName: item.buyerName ?? 'Buyer',
                          recipientRole: 'buyer',
                          currentUserRole: 'agent',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // View Property
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryCyan),
                    foregroundColor: primaryCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyerPropertyDetailsScreen(
                          propertyId: item.propertyId,
                          buyerUserId: item.buyerId,
                          buyerName: item.buyerName,
                          buyerPhoneNumber: item.buyerPhone,
                        ),
                      ),
                    );
                  },
                  child: const Text('Property', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Action Buttons: Confirm or Mark Visited
          if (item.status == PropertyVisitModel.statusRequested || item.status == PropertyVisitModel.statusConfirmed) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryCyan),
                      ),
                    )
                  : Row(
                      children: [
                        if (item.status == PropertyVisitModel.statusRequested) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleConfirmVisit(item),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleRejectVisit(item),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ] else if (item.status == PropertyVisitModel.statusConfirmed) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleMarkVisited(item),
                              icon: const Icon(Icons.task_alt_rounded, size: 16),
                              label: const Text('Mark Visited'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _handleRejectVisit(item),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              foregroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
