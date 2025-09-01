import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends State<ServiceCentersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Oil Change',
    'Tire Service',
    'Brake Repair',
    'Engine Repair',
    'Battery Service',
    'Transmission',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          // Header with gradient background
          _buildHeaderWithBackground(),
          
          // Filter section
          _buildFilterSection(),
          
          // Tab content
          Expanded(
            child: Container(
              color: AppTheme.getThemeAwareBackground(context),
              child: Column(
                children: [
                  // Custom Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    height: 44,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.getThemeAwareCardBackground(context).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.getThemeAwareBorderColor(context).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              width: 1,
                            ),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(vertical: 6),
                          labelStyle: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          tabs: const [
                            Tab(icon: Icon(Icons.map, size: 12), text: 'Map View'),
                            Tab(icon: Icon(Icons.list, size: 12), text: 'List View'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMapView(),
                        _buildListView(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If no previous route, try to navigate to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Service Centers',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Current Location',
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Find trusted service centers near you',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      height: 80,
      color: AppTheme.getThemeAwareBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Filter by Service Type',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getThemeAwareTextColor(context),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.getThemeAwareTextColor(context),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppTheme.getThemeAwareCardBackground(context).withOpacity(0.3),
                    selectedColor: AppTheme.primaryGreen,
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightBackground.withOpacity(0.3),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Simulated map background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightBackground.withOpacity(0.5),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Interactive Map View',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.backgroundGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Google Maps integration will be\nimplemented here',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      color: AppTheme.darkAccentGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Floating service center cards
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 180,
              child: PageView.builder(
                itemCount: _getFilteredServiceCenters().length,
                itemBuilder: (context, index) {
                  final center = _getFilteredServiceCenters()[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildServiceCenterCard(center, compact: true),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final serviceCenters = _getFilteredServiceCenters();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: serviceCenters.length,
      itemBuilder: (context, index) {
        return _buildServiceCenterCard(serviceCenters[index]);
      },
    );
  }

  Widget _buildServiceCenterCard(Map<String, dynamic> center, {bool compact = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 16),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showServiceCenterDetails(center),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 65,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getServiceIcon(center['category']),
                        color: AppTheme.primaryGreen,
                        size: compact ? 16 : 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center['name'],
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.backgroundGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < center['rating'].floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppTheme.warningColor,
                                  size: compact ? 14 : 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${center['rating']} (${center['reviews']} reviews)',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: compact ? 11 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: center['isOpen'] 
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              center['isOpen'] ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: center['isOpen'] 
                                    ? AppTheme.successColor 
                                    : AppTheme.errorColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${center['distance']} mi',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  center['address'],
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (center['services'] as List<String>).take(compact ? 2 : 4).map(
                    (service) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.backgroundGreen,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callServiceCenter(center),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text(
                            'Call',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(color: AppTheme.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToServiceCenter(center),
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredServiceCenters() {
    final allCenters = [
      {
        'name': 'QuickLube Express',
        'category': 'Oil Change',
        'rating': 4.5,
        'reviews': 127,
        'distance': 0.8,
        'isOpen': true,
        'address': '123 Main St, Downtown',
        'phone': '(555) 123-4567',
        'services': ['Oil Change', 'Filter Replacement', 'Fluid Check'],
      },
      {
        'name': 'AutoCare Plus',
        'category': 'Engine Repair',
        'rating': 4.8,
        'reviews': 89,
        'distance': 1.2,
        'isOpen': true,
        'address': '456 Oak Ave, Midtown',
        'phone': '(555) 234-5678',
        'services': ['Engine Repair', 'Transmission', 'Brake Service', 'Diagnostics'],
      },
      {
        'name': 'Tire Kingdom',
        'category': 'Tire Service',
        'rating': 4.3,
        'reviews': 156,
        'distance': 2.1,
        'isOpen': false,
        'address': '789 Pine Rd, East Side',
        'phone': '(555) 345-6789',
        'services': ['Tire Installation', 'Wheel Alignment', 'Balancing'],
      },
      {
        'name': 'Battery World',
        'category': 'Battery Service',
        'rating': 4.6,
        'reviews': 73,
        'distance': 2.8,
        'isOpen': true,
        'address': '321 Elm St, West End',
        'phone': '(555) 456-7890',
        'services': ['Battery Replacement', 'Electrical Repair', 'Alternator Service'],
      },
      {
        'name': 'Brake Masters',
        'category': 'Brake Repair',
        'rating': 4.7,
        'reviews': 94,
        'distance': 3.2,
        'isOpen': true,
        'address': '654 Maple Dr, South Side',
        'phone': '(555) 567-8901',
        'services': ['Brake Repair', 'Pad Replacement', 'Rotor Service'],
      },
    ];

    if (_selectedFilter == 'All') {
      return allCenters;
    }
    
    return allCenters.where((center) => 
        (center['services'] as List<String>).any((service) => 
            service.toLowerCase().contains(_selectedFilter.toLowerCase())
        )
    ).toList();
  }

  IconData _getServiceIcon(String category) {
    switch (category) {
      case 'Oil Change':
        return Icons.oil_barrel;
      case 'Tire Service':
        return Icons.tire_repair;
      case 'Brake Repair':
        return Icons.disc_full;
      case 'Engine Repair':
        return const IconData(0xe800, fontFamily: 'MyFlutterApp');
      case 'Battery Service':
        return Icons.battery_charging_full;
      case 'Transmission':
        return Icons.settings;
      default:
        return const IconData(0xe800, fontFamily: 'MyFlutterApp');
    }
  }

  void _getCurrentLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Getting your current location...',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showServiceCenterDetails(Map<String, dynamic> center) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                center['name'],
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < center['rating'].floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${center['rating']} (${center['reviews']} reviews)',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.location_on, center['address']),
              _buildDetailRow(Icons.phone, center['phone']),
              _buildDetailRow(Icons.access_time, center['isOpen'] ? 'Open Now' : 'Closed'),
                              _buildDetailRow(Icons.directions, '${center['distance']} km away'),
              const SizedBox(height: 20),
              const Text(
                'Services Offered',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (center['services'] as List<String>).map(
                  (service) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callServiceCenter(center),
                      icon: const Icon(Icons.phone),
                      label: const Text(
                        'Call Center',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToServiceCenter(center),
                      icon: const Icon(Icons.navigation),
                      label: const Text(
                        'Navigate',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callServiceCenter(Map<String, dynamic> center) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calling ${center['name']}...',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _navigateToServiceCenter(Map<String, dynamic> center) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening navigation to ${center['name']}...',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}