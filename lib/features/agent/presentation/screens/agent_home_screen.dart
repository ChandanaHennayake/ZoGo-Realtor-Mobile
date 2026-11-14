import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../buyer/data/services/user_notification_service.dart';
import '../../../buyer/presentation/screens/buyer_property_details_screen.dart';
import '../../../buyer/presentation/widgets/notifications_sheet.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../data/services/agent_service.dart';
import '../../models/agent_dashboard_model.dart';
import '../../models/agent_property_model.dart';
import '../widgets/agent_property_card.dart';
import '../widgets/agent_stat_card.dart';
import '../widgets/agent_territory_tab.dart';
import '../widgets/agent_visits_calendar_tab.dart';
import '../../../home/presentation/widgets/user_profile_sheet.dart';

class AgentHomeScreen extends StatefulWidget {
  final List<String> roles;

  const AgentHomeScreen({
    super.key,
    required this.roles,
  });

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  int _selectedIndex = 0;

  final AgentService _agentService = AgentService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final UserNotificationService _notificationService = UserNotificationService();

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkCyan = Color(0xFF008D97);

  AgentDashboardModel _dashboard = AgentDashboardModel.empty();
  List<AgentPropertyItem> _pendingDocuments = [];

  bool _isLoadingDashboard = true;
  bool _isLoadingDocs = true;
  int _unreadNotifications = 0;

  Map<String, String> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _refreshAll();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _secureStorage.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadDashboard(),
      _loadDocuments(),
      _loadUnreadNotifications(),
    ]);
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoadingDashboard = true);
    final data = await _agentService.getDashboard();
    if (mounted) {
      setState(() {
        _dashboard = data;
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    final data = await _agentService.getPendingDocuments();
    if (mounted) {
      setState(() {
        _pendingDocuments = data;
        _isLoadingDocs = false;
      });
    }
  }

  Future<void> _handleMarkSold(AgentPropertyItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Mark as Sold'),
          ],
        ),
        content: Text(
          'Mark "${item.title}" as SOLD for buyer ${item.buyerName}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _agentService.markSold(
      item.propertyId,
      buyerId: item.buyerUserId.isNotEmpty ? item.buyerUserId : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Property successfully marked as SOLD!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _refreshAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update property status to Sold.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handleRejectInquiry(AgentPropertyItem item) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Reject Inquiry'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject buyer ${item.buyerName}\'s inquiry for "${item.title}"?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'Enter specific rejection justification',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject Inquiry'),
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

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inquiry rejected and closed.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _refreshAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to reject inquiry.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyDocuments(AgentPropertyItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: primaryCyan),
            SizedBox(width: 8),
            Text('Verify Documents'),
          ],
        ),
        content: Text('Mark documents as verified and completed for "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify & Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Navigate to details to view and verify documents or complete
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BuyerPropertyDetailsScreen(propertyId: item.propertyId)),
      ).then((_) => _refreshAll());
    }
  }

  Future<void> _handleRejectDocuments(AgentPropertyItem item) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.thumb_down_alt_outlined, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Reject Documents'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter correction/rejection requirements for the seller/buyer:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject Documents'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _agentService.rejectInquiry(
      item.propertyId,
      buyerId: item.buyerUserId.isNotEmpty ? item.buyerUserId : null,
      reason: 'Documents rejected: ${reasonController.text.trim()}',
    );

    if (mounted && success) {
      _refreshAll();
    }
  }

  Future<void> _handleCallBuyer(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this buyer.'),
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

  void _openChatWithBuyer(AgentPropertyItem item) {
    if (item.buyerUserId.isEmpty && item.buyerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No buyer details available for this property.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          propertyId: item.propertyId,
          propertyTitle: item.title,
          recipientId: item.buyerUserId,
          recipientName: item.buyerName,
          recipientPhone: item.buyerPhone,
          recipientRole: 'buyer',
          currentUserRole: 'agent',
        ),
      ),
    );
  }

  Widget _buildTopProfileAvatar({bool isLight = false}) {
    final initial = (_userProfile['firstName']?.isNotEmpty == true)
        ? _userProfile['firstName']![0].toUpperCase()
        : 'A';
    return GestureDetector(
      onTap: () => UserProfileSheet.show(context, roles: widget.roles),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [primaryCyan, Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isLight ? Colors.white70 : primaryCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          _buildTerritoryTab(),
          _buildVisitsTab(),
          _buildDocumentsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // TAB 0: DASHBOARD
  // ============================================================
  Widget _buildDashboardTab() {
    final topPadding = MediaQuery.of(context).padding.top;
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: primaryCyan,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryCyan, darkCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.real_estate_agent_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZoGo Realtor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Agent Portal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                            onPressed: () async {
                              await NotificationsSheet.show(context);
                              _loadUnreadNotifications();
                            },
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Center(
                                  child: Text(
                                    _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _buildTopProfileAvatar(isLight: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Welcome back, ${_userProfile['firstName'] ?? 'Agent'} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Operating Districts: Colombo • Gampaha',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overview Metrics Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workflow Metrics',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_isLoadingDashboard)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryCyan),
                    ),
                ],
              ),
            ),
          ),

          // Stat Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.98,
              children: [
                AgentStatCard(
                  title: 'Interested',
                  count: _dashboard.interestedProperties,
                  icon: Icons.favorite_rounded,
                  startColor: const Color(0xFF06B6D4),
                  endColor: const Color(0xFF0284C7),
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                AgentStatCard(
                  title: 'Pending Visits',
                  count: _dashboard.pendingVisits,
                  icon: Icons.event_available_rounded,
                  startColor: const Color(0xFFF59E0B),
                  endColor: const Color(0xFFD97706),
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                AgentStatCard(
                  title: 'Documents',
                  count: _dashboard.pendingDocuments,
                  icon: Icons.folder_shared_rounded,
                  startColor: const Color(0xFF8B5CF6),
                  endColor: const Color(0xFF6D28D9),
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                AgentStatCard(
                  title: 'Territory',
                  count: 2,
                  icon: Icons.map_rounded,
                  startColor: const Color(0xFF10B981),
                  endColor: const Color(0xFF059669),
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ),

          // Quick Shortcuts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: const Text(
                'Assigned Tasks',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionTile(
                  icon: Icons.visibility_rounded,
                  color: const Color(0xFF0284C7),
                  title: 'Review Buyer Interests',
                  subtitle: '${_dashboard.interestedProperties} properties with active buyer interest',
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFFD97706),
                  title: 'Execute Scheduled Visits',
                  subtitle: '${_dashboard.pendingVisits} buyer visits awaiting inspection completion',
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                const SizedBox(height: 10),
                _buildActionTile(
                  icon: Icons.description_rounded,
                  color: const Color(0xFF6D28D9),
                  title: 'Prepare Legal Documents',
                  subtitle: '${_dashboard.pendingDocuments} post-visit document requests pending',
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1: TERRITORY LISTINGS
  // ============================================================
  Widget _buildTerritoryTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Territory Listings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          _buildTopProfileAvatar(),
        ],
      ),
      body: const AgentTerritoryTab(),
    );
  }

  // ============================================================
  // TAB 2: VISITS CALENDAR
  // ============================================================
  Widget _buildVisitsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visits Calendar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          _buildTopProfileAvatar(),
        ],
      ),
      body: const AgentVisitsCalendarTab(),
    );
  }

  // ============================================================
  // TAB 3: PENDING DOCUMENTS
  // ============================================================
  Widget _buildDocumentsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pending Documents', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadDocuments,
          ),
          _buildTopProfileAvatar(),
        ],
      ),
      body: _isLoadingDocs
          ? const Center(child: CircularProgressIndicator(color: primaryCyan))
          : _pendingDocuments.isEmpty
              ? _buildEmptyState(
                  icon: Icons.folder_shared_rounded,
                  title: 'No Document Requests',
                  subtitle: 'Buyers who complete visits and request deeds/legal documents will appear here.',
                  onRefresh: _loadDocuments,
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  color: primaryCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pendingDocuments.length,
                    itemBuilder: (ctx, i) {
                      final item = _pendingDocuments[i];
                      return AgentPropertyCard(
                        item: item,
                        onVerifyDocuments: () => _handleVerifyDocuments(item),
                        onRejectDocuments: () => _handleRejectDocuments(item),
                        onMarkSold: () => _handleMarkSold(item),
                        onRejectInquiry: () => _handleRejectInquiry(item),
                        onCallBuyer: () => _handleCallBuyer(item.buyerPhone),
                        onChatWithBuyer: () => _openChatWithBuyer(item),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyerPropertyDetailsScreen(
                                propertyId: item.propertyId,
                                isAgentView: true,
                                buyerName: item.buyerName,
                                buyerPhoneNumber: item.buyerPhone,
                                buyerUserId: item.buyerUserId,
                                sellerName: item.sellerName,
                                sellerPhoneNumber: item.sellerPhone,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRefresh,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: primaryCyan),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION BAR
  // ============================================================
  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: Colors.white,
      elevation: 8,
      indicatorColor: primaryCyan.withValues(alpha: 0.15),
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: primaryCyan),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded, color: primaryCyan),
          label: 'Territory',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded, color: primaryCyan),
          label: 'Visits',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_shared_outlined),
          selectedIcon: Icon(Icons.folder_shared_rounded, color: primaryCyan),
          label: 'Documents',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _agentService.dispose();
    super.dispose();
  }
}
