import 'package:flutter/material.dart';
import 'package:zogo_realtor/features/agent/presentation/screens/agent_home_screen.dart';

import '../widgets/home_header.dart';
import '../widgets/property_type_card.dart';
import 'my_activities_screen.dart';

import 'package:zogo_realtor/features/seller/presentation/screens/seller_activation_screen.dart';
import 'package:zogo_realtor/features/buyer/data/services/buyer_favorite_service.dart';
import 'package:zogo_realtor/features/buyer/data/services/buyer_property_service.dart';
import 'package:zogo_realtor/features/buyer/models/buyer_property_list_item.dart';
import 'package:zogo_realtor/features/buyer/presentation/screens/buyer_property_details_screen.dart';
import 'package:zogo_realtor/features/buyer/presentation/widgets/buyer_property_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.roles,
    required this.onActivateSeller,
    this.onListProperty,
  });

  /// Roles returned from the login API.
  final List<String> roles;

  /// Calls POST /api/v1/seller/activate and returns true on success.
  final Future<bool> Function() onActivateSeller;

  /// Optional override for the "create listing" action.
  final VoidCallback? onListProperty;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<String> _roles;

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color pinkAccent = Color(0xFFFF2D7A);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  final List<String> _propertyTypes = [
    'Buy',
    'Rent',
    'Sell',
  ];

  final List<IconData> _propertyIcons = [
    Icons.home_outlined,
    Icons.key_outlined,
    Icons.sell_outlined,
  ];

  // Services & Controllers
  final BuyerPropertyService _propertyService = BuyerPropertyService();
  final BuyerFavoriteService _favoriteService = BuyerFavoriteService();
  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Properties Feed State
  final List<BuyerPropertyListItem> _properties = [];
  bool _isLoadingProperties = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _propertiesError;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Filters State
  String _searchQuery = '';
  int? _selectedPropertyTypeId; // null: All Types
  int? _selectedListingTypeId; // null: All Listings, 1: For Sale, 2: For Rent

  List<Map<String, dynamic>> _propertyTypeOptions = [
    {'id': null, 'label': 'All Types'},
  ];

  // ============================================================
  // INIT & LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _roles = List<String>.from(widget.roles);
    _homeScrollController.addListener(_onHomeScroll);
    _loadMasterFilterData();
    _loadProperties(refresh: true);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roles != oldWidget.roles) {
      _roles = List<String>.from(widget.roles);
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _searchController.dispose();
    _propertyService.dispose();
    _favoriteService.dispose();
    super.dispose();
  }

  void _onHomeScroll() {
    if (_homeScrollController.position.pixels >=
            _homeScrollController.position.maxScrollExtent - 250 &&
        !_isLoadingProperties &&
        !_isLoadingMore &&
        _hasMore) {
      _loadProperties(refresh: false);
    }
  }

  bool get _hasSellerRole {
    return _roles.any(
      (role) => role.trim().toUpperCase() == 'SEL',
    );
  }

  bool get _hasAgentRole {
    return _roles.any(
      (role) => role.trim().toUpperCase() == 'AGT',
    );
  }

  void _addSellerRoleLocally() {
    if (_hasSellerRole) return;
    setState(() {
      _roles = [..._roles, 'SEL'];
    });
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadMasterFilterData() async {
    try {
      final types = await _propertyService.getPropertyTypes();
      if (!mounted) return;
      if (types.isNotEmpty) {
        setState(() {
          _propertyTypeOptions = [
            {'id': null, 'label': 'All Types'},
            ...types.map((t) => {
                  'id': (t['id'] as num?)?.toInt(),
                  'label': t['name']?.toString() ?? 'Type #${t['id']}',
                }),
          ];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProperties({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoadingProperties = true;
        _propertiesError = null;
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
        searchQuery: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        propertyTypeId: _selectedPropertyTypeId,
        listingTypeId: _selectedListingTypeId,
        forceRefresh: refresh,
      );

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
        _isLoadingProperties = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _propertiesError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProperties = false;
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
      return false;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_hasAgentRole) {
      return AgentHomeScreen(roles: _roles);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(bottom: false, child: _buildHome()),
          MyActivitiesScreen(
            hasSellerRole: _hasSellerRole,
            onExploreProperties: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
            onActivateSeller: _handleSell,
            onListProperty: widget.onListProperty,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // HOME TAB
  // ============================================================

  Widget _buildHome() {
    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: () => _loadProperties(refresh: true),
      child: CustomScrollView(
        controller: _homeScrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header with integrated Search bar
          SliverToBoxAdapter(
            child: HomeHeader(
              roles: _roles,
              searchController: _searchController,
              onSearchChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _loadProperties(refresh: true);
              },
              onSearchSubmitted: (_) => _loadProperties(refresh: true),
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _loadProperties(refresh: true);
              },
            ),
          ),

          // Property Actions (Buy / Rent / Sell)
          SliverToBoxAdapter(
            child: _buildPropertyActions(),
          ),

          // Horizontal Category & Listing Type Filter Chips
          SliverToBoxAdapter(
            child: _buildFilterChipsRow(),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              _searchQuery.isNotEmpty
                  ? 'Search Results'
                  : (_selectedListingTypeId == 1
                      ? 'Properties For Sale'
                      : (_selectedListingTypeId == 2 ? 'Properties For Rent' : 'Available Properties')),
            ),
          ),

          // Property Listing Feed
          _buildPropertiesSliver(),

          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY ACTIONS (BUY / RENT / SELL)
  // ============================================================

  Widget _buildPropertyActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: List.generate(
          _propertyTypes.length,
          (index) {
            final isBuy = index == 0;
            final isRent = index == 1;
            final isSelected = (isBuy && _selectedListingTypeId == 1) ||
                (isRent && _selectedListingTypeId == 2);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == 2 ? 0 : 10,
                ),
                child: PropertyTypeCard(
                  title: _propertyTypes[index],
                  icon: _propertyIcons[index],
                  isSelected: isSelected,
                  onTap: () {
                    _handlePropertyAction(index);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handlePropertyAction(int index) {
    switch (index) {
      case 0: // Buy
        setState(() {
          if (_selectedListingTypeId == 1) {
            _selectedListingTypeId = null; // Toggle off
          } else {
            _selectedListingTypeId = 1; // For Sale
          }
        });
        _loadProperties(refresh: true);
        break;

      case 1: // Rent
        setState(() {
          if (_selectedListingTypeId == 2) {
            _selectedListingTypeId = null; // Toggle off
          } else {
            _selectedListingTypeId = 2; // For Rent
          }
        });
        _loadProperties(refresh: true);
        break;

      case 2: // Sell
        _handleSell();
        break;
    }
  }

  Future<void> _handleSell() async {
    if (_hasSellerRole) {
      _openMyActivities();
      return;
    }

    final activated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SellerActivationScreen(
            onActivateSeller: widget.onActivateSeller,
          );
        },
      ),
    );

    if (!mounted) return;
    if (activated != true) return;

    _addSellerRoleLocally();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seller account activated successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _openMyActivities();
  }

  void _openMyActivities() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  // ============================================================
  // FILTER CHIPS ROW
  // ============================================================

  Widget _buildFilterChipsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // All Listings
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
            const SizedBox(width: 8),
            // For Sale
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
            const SizedBox(width: 8),
            // For Rent
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
            Container(height: 20, width: 1.5, color: Colors.grey.shade300),
            const SizedBox(width: 12),

            // Dynamic Property Types
            ..._propertyTypeOptions.map((opt) {
              final isSel = _selectedPropertyTypeId == opt['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryCyan : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryCyan : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : darkText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_properties.isNotEmpty)
            Text(
              '${_properties.length} ${_properties.length == 1 ? 'property' : 'properties'}',
              style: const TextStyle(
                color: secondaryGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTIES SLIVER
  // ============================================================

  Widget _buildPropertiesSliver() {
    if (_isLoadingProperties && _properties.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: primaryCyan),
          ),
        ),
      );
    }

    if (_propertiesError != null && _properties.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load properties',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _propertiesError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: secondaryGray, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadProperties(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.home_work_outlined, size: 36, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Properties Found',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkText),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try modifying your search or clearing selected filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: secondaryGray),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedListingTypeId = null;
                      _selectedPropertyTypeId = null;
                    });
                    _loadProperties(refresh: true);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryCyan,
                    side: const BorderSide(color: primaryCyan),
                  ),
                  child: const Text('Reset All Filters'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _properties.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(color: primaryCyan)
                      : const SizedBox.shrink(),
                ),
              );
            }

            final property = _properties[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BuyerPropertyCard(
                property: property,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerPropertyDetailsScreen(
                        propertyId: property.propertyId,
                        initialItem: property,
                      ),
                    ),
                  );
                  _loadProperties(refresh: true);
                },
                onFavoriteToggle: _handleFavoriteToggle,
              ),
            );
          },
          childCount: _properties.length + (_hasMore ? 1 : 0),
        ),
      ),
    );
  }

  // ============================================================
  // SAVED TAB
  // ============================================================

  Widget buildSavedTab() {
    return FutureBuilder<List<BuyerPropertyListItem>>(
      future: BuyerFavoriteService().getFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryCyan),
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: pinkAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 38,
                      color: pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Saved Properties',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the heart icon on any property to save it to your favorites list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0; // Switch to Home
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryCyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Explore Properties'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: primaryCyan,
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: favorites.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = favorites[index];
              return BuyerPropertyCard(
                property: item,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerPropertyDetailsScreen(
                        propertyId: item.propertyId,
                        initialItem: item,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                onFavoriteToggle: (propertyId, currentlyFavorite) async {
                  if (currentlyFavorite) {
                    await BuyerFavoriteService().removeFavorite(propertyId);
                  } else {
                    await BuyerFavoriteService().addFavorite(propertyId);
                  }
                  if (mounted) setState(() {});
                  return true;
                },
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
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
      indicatorColor: primaryCyan.withValues(
        alpha: 0.12,
      ),
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_activity_outlined),
          selectedIcon: Icon(Icons.local_activity_rounded),
          label: 'Activity',
        ),
      ],
    );
  }
}
