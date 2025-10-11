import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/location_service.dart';

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends State<ServiceCentersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Google Maps related
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  MapType _currentMapType = MapType.normal;
  bool _mapLoadFailed = false;
  bool _isMapLoading = true;
  Timer? _mapLoadingTimer;
  bool _isEmulator = false;
  int _mapRefreshAttempts = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfEmulator();
    _getCurrentLocation();
  }

  void _checkIfEmulator() {
    // Check if running on emulator
    _isEmulator = true; // Assume emulator for now, can be enhanced with platform detection
    print('Google Maps: Running on emulator: $_isEmulator');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapLoadingTimer?.cancel();
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
                            Tab(icon: Icon(Icons.map, size: 12), text: 'Maps'),
                            Tab(icon: Icon(Icons.favorite, size: 12), text: 'Favorites'),
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
                        _buildFavoritesView(),
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


  Widget _buildMapView() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your location...',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.backgroundGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enable location services to\nview nearby service centers',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                color: AppTheme.darkAccentGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Google Maps with enhanced error handling
        Container(
          color: Colors.grey[200], // Fallback background
          child: _mapLoadFailed ? 
            // Show fallback UI when map fails to load
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map Loading Issue',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load Google Maps.\nThis may be due to network issues or emulator limitations.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _mapLoadFailed = false;
                        _isMapLoading = true;
                        _mapRefreshAttempts = 0;
                      });
                      _getCurrentLocation();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Retry Map',
                      style: TextStyle(fontFamily: 'Orbitron'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ) :
            GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              print('Google Maps: Map created successfully');
              _mapController = controller;
              
              // Start loading timeout
              _startMapLoadingTimeout();
              
              // Add a delay to ensure map is fully loaded before adding markers
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) {
                  _updateMarkers();
                  _onMapLoaded(); // Mark map as loaded
                }
              });
              
              // For emulators, try additional refresh attempts
              if (_isEmulator) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (_isMapLoading && mounted) {
                    print('Google Maps: Emulator - attempting first refresh');
                    _forceMapRefresh();
                  }
                });
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14.0, // Slightly reduced zoom for better loading
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
            onTap: (LatLng position) {
              print('Google Maps: Map tapped at ${position.latitude}, ${position.longitude}');
              // Hide any open info windows by rebuilding markers
              if (mounted) {
                setState(() {
                  _updateMarkers();
                });
              }
            },
            onCameraMove: (CameraPosition position) {
              // Optional: Handle camera movement
            },
            onCameraIdle: () {
              // Map is idle, can perform operations
              if (_isMapLoading) {
                _onMapLoaded();
              }
            },
            // Enhanced properties for better emulator compatibility
            compassEnabled: true,
            mapToolbarEnabled: false,
            buildingsEnabled: false, // Disable for better performance
            trafficEnabled: false,
            zoomControlsEnabled: false, // Disable default controls
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: false, // Disable for better emulator performance
            rotateGesturesEnabled: false, // Disable for better emulator performance
            // Use lite mode for better emulator compatibility
            liteModeEnabled: _isEmulator,
          ),
        ),
        
        // Current location button
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _goToCurrentLocation,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.my_location),
          ),
        ),
        
        // Debug info overlay (temporary)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Location: ${_currentLocation?.latitude.toStringAsFixed(4)}, ${_currentLocation?.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
        
        // Map type switcher button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _switchMapType,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.layers),
          ),
        ),
        
        // Map loading indicator
        if (_isMapLoading && !_mapLoadFailed)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading map...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Fallback message if map fails to load
        if (_mapLoadFailed)
          Container(
            color: Colors.black87,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Map Loading Issue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is common in emulators. Try switching map type or use a physical device.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mapLoadFailed = false;
                                  _isMapLoading = true;
                                  _mapRefreshAttempts = 0;
                                  _switchMapType();
                                });
                              },
                              icon: const Icon(Icons.layers),
                              label: const Text('Switch Map Type'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mapLoadFailed = false;
                                  _isMapLoading = true;
                                  _mapRefreshAttempts = 0;
                                });
                                _getCurrentLocation();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isEmulator)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _mapLoadFailed = false;
                                _isMapLoading = true;
                                _mapRefreshAttempts = 0;
                                _currentMapType = MapType.satellite;
                              });
                              _forceMapRefresh();
                            },
                            icon: const Icon(Icons.satellite),
                            label: const Text('Force Satellite View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.backgroundGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap on service center markers\non the map to add them to favorites',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: AppTheme.darkAccentGreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  List<Map<String, dynamic>> _getServiceCenters() {
    return [
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
        'coordinates': const LatLng(40.7128, -74.0060), // NYC coordinates
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
        'coordinates': const LatLng(40.7589, -73.9851), // NYC coordinates
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
        'coordinates': const LatLng(40.7505, -73.9934), // NYC coordinates
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
        'coordinates': const LatLng(40.7614, -73.9776), // NYC coordinates
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
        'coordinates': const LatLng(40.7282, -74.0776), // NYC coordinates
      },
    ];
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      print('Google Maps: Location found at ${position.latitude}, ${position.longitude}');
      _updateMarkers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location found!',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to get location: $e',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  void _updateMarkers() {
    final serviceCenters = _getServiceCenters();
    print('Google Maps: Updating markers for ${serviceCenters.length} service centers');
    _markers = serviceCenters.map((center) {
      final coordinates = center['coordinates'] as LatLng;
      print('Google Maps: Adding marker for ${center['name']} at ${coordinates.latitude}, ${coordinates.longitude}');
      return Marker(
        markerId: MarkerId(center['name']),
        position: coordinates,
        infoWindow: InfoWindow(
          title: center['name'],
          snippet: '${center['rating']} ⭐ • ${center['distance']} mi away',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(center['category']),
        ),
        onTap: () {
          print('Google Maps: Marker tapped for ${center['name']}');
          // Show service center details
          _showServiceCenterDetails(center);
        },
      );
    }).toSet();
    print('Google Maps: Total markers created: ${_markers.length}');
  }

  double _getMarkerColor(String category) {
    switch (category) {
      case 'Oil Change':
        return BitmapDescriptor.hueBlue;
      case 'Tire Service':
        return BitmapDescriptor.hueOrange;
      case 'Brake Repair':
        return BitmapDescriptor.hueRed;
      case 'Engine Repair':
        return BitmapDescriptor.hueGreen;
      case 'Battery Service':
        return BitmapDescriptor.hueYellow;
      case 'Transmission':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueBlue;
    }
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

  void _switchMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _currentMapType = MapType.terrain;
          break;
        case MapType.terrain:
          _currentMapType = MapType.normal;
          break;
        case MapType.none:
          _currentMapType = MapType.normal;
          break;
      }
      _isMapLoading = true;
      _mapLoadFailed = false;
    });
    print('Google Maps: Switched to map type: $_currentMapType');
    _startMapLoadingTimeout();
  }

  void _startMapLoadingTimeout() {
    _mapLoadingTimer?.cancel();
    // Shorter timeout for emulators
    final timeout = _isEmulator ? const Duration(seconds: 5) : const Duration(seconds: 10);
    
    _mapLoadingTimer = Timer(timeout, () {
      if (_isMapLoading) {
        if (_isEmulator && _mapRefreshAttempts < 3) {
          // Try to refresh map for emulators
          _mapRefreshAttempts++;
          print('Google Maps: Emulator timeout - attempting refresh #$_mapRefreshAttempts');
          _forceMapRefresh();
        } else {
          setState(() {
            _isMapLoading = false;
            _mapLoadFailed = true;
          });
          print('Google Maps: Map loading timeout - showing fallback UI');
        }
      }
    });
  }

  void _forceMapRefresh() {
    if (_mapController != null && _currentLocation != null) {
      // Force camera update to trigger map refresh
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 15.0,
          ),
        ),
      );
      
      // Try different map type
      if (_mapRefreshAttempts == 2) {
        setState(() {
          _currentMapType = MapType.satellite;
        });
        print('Google Maps: Switching to satellite view for emulator');
      }
      
      // Restart timeout
      _startMapLoadingTimeout();
    }
  }

  void _onMapLoaded() {
    _mapLoadingTimer?.cancel();
    setState(() {
      _isMapLoading = false;
      _mapLoadFailed = false;
    });
    print('Google Maps: Map loaded successfully');
  }
}