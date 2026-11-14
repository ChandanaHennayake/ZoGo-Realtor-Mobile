import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../buyer/presentation/screens/buyer_property_details_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../screens/agent_interested_leads_screen.dart';
import '../../data/services/agent_service.dart';
import '../../models/agent_territory_property_model.dart';

class AgentTerritoryTab extends StatefulWidget {
  final VoidCallback? onRefreshRequested;

  const AgentTerritoryTab({
    super.key,
    this.onRefreshRequested,
  });

  @override
  State<AgentTerritoryTab> createState() => _AgentTerritoryTabState();
}

class _AgentTerritoryTabState extends State<AgentTerritoryTab> {
  static const Color primaryCyan = Color(0xFF00C6D4);

  final AgentService _agentService = AgentService();
  final TextEditingController _searchController = TextEditingController();

  List<AgentTerritoryPropertyItem> _properties = [];
  bool _isLoading = true;
  String? _errorMessage;

  int? _selectedListingTypeId; // null: All, 1: Sale, 2: Rent
  int? _selectedPropertyTypeId; // null: All Types
  int? _selectedDistrictId;

  final List<Map<String, dynamic>> _propertyTypeOptions = [
    {'id': null, 'label': 'All Types'},
    {'id': 1, 'label': 'House'},
    {'id': 2, 'label': 'Apartment'},
    {'id': 3, 'label': 'Land'},
    {'id': 4, 'label': 'Commercial'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTerritoryProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _agentService.dispose();
    super.dispose();
  }

  Future<void> _loadTerritoryProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _agentService.getTerritoryProperties(
        districtId: _selectedDistrictId,
        listingTypeId: _selectedListingTypeId,
        propertyTypeId: _selectedPropertyTypeId,
        searchQuery: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() {
        _properties = items;
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

  String _formatCurrency(double amount) {
    if (amount <= 0) return 'Rs. 0';
    final parts = amount.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rs. ${parts.replaceAll(reg, ',')}';
  }

  Future<void> _callUser(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available for this lister.'),
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
    // Unique districts in current properties list for filter chips
    final districtsMap = <int, String>{};
    for (var p in _properties) {
      if (p.districtId > 0 && p.districtName.isNotEmpty) {
        districtsMap[p.districtId] = p.districtName;
      }
    }

    return Column(
      children: [
        // Search & Filter Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Quick Banner: Buyer Leads & Inquiries
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgentInterestedLeadsScreen(agentService: _agentService),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: primaryCyan, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buyer Inquiries & Leads',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Review interested buyers, call or chat directly',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: primaryCyan, size: 13),
                    ],
                  ),
                ),
              ),

              // Search input
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadTerritoryProperties(),
                decoration: InputDecoration(
                  hintText: 'Search title, address, ref #...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadTerritoryProperties();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Listing Type: All, Sale, Rent
                    _buildFilterChip(
                      label: 'All Listings',
                      isSelected: _selectedListingTypeId == null,
                      onSelected: () {
                        setState(() => _selectedListingTypeId = null);
                        _loadTerritoryProperties();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'For Sale',
                      isSelected: _selectedListingTypeId == 1,
                      onSelected: () {
                        setState(() => _selectedListingTypeId = 1);
                        _loadTerritoryProperties();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      label: 'For Rent',
                      isSelected: _selectedListingTypeId == 2,
                      onSelected: () {
                        setState(() => _selectedListingTypeId = 2);
                        _loadTerritoryProperties();
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 20, color: Colors.grey.shade300),
                    const SizedBox(width: 12),

                    // Property Types
                    ..._propertyTypeOptions.map((opt) {
                      final isSelected = _selectedPropertyTypeId == opt['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildFilterChip(
                          label: opt['label'] as String,
                          isSelected: isSelected,
                          onSelected: () {
                            setState(() => _selectedPropertyTypeId = opt['id'] as int?);
                            _loadTerritoryProperties();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              if (districtsMap.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDistrictChip(
                        label: 'All Territory Districts',
                        isSelected: _selectedDistrictId == null,
                        onSelected: () {
                          setState(() => _selectedDistrictId = null);
                          _loadTerritoryProperties();
                        },
                      ),
                      const SizedBox(width: 6),
                      ...districtsMap.entries.map((entry) {
                        final isSel = _selectedDistrictId == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildDistrictChip(
                            label: entry.value,
                            isSelected: isSel,
                            onSelected: () {
                              setState(() => _selectedDistrictId = entry.key);
                              _loadTerritoryProperties();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Count Banner
        Container(
          width: double.infinity,
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: primaryCyan),
              const SizedBox(width: 6),
              Text(
                '${_properties.length} published properties in your assigned operating territory',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Properties List
        Expanded(
          child: RefreshIndicator(
            color: primaryCyan,
            onRefresh: _loadTerritoryProperties,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryCyan : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryCyan : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTerritoryProperties,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map_rounded, size: 36, color: primaryCyan),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Territory Listings Found',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'When sellers publish properties in your assigned districts, they will automatically appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTerritoryProperties,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Territory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _properties.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _properties[index];
        return _buildTerritoryPropertyCard(item);
      },
    );
  }

  Widget _buildTerritoryPropertyCard(AgentTerritoryPropertyItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Ref # & District Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.referenceNo.isNotEmpty ? item.referenceNo : 'REF-PROP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.districtName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryCyan,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.listingTypeId == 2
                        ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.listingTypeName.isNotEmpty
                        ? item.listingTypeName
                        : (item.listingTypeId == 2 ? 'Rent' : 'Sale'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.listingTypeId == 2
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title & Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.addressLine1.isNotEmpty ? item.addressLine1 : item.cityName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Asking Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatCurrency(item.askingPrice),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryCyan,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Lister Section & Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.listerName.isNotEmpty ? item.listerName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
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
                        item.listerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.listerPhone ?? 'Phone on request',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Direct Call Lister
                IconButton.filled(
                  tooltip: 'Call Lister',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  onPressed: () => _callUser(item.listerPhone),
                ),
                const SizedBox(width: 8),

                // Chat Lister
                IconButton.filled(
                  tooltip: 'Chat Lister',
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
                          propertyTitle: item.title,
                          recipientId: item.listerUserId,
                          recipientName: item.listerName,
                          recipientRole: 'seller',
                          currentUserRole: 'agent',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // View Details
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
                          sellerPhoneNumber: item.listerPhone,
                        ),
                      ),
                    );
                  },
                  child: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
