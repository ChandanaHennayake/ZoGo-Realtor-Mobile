import 'package:flutter/material.dart';
import '../../../../features/buyer/data/services/buyer_offer_service.dart';
import '../../../../features/buyer/data/services/buyer_visit_service.dart';
import '../../../../features/buyer/models/property_offer_model.dart';
import '../../../../features/buyer/models/property_visit_model.dart';
import '../../../../features/buyer/presentation/screens/buyer_property_details_screen.dart';

class MyActivitiesScreen extends StatefulWidget {
  final bool hasSellerRole;
  final VoidCallback? onExploreProperties;
  final VoidCallback? onActivateSeller;
  final VoidCallback? onListProperty;

  const MyActivitiesScreen({
    super.key,
    required this.hasSellerRole,
    this.onExploreProperties,
    this.onActivateSeller,
    this.onListProperty,
  });

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color secondaryGray = Color(0xFF6B7280);

  late final TabController _tabController;
  final BuyerVisitService _visitService = BuyerVisitService();
  final BuyerOfferService _offerService = BuyerOfferService();

  List<PropertyVisitModel> _visits = [];
  List<PropertyOfferModel> _offers = [];

  bool _isLoadingVisits = true;
  bool _isLoadingOffers = true;
  String? _visitsError;
  String? _offersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVisits();
    _loadOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoadingVisits = true;
      _visitsError = null;
    });

    try {
      final visits = await _visitService.getMyVisits();
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _isLoadingVisits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _visitsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingVisits = false;
      });
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingOffers = true;
      _offersError = null;
    });

    try {
      final offers = await _offerService.getMyOffers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _isLoadingOffers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _offersError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingOffers = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    if (amount <= 0) return 'Rs. 0';
    final parts = amount.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rs. ${parts.replaceAll(reg, ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Activities',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: darkText),
            onPressed: () {
              _loadVisits();
              _loadOffers();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryCyan,
          unselectedLabelColor: secondaryGray,
          indicatorColor: primaryCyan,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 17),
                    const SizedBox(width: 5),
                    Text('Visits (${_visits.length})'),
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 17),
                    const SizedBox(width: 5),
                    Text('Offers (${_offers.length})'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVisitsTab(),
          _buildOffersTab(),
        ],
      ),
    );
  }

  Widget _buildVisitsTab() {
    if (_isLoadingVisits) {
      return const Center(child: CircularProgressIndicator(color: primaryCyan));
    }

    if (_visitsError != null && _visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Failed to load visits',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _visitsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryGray, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVisits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visits.isEmpty) {
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
                  color: primaryCyan.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note_rounded, size: 38, color: primaryCyan),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Visits Requested Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Schedule a visit to view properties in person. Your requested visits will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondaryGray, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (widget.onExploreProperties != null)
                ElevatedButton.icon(
                  onPressed: widget.onExploreProperties,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Explore Properties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: _loadVisits,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final visit = _visits[index];
          return _buildVisitCard(visit);
        },
      ),
    );
  }

  Widget _buildVisitCard(PropertyVisitModel visit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BuyerPropertyDetailsScreen(
                  propertyId: visit.propertyId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: visit.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(visit.icon, color: visit.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (visit.propertyReferenceNo.isNotEmpty)
                            Text(
                              visit.propertyReferenceNo,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryCyan,
                                letterSpacing: 0.5,
                              ),
                            ),
                          Text(
                            visit.propertyTitle.isNotEmpty ? visit.propertyTitle : 'Property Visit',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (visit.cityName.isNotEmpty || visit.districtName.isNotEmpty)
                            Text(
                              [visit.cityName, visit.districtName]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(fontSize: 12, color: secondaryGray),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: visit.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: visit.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        visit.statusName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: visit.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: primaryCyan),
                      const SizedBox(width: 6),
                      Text(
                        '${visit.scheduledAt.year}-${visit.scheduledAt.month.toString().padLeft(2, '0')}-${visit.scheduledAt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded, size: 16, color: primaryCyan),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          visit.timeSlot,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (visit.buyerNotes != null && visit.buyerNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${visit.buyerNotes!}',
                    style: const TextStyle(fontSize: 12, color: secondaryGray, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersTab() {
    if (_isLoadingOffers) {
      return const Center(child: CircularProgressIndicator(color: primaryCyan));
    }

    if (_offersError != null && _offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Failed to load offers',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _offersError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryGray, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOffers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_offers.isEmpty) {
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer_rounded, size: 38, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Offers Submitted Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit formal purchase offers for properties of interest. You can track all responses here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondaryGray, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (widget.onExploreProperties != null)
                ElevatedButton.icon(
                  onPressed: widget.onExploreProperties,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Explore Properties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryCyan,
      onRefresh: _loadOffers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _buildOfferCard(offer);
        },
      ),
    );
  }

  Widget _buildOfferCard(PropertyOfferModel offer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BuyerPropertyDetailsScreen(
                  propertyId: offer.propertyId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: offer.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(offer.icon, color: offer.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.propertyReferenceNo.isNotEmpty)
                            Text(
                              offer.propertyReferenceNo,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryCyan,
                                letterSpacing: 0.5,
                              ),
                            ),
                          Text(
                            offer.propertyTitle.isNotEmpty ? offer.propertyTitle : 'Formal Offer',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: offer.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: offer.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        offer.statusName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: offer.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OFFER AMOUNT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: secondaryGray),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(offer.offerAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      if (offer.askingPrice > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ASKING PRICE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: secondaryGray),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(offer.askingPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: secondaryGray,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (offer.counterAmount != null && offer.counterAmount! > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.handshake_rounded, size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Text(
                          'Seller Counter Offer: ${_formatCurrency(offer.counterAmount!)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
