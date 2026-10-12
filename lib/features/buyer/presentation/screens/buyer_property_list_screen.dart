import 'package:flutter/material.dart';
import '../../data/services/buyer_favorite_service.dart';
import '../../data/services/buyer_property_service.dart';
import '../../models/buyer_property_list_item.dart';
import '../widgets/buyer_property_card.dart';
import 'buyer_property_details_screen.dart';

class BuyerPropertyListScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? initialCategory;
  final int? initialListingType;

  const BuyerPropertyListScreen({
    super.key,
    this.isEmbedded = false,
    this.initialCategory,
    this.initialListingType,
  });

  @override
  State<BuyerPropertyListScreen> createState() =>
      _BuyerPropertyListScreenState();
}

class _BuyerPropertyListScreenState extends State<BuyerPropertyListScreen> {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  final BuyerPropertyService _propertyService = BuyerPropertyService();
  final BuyerFavoriteService _favoriteService = BuyerFavoriteService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<BuyerPropertyListItem> _properties = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  static const int _pageSize = 20;

  String _searchQuery = '';
  int? _selectedPropertyTypeId; // null: All, 1: House, 2: Apartment, 3: Land, 4: Commercial, 5: Villa
  int? _selectedListingTypeId; // null: All, 1: For Sale, 2: For Rent

  static const List<Map<String, dynamic>> _propertyTypeOptions = [
    {'id': null, 'label': 'All Types'},
    {'id': 1, 'label': 'House'},
    {'id': 2, 'label': 'Apartment'},
    {'id': 3, 'label': 'Land'},
    {'id': 4, 'label': 'Commercial'},
    {'id': 5, 'label': 'Villa'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialListingType != null) {
      _selectedListingTypeId = widget.initialListingType;
    }
    if (widget.initialCategory != null) {
      _applyInitialCategory(widget.initialCategory!);
    }
    _scrollController.addListener(_onScroll);
    _loadProperties(refresh: true);
  }

  void _applyInitialCategory(String category) {
    switch (category.toLowerCase()) {
      case 'house':
        _selectedPropertyTypeId = 1;
        break;
      case 'apartment':
        _selectedPropertyTypeId = 2;
        break;
      case 'land':
        _selectedPropertyTypeId = 3;
        break;
      case 'commercial':
        _selectedPropertyTypeId = 4;
        break;
      case 'villa':
        _selectedPropertyTypeId = 5;
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _propertyService.dispose();
    _favoriteService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadProperties(refresh: false);
    }
  }

  Future<void> _loadProperties({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final pageToLoad = refresh ? 1 : _currentPage + 1;
      final newItems = await _propertyService.getBuyerProperties(
        pageNumber: pageToLoad,
        pageSize: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        propertyTypeId: _selectedPropertyTypeId,
        listingTypeId: _selectedListingTypeId,
      );

      // Check favorites to synchronize favorite flags
      List<BuyerPropertyListItem> favoritesList = [];
      try {
        favoritesList = await _favoriteService.getFavorites();
      } catch (_) {}

      final favIds = favoritesList.map((f) => f.propertyId.toLowerCase()).toSet();

      final mappedItems = newItems.map((item) {
        final isFav = favIds.contains(item.propertyId.toLowerCase()) || item.isFavorite;
        return item.copyWith(isFavorite: isFav);
      }).toList();

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _properties.clear();
        }
        _properties.addAll(mappedItems);
        _currentPage = pageToLoad;
        _hasMore = newItems.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<bool> _handleFavoriteToggle(String propertyId, bool currentlyFavorite) async {
    try {
      if (currentlyFavorite) {
        await _favoriteService.removeFavorite(propertyId);
      } else {
        await _favoriteService.addFavorite(propertyId);
      }

      // Update local state
      setState(() {
        final idx = _properties.indexWhere(
          (p) => p.propertyId.toLowerCase() == propertyId.toLowerCase(),
        );
        if (idx != -1) {
          _properties[idx] = _properties[idx].copyWith(isFavorite: !currentlyFavorite);
        }
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void _openDetails(BuyerPropertyListItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerPropertyDetailsScreen(
          propertyId: item.propertyId,
          initialItem: item,
        ),
      ),
    );

    // If favorite status changed inside details, refresh state
    if (result is bool) {
      setState(() {
        final idx = _properties.indexWhere(
          (p) => p.propertyId.toLowerCase() == item.propertyId.toLowerCase(),
        );
        if (idx != -1) {
          _properties[idx] = _properties[idx].copyWith(isFavorite: result);
        }
      });
    } else {
      _loadProperties(refresh: true);
    }
  }

  List<BuyerPropertyListItem> get _filteredProperties {
    return _properties.where((item) {
      if (_selectedPropertyTypeId != null &&
          item.propertyTypeId != _selectedPropertyTypeId) {
        return false;
      }
      if (_selectedListingTypeId != null &&
          item.listingTypeId != _selectedListingTypeId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matches = item.title.toLowerCase().contains(q) ||
            item.referenceNo.toLowerCase().contains(q) ||
            item.locationDisplay.toLowerCase().contains(q) ||
            item.propertyTypeName.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: RefreshIndicator(
            color: primaryCyan,
            onRefresh: () => _loadProperties(refresh: true),
            child: _buildBody(),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Properties',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: darkText),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadProperties(refresh: true),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search input box
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onSubmitted: (_) => _loadProperties(refresh: true),
              decoration: InputDecoration(
                hintText: 'Search properties by title, city, reference...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadProperties(refresh: true);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Listing Type Switch (All / For Sale / For Rent)
                _buildFilterChip(
                  label: 'All Listings',
                  isSelected: _selectedListingTypeId == null,
                  onSelected: () {
                    setState(() {
                      _selectedListingTypeId = null;
                    });
                    _loadProperties(refresh: true);
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'For Sale',
                  isSelected: _selectedListingTypeId == 1,
                  onSelected: () {
                    setState(() {
                      _selectedListingTypeId = 1;
                    });
                    _loadProperties(refresh: true);
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'For Rent',
                  isSelected: _selectedListingTypeId == 2,
                  onSelected: () {
                    setState(() {
                      _selectedListingTypeId = 2;
                    });
                    _loadProperties(refresh: true);
                  },
                ),
                const SizedBox(width: 12),
                Container(height: 20, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),

                // Property Types
                ..._propertyTypeOptions.map((opt) {
                  final isSel = _selectedPropertyTypeId == opt['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: opt['label'].toString(),
                      isSelected: isSel,
                      onSelected: () {
                        setState(() {
                          _selectedPropertyTypeId = opt['id'] as int?;
                        });
                        _loadProperties(refresh: true);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryCyan : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryCyan : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryCyan),
            SizedBox(height: 14),
            Text(
              'Loading verified properties...',
              style: TextStyle(fontSize: 14, color: secondaryGray),
            ),
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
              const Icon(Icons.error_outline_rounded, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: secondaryGray),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadProperties(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filteredProperties;

    if (items.isEmpty) {
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
                child: const Icon(
                  Icons.real_estate_agent_outlined,
                  size: 36,
                  color: primaryCyan,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No properties available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No published properties match your current search and filter criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: secondaryGray, height: 1.4),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedPropertyTypeId = null;
                    _selectedListingTypeId = null;
                  });
                  _loadProperties(refresh: true);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Clear Filters', style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingMore
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryCyan,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Loading more properties...', style: TextStyle(color: secondaryGray, fontSize: 13)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        final property = items[index];
        return BuyerPropertyCard(
          property: property,
          onTap: () => _openDetails(property),
          onFavoriteToggle: _handleFavoriteToggle,
        );
      },
    );
  }
}
