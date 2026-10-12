import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/screens/get_started_screen.dart';
import '../../data/services/agent_service.dart';
import '../../models/agent_dashboard_model.dart';
import '../../models/agent_property_model.dart';
import '../widgets/agent_property_card.dart';
import '../widgets/agent_stat_card.dart';

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

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkCyan = Color(0xFF008D97);

  AgentDashboardModel _dashboard = AgentDashboardModel.empty();
  List<AgentPropertyItem> _interestedProperties = [];
  List<AgentPropertyItem> _pendingVisits = [];
  List<AgentPropertyItem> _pendingDocuments = [];

  bool _isLoadingDashboard = true;
  bool _isLoadingInterested = true;
  bool _isLoadingVisits = true;
  bool _isLoadingDocs = true;

  String? _markingVisitedPropertyId;

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
      _loadInterested(),
      _loadVisits(),
      _loadDocuments(),
    ]);
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

  Future<void> _loadInterested() async {
    setState(() => _isLoadingInterested = true);
    final data = await _agentService.getInterestedProperties();
    if (mounted) {
      setState(() {
        _interestedProperties = data;
        _isLoadingInterested = false;
      });
    }
  }

  Future<void> _loadVisits() async {
    setState(() => _isLoadingVisits = true);
    final data = await _agentService.getPendingVisits();
    if (mounted) {
      setState(() {
        _pendingVisits = data;
        _isLoadingVisits = false;
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

  Future<void> _handleMarkVisited(AgentPropertyItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Complete Visit'),
          ],
        ),
        content: Text(
          'Mark visit as completed for "${item.title}" with Buyer ${item.buyerName}?',
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
            child: const Text('Yes, Visited'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _markingVisitedPropertyId = item.propertyId;
    });

    final success = await _agentService.markVisited(
      item.propertyId,
      buyerId: item.buyerUserId.isNotEmpty ? item.buyerUserId : null,
    );

    if (mounted) {
      setState(() {
        _markingVisitedPropertyId = null;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Property visit marked as completed!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _refreshAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update visit status.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out from Agent workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _secureStorage.clearAll();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GetStartedScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardTab(),
            _buildInterestedTab(),
            _buildVisitsTab(),
            _buildDocumentsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // TAB 0: DASHBOARD
  // ============================================================
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: primaryCyan,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZoGo Realtor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Agent Portal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Verified Agent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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
              childAspectRatio: 1.15,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // TAB 1: INTERESTED PROPERTIES
  // ============================================================
  Widget _buildInterestedTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Interested Properties', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadInterested,
          ),
        ],
      ),
      body: _isLoadingInterested
          ? const Center(child: CircularProgressIndicator(color: primaryCyan))
          : _interestedProperties.isEmpty
              ? _buildEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Interested Properties',
                  subtitle: 'Properties where buyers express interest in your assigned districts will show here.',
                  onRefresh: _loadInterested,
                )
              : RefreshIndicator(
                  onRefresh: _loadInterested,
                  color: primaryCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _interestedProperties.length,
                    itemBuilder: (ctx, i) {
                      return AgentPropertyCard(item: _interestedProperties[i]);
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // TAB 2: PENDING VISITS
  // ============================================================
  Widget _buildVisitsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pending Visits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryCyan),
            onPressed: _loadVisits,
          ),
        ],
      ),
      body: _isLoadingVisits
          ? const Center(child: CircularProgressIndicator(color: primaryCyan))
          : _pendingVisits.isEmpty
              ? _buildEmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'No Pending Visits',
                  subtitle: 'When buyers request property visits in your districts, they appear here for inspection completion.',
                  onRefresh: _loadVisits,
                )
              : RefreshIndicator(
                  onRefresh: _loadVisits,
                  color: primaryCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pendingVisits.length,
                    itemBuilder: (ctx, i) {
                      final item = _pendingVisits[i];
                      return AgentPropertyCard(
                        item: item,
                        isMarkingVisited: _markingVisitedPropertyId == item.propertyId,
                        onMarkVisited: () => _handleMarkVisited(item),
                      );
                    },
                  ),
                ),
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
                      return AgentPropertyCard(item: _pendingDocuments[i]);
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // TAB 4: PROFILE & SETTINGS
  // ============================================================
  Widget _buildProfileTab() {
    final name = '${_userProfile['firstName'] ?? 'ZoGo'} ${_userProfile['lastName'] ?? 'Agent'}';
    final email = _userProfile['email'] ?? 'agent@zogo.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Agent Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryCyan, darkCyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryCyan.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 16, color: primaryCyan),
                      SizedBox(width: 6),
                      Text(
                        'Licensed Real Estate Agent (AGT)',
                        style: TextStyle(
                          color: primaryCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Operating Districts Info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_city_rounded, color: primaryCyan, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Assigned Territory',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Primary City: Colombo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Operating Districts:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDistrictChip('Colombo (Western Province)'),
                    _buildDistrictChip('Gampaha (Western Province)'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Log Out from Agent Workspace',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFFFCDD2)),
            ),
            tileColor: Colors.white,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded, color: primaryCyan),
          label: 'Interested',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available_rounded, color: primaryCyan),
          label: 'Visits',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_shared_outlined),
          selectedIcon: Icon(Icons.folder_shared_rounded, color: primaryCyan),
          label: 'Documents',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: primaryCyan),
          label: 'Profile',
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
