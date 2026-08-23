import 'package:flutter/material.dart';

import '../widgets/featured_property_card.dart';
import '../widgets/home_header.dart';
import '../widgets/property_type_card.dart';
import '../widgets/recommended_property_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const Color primaryCyan = Color(0xFF00C6D4);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),

      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            _buildPlaceholder('Search'),
            _buildPlaceholder('Saved'),
            _buildPlaceholder('Messages'),
            _buildPlaceholder('Profile'),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

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

  Widget _buildPropertyActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
                  onTap: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
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
                color: Color(0xFFFF2D7A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

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
      indicatorColor: primaryCyan.withValues(alpha: 0.12),
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
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
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
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