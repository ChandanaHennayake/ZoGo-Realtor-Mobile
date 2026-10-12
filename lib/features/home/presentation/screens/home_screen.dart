import 'package:flutter/material.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';
import 'package:zogo_realtor/features/auth/presentation/screens/get_started_screen.dart';
import 'package:zogo_realtor/features/seller/presentation/screens/SellerMyPropertiesScreen.dart';
import 'package:zogo_realtor/features/agent/presentation/screens/agent_home_screen.dart';

import '../widgets/featured_property_card.dart';
import '../widgets/home_header.dart';
import '../widgets/property_type_card.dart';
import '../widgets/recommended_property_card.dart';

import 'package:zogo_realtor/features/seller/presentation/screens/seller_activation_screen.dart';
import 'package:zogo_realtor/features/buyer/data/services/buyer_favorite_service.dart';
import 'package:zogo_realtor/features/buyer/models/buyer_property_list_item.dart';
import 'package:zogo_realtor/features/buyer/presentation/screens/buyer_property_details_screen.dart';
import 'package:zogo_realtor/features/buyer/presentation/screens/buyer_property_list_screen.dart';
import 'package:zogo_realtor/features/buyer/presentation/widgets/buyer_property_card.dart';

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
    if (_hasAgentRole) {
      return AgentHomeScreen(roles: _roles);
    }

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerPropertyListScreen(),
      ),
    );
  }

  // ============================================================
  // RENT
  // ============================================================

  void _handleRent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerPropertyListScreen(
          initialListingType: 2,
        ),
      ),
    );
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

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
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
            onTap: onViewAll ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BuyerPropertyListScreen(),
                    ),
                  );
                },
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
    return const BuyerPropertyListScreen(isEmbedded: true);
  }

  Widget _buildSavedTab() {
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
                        _selectedIndex = 2; // Switch to Properties tab
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
            ListTile(
              leading: const Icon(Icons.travel_explore_rounded, color: primaryCyan),
              title: const Text('Browse Properties', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Explore properties available for sale and rent', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyerPropertyListScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: pinkAccent),
              title: const Text('Saved Properties', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('View your favorite saved properties', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_hasSellerRole) ...[
              ListTile(
                leading: const Icon(Icons.apartment_rounded, color: primaryCyan),
                title: const Text('My Listed Properties', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
                onTap: _openMyProperties,
              ),
              const SizedBox(height: 12),
            ],
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
          icon: Icon(Icons.travel_explore_outlined),
          selectedIcon: Icon(Icons.travel_explore_rounded),
          label: 'Properties',
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