import 'package:flutter/material.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/auth/presentation/screens/get_started_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/SellerMyPropertiesScreen.dart';

import '../widgets/featured_property_card.dart';
import '../widgets/home_header.dart';
import '../widgets/property_type_card.dart';
import '../widgets/recommended_property_card.dart';

import 'package:zogo_realtor/features/seller/presentation/screens/seller_activation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.roles,
    required this.onActivateSeller,
    this.onListProperty,
  });

  /// Roles returned from the login API.
  ///
  /// Example:
  /// ['BYR']
  ///
  /// or:
  /// ['SEL', 'BYR']
  final List<String> roles;

  /// Calls POST /api/v1/seller/activate and returns true on success.
  final Future<bool> Function() onActivateSeller;

  /// Optional override for the "create listing" action.
  ///
  /// Leave null and SellerMyPropertiesScreen navigates on its own.
  /// Do NOT pass a callback that uses a disposed screen's context
  /// (e.g. LoginScreen after pushReplacement).
  final VoidCallback? onListProperty;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Local, mutable copy of the roles.
  ///
  /// widget.roles is final and comes from the login response, so it can
  /// never reflect an activation that happens during this session.
  late List<String> _roles;

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color pinkAccent = Color(0xFFFF2D7A);

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

  final TextEditingController _homeSearchController = TextEditingController();
  String _searchCategory = 'All';
  String _searchQueryText = '';

  // ============================================================
  // ROLES
  // ============================================================

  @override
  void initState() {
    super.initState();
    _roles = List<String>.from(widget.roles);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the parent re-issues roles (e.g. after a token refresh),
    // take the fresher list.
    if (widget.roles != oldWidget.roles) {
      _roles = List<String>.from(widget.roles);
    }
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  bool get _hasSellerRole {
    return _roles.any(
      (role) => role.trim().toUpperCase() == 'SEL',
    );
  }

  void _addSellerRoleLocally() {
    if (_hasSellerRole) {
      return;
    }

    setState(() {
      _roles = [..._roles, 'SEL'];
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),

      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            _buildSellerPropertiesTab(),
            _buildSearchTab(),
            _buildSavedTab(),
            _buildProfile(),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: HomeHeader(),
        ),

        SliverToBoxAdapter(
          child: _buildPropertyActions(),
        ),

        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Featured Properties',
          ),
        ),

        const SliverToBoxAdapter(
          child: FeaturedPropertyCard(
            imageUrl:
                'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=80',
            price: 'Rs. 45,000,000',
            title: 'Modern Villa in Colombo',
            location: 'Colombo 07',
            beds: '4 Beds',
            baths: '3 Baths',
            area: '2,800 sq.ft',
          ),
        ),

        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Recommended for you',
          ),
        ),

        SliverToBoxAdapter(
          child: _buildRecommendedProperties(),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  // ============================================================
  // BUY / RENT / SELL
  // ============================================================

  Widget _buildPropertyActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        8,
      ),
      child: Row(
        children: List.generate(
          _propertyTypes.length,
          (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == 2 ? 0 : 10,
                ),
                child: PropertyTypeCard(
                  title: _propertyTypes[index],
                  icon: _propertyIcons[index],
                  isSelected: index == 0,
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
      case 0:
        _handleBuy();
        break;

      case 1:
        _handleRent();
        break;

      case 2:
        _handleSell();
        break;
    }
  }

  // ============================================================
  // BUY
  // ============================================================

  void _handleBuy() {
    setState(() {
      _searchCategory = 'All';
      _selectedIndex = 2;
    });
  }

  // ============================================================
  // RENT
  // ============================================================

  void _handleRent() {
    setState(() {
      _searchCategory = 'Apartment';
      _selectedIndex = 2;
    });
  }

  // ============================================================
  // SELL
  // ============================================================

  Future<void> _handleSell() async {
    // ----------------------------------------------------------
    // ALREADY A SELLER -> SWITCH DIRECTLY TO MY PROPERTIES TAB
    // ----------------------------------------------------------

    if (_hasSellerRole) {
      _openMyProperties();
      return;
    }

    // ----------------------------------------------------------
    // NOT A SELLER -> SHOW ACTIVATION SCREEN
    // ----------------------------------------------------------

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

    if (!mounted) {
      return;
    }

    if (activated != true) {
      return;
    }

    _addSellerRoleLocally();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Seller account activated successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _openMyProperties();
  }

  void _openMyProperties() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        12,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: () {},
            child: const Text(
              'View All',
              style: TextStyle(
                color: pinkAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDED PROPERTIES
  // ============================================================

  Widget _buildRecommendedProperties() {
    final properties = [
      (
        title: 'Beachfront Villa',
        price: 'Rs. 75,000,000',
        location: 'Galle',
        image:
            'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Modern House',
        price: 'Rs. 28,500,000',
        location: 'Kandy',
        image:
            'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Luxury Apartment',
        price: 'Rs. 32,000,000',
        location: 'Colombo',
        image:
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=500&q=80',
      ),
    ];

    return SizedBox(
      height: 205,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];

          return RecommendedPropertyCard(
            imageUrl: property.image,
            title: property.title,
            price: property.price,
            location: property.location,
            onTap: () {},
            onFavorite: () {},
          );
        },
      ),
    );
  }

  // ============================================================
  // TABS IMPLEMENTATION
  // ============================================================

  Widget _buildSellerPropertiesTab() {
    if (_hasSellerRole) {
      return SellerMyPropertiesScreen(
        onListProperty: widget.onListProperty,
        isEmbedded: true,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 42,
                color: primaryCyan,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seller Account Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activate your seller account to list and manage your properties directly inside ZoGo Realtor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleSell,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text(
                'Activate Seller Account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    final allProperties = [
      (
        title: 'Modern Luxury Villa',
        type: 'Villa',
        price: 'Rs. 45,000,000',
        location: 'Colombo 07',
        beds: '4 Beds',
        image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=80',
      ),
      (
        title: 'Beachfront Holiday Villa',
        type: 'Villa',
        price: 'Rs. 75,000,000',
        location: 'Galle Fort',
        beds: '5 Beds',
        image: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Contemporary Mountain House',
        type: 'House',
        price: 'Rs. 28,500,000',
        location: 'Kandy Hills',
        beds: '3 Beds',
        image: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Skyline Luxury Penthouse',
        type: 'Apartment',
        price: 'Rs. 32,000,000',
        location: 'Colombo 03',
        beds: '3 Beds',
        image: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Commercial Retail Space',
        type: 'Commercial',
        price: 'Rs. 95,000,000',
        location: 'Kollupitiya',
        beds: 'Commercial',
        image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=500&q=80',
      ),
      (
        title: 'Prime Coconut Estate Land',
        type: 'Land',
        price: 'Rs. 18,000,000',
        location: 'Kurunegala',
        beds: 'Land',
        image: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80',
      ),
    ];

    final filtered = allProperties.where((p) {
      if (_searchCategory != 'All' && p.type.toLowerCase() != _searchCategory.toLowerCase()) {
        return false;
      }
      if (_searchQueryText.trim().isNotEmpty) {
        final q = _searchQueryText.trim().toLowerCase();
        final matches = p.title.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _homeSearchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQueryText = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by property name, city, type...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryCyan, size: 22),
                    suffixIcon: _searchQueryText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _homeSearchController.clear();
                              setState(() {
                                _searchQueryText = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'House', 'Apartment', 'Villa', 'Commercial', 'Land'].map((cat) {
                    final isSel = _searchCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: primaryCyan,
                        backgroundColor: const Color(0xFFF9FAFB),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.black87,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _searchCategory = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Result count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(
            children: [
              Text(
                'Showing ${filtered.length} properties',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No properties match your search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _homeSearchController.clear();
                          setState(() {
                            _searchQueryText = '';
                            _searchCategory = 'All';
                          });
                        },
                        child: const Text('Reset Search', style: TextStyle(color: primaryCyan, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              item.image,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: primaryCyan.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.type,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryCyan),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.price,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(item.location, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                    const Spacer(),
                                    Text(item.beds, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
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
                  _selectedIndex = 2; // Switch to Search tab
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

  Widget _buildProfile() {
    return FutureBuilder<Map<String, String>>(
      future: SecureStorageService().getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? {};
        final firstName = profile['firstName'] ?? '';
        final lastName = profile['lastName'] ?? '';
        final email = profile['email'] ?? '';
        final fullName = ('$firstName $lastName').trim().isNotEmpty
            ? ('$firstName $lastName').trim()
            : 'ZoGo User';

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: primaryCyan.withValues(alpha: 0.15),
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 8,
                children: _roles.map((r) {
                  final isSeller = r.toUpperCase() == 'SEL';
                  return Chip(
                    label: Text(
                      isSeller ? 'Seller' : (r.toUpperCase() == 'BYR' ? 'Buyer' : r),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSeller ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isSeller ? primaryCyan : Colors.grey.shade200,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            if (_hasSellerRole)
              ListTile(
                leading: const Icon(Icons.apartment_rounded, color: primaryCyan),
                title: const Text('My Listed Properties', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
                onTap: _openMyProperties,
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out from ZoGo Realtor?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SecureStorageService().clearAll();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
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
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment_rounded),
          label: 'My Properties',
        ),

        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded),
          label: 'Search',
        ),

        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: 'Saved',
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}