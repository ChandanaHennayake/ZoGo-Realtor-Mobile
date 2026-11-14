import 'package:flutter/material.dart';
import '../../data/services/admin_property_service.dart';
import '../../models/admin_property_model.dart';
import 'admin_property_review_detail_screen.dart';

class AdminPropertyQueueScreen extends StatefulWidget {
  const AdminPropertyQueueScreen({super.key});

  @override
  State<AdminPropertyQueueScreen> createState() =>
      _AdminPropertyQueueScreenState();
}

class _AdminPropertyQueueScreenState extends State<AdminPropertyQueueScreen> {
  static const Color slateBg = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF161B26);
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color purpleAccent = Color(0xFF6366F1);

  final AdminPropertyService _adminService = AdminPropertyService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminPropertySummaryModel> _allProperties = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  int? _selectedStatusFilter; // null means All, or 4 (Pending), 3 (Review), 9 (Changes), 2 (Published)

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminService.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _adminService.getProperties(
        status: _selectedStatusFilter,
        pageNumber: 1,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _allProperties = items;
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

  List<AdminPropertySummaryModel> get _filteredProperties {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allProperties;

    return _allProperties.where((p) {
      final matchTitle = p.title.toLowerCase().contains(query);
      final matchRef = p.referenceNo.toLowerCase().contains(query);
      final matchDistrict = p.districtName.toLowerCase().contains(query);
      final matchOwner = p.ownerName.toLowerCase().contains(query);
      return matchTitle || matchRef || matchDistrict || matchOwner;
    }).toList();
  }

  String _formatPrice(double val) {
    if (val >= 10000000) {
      return 'LKR ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return 'LKR ${(val / 100000).toStringAsFixed(2)} Lakhs';
    }
    return 'LKR ${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slateBg,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: primaryCyan, size: 22),
            SizedBox(width: 10),
            Text(
              'Property Review Queue',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadProperties,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: cardDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by title, ref no, seller, or district...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: slateBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryCyan),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('All Listings', null),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Pending Review', AdminPropertySummaryModel.statusPendingApproval, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Under Review', AdminPropertySummaryModel.statusUnderReview, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Changes Requested', AdminPropertySummaryModel.statusChangesRequested, color: purpleAccent),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Published', AdminPropertySummaryModel.statusPublished, color: const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, int? statusValue, {Color? color}) {
    final isSelected = _selectedStatusFilter == statusValue;
    final chipColor = color ?? primaryCyan;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? statusValue : null;
        });
        _loadProperties();
      },
      selectedColor: chipColor,
      backgroundColor: slateBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.white12,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: primaryCyan),
            SizedBox(height: 14),
            Text('Fetching submitted listings...', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
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
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProperties,
                style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.black),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filteredProperties;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProperties,
        color: primaryCyan,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryCyan.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: primaryCyan),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Approval Queue is Clean',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'No listings pending review matching your filters.',
                style: TextStyle(fontSize: 13, color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProperties,
      color: primaryCyan,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildQueueCard(item);
        },
      ),
    );
  }

  Widget _buildQueueCard(AdminPropertySummaryModel item) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status badge & Ref
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.statusIcon, size: 12, color: item.statusColor),
                      const SizedBox(width: 4),
                      Text(
                        item.statusName.toUpperCase(),
                        style: TextStyle(color: item.statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  item.referenceNo,
                  style: const TextStyle(color: primaryCyan, fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ],
            ),
          ),

          // Image & Details Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: slateBg,
                    child: (item.primaryImageUrl != null && item.primaryImageUrl!.isNotEmpty)
                        ? Image.network(
                            item.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.apartment_rounded, color: Colors.white24, size: 30),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.home_work_outlined, color: Colors.white24, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.districtName} • ${item.propertyTypeName}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(item.askingPrice),
                        style: const TextStyle(color: primaryCyan, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),

          // Footer: Seller name, documents badge, and review action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.ownerName,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: slateBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 11, color: purpleAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${item.documentCount} Docs',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPropertyReviewDetailScreen(
                          propertyId: item.propertyId,
                          propertyTitle: item.title,
                        ),
                      ),
                    );
                    if (updated == true) {
                      _loadProperties();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
