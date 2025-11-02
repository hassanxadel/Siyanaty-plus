import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/services/location_service.dart';

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

// Service Center model
class ServiceCenter {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final String? phoneNumber;
  final bool isOpen;
  final List<String> types;

  ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.phoneNumber,
    this.isOpen = true,
    this.types = const [],
  });

  factory ServiceCenter.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return ServiceCenter(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Service Center',
      address: json['vicinity'] ?? json['formatted_address'] ?? 'No address',
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      phoneNumber: json['formatted_phone_number'],
      isOpen: json['opening_hours']?['open_now'] ?? true,
      types: List<String>.from(json['types'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'phoneNumber': phoneNumber,
      'isOpen': isOpen,
      'types': types,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }
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

  // Service Centers data
  List<ServiceCenter> _serviceCenters = [];
  List<ServiceCenter> _favoriteServiceCenters = [];

  // API Configuration - Using key from constants
  static const String _googlePlacesApiKey = AppConstants.googleMapsApiKey;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfEmulator();
    _loadFavorites();
    _getCurrentLocation();
    // Don't auto-fetch service centers - only when user clicks button
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
                            Tab(icon: Icon(Icons.location_on, size: 12), text: 'Centers'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(), // Disable swiping
                      children: [
                        _buildMapView(),
                        _buildFavoritesView(),
                        _buildCentersListView(),
                      ],
                    ),
                  ),
                  
                  // Nearby Centers button - positioned between map and nav bar
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.backgroundGreen,
                          AppTheme.primaryGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(2); // Switch to Centers tab
                        _fetchNearbyServiceCenters();
                      },
                      icon: const Icon(Icons.location_searching, color: Colors.white),
                      label: const Text(
                        'Find Nearby Centers',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
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
            // Disable lite mode to get full functionality
            liteModeEnabled: false,
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
    if (_favoriteServiceCenters.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteServiceCenters.length,
      itemBuilder: (context, index) {
        final center = _favoriteServiceCenters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkAccentGreen,
                  AppTheme.backgroundGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: InkWell(
            onTap: () => _showServiceCenterBottomSheet(center),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          center.name,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showRemoveFromFavoritesDialog(center),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          center.address,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (center.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${center.rating!.toStringAsFixed(1)} rating',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToServiceCenter(center),
                            icon: const Icon(Icons.directions, size: 16, color: Colors.white),
                            label: const Text(
                              'Navigate',
                              style: TextStyle(
                                fontFamily: 'Orbitron', 
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (center.phoneNumber != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callServiceCenter(center),
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text(
                              'Call',
                              style: TextStyle(fontFamily: 'Orbitron', fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildCentersListView() {
    if (_serviceCenters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 80,
              color: AppTheme.primaryGreen.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Service Centers Found',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.backgroundGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching from the Maps tab\nor check your location settings',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                color: AppTheme.darkAccentGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundGreen,
                    AppTheme.primaryGreen,
                    AppTheme.darkAccentGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(0); // Switch to Maps tab
                  _fetchNearbyServiceCenters();
                },
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  'Search for Centers',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _serviceCenters.length,
      itemBuilder: (context, index) {
        final center = _serviceCenters[index];
        final distance = _currentLocation != null 
            ? _calculateDistance(_currentLocation!, LatLng(center.lat, center.lng))
            : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkAccentGreen,
                  AppTheme.backgroundGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with name and favorite button
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          center.name,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _addToFavorites(center),
                        icon: Icon(
                          _isFavorite(center.id) ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite(center.id) ? Colors.red : AppTheme.darkAccentGreen,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Address
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: AppTheme.darkAccentGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          center.address,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rating and Distance Row
                  Row(
                    children: [
                      if (center.rating != null) ...[
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          center.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (distance != null) ...[
                        const Icon(
                          Icons.directions_walk,
                          color: AppTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.backgroundGreen,
                                AppTheme.primaryGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToServiceCenter(center),
                            icon: const Icon(Icons.directions, size: 16, color: Colors.white),
                            label: const Text(
                              'Navigate',
                              style: TextStyle(
                                fontFamily: 'Orbitron', 
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (center.phoneNumber != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue,
                                  Colors.blueAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _callServiceCenter(center),
                              icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                              label: const Text(
                                'Call',
                                style: TextStyle(
                                  fontFamily: 'Orbitron', 
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = start.latitude * (pi / 180);
    double lat2Rad = end.latitude * (pi / 180);
    double deltaLatRad = (end.latitude - start.latitude) * (pi / 180);
    double deltaLngRad = (end.longitude - start.longitude) * (pi / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  Widget _buildServiceCenterCard(Map<String, dynamic> center, {bool compact = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                              color: Colors.white,
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
                    color: Colors.white70,
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
                          color: Colors.white,
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
                          onPressed: () => _showOldServiceCenterCall(center),
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
                          onPressed: () => _showOldServiceCenterNavigation(center),
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
      
      // Check if this is the default emulator location (Google HQ)
      if (position.latitude == 37.4219983 && position.longitude == -122.084) {
        // Override with specific Cairo coordinates for testing
        setState(() {
          _currentLocation = const LatLng(29.973360, 31.259310); // Specific Cairo coordinates
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Emulator detected. Using your specified Cairo location.',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );
      }
      
      _updateMarkers();
      // Don't auto-fetch service centers - only when user clicks button
      
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        // Set a fallback location (Specific Cairo coordinates)
        _currentLocation = const LatLng(29.973360, 31.259310);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to get location. Using fallback location.\nError: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      _updateMarkers();
      // Don't auto-fetch service centers - only when user clicks button
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
    // Use the new service centers marker update method
    _updateMarkersWithServiceCenters();
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
                      onPressed: () => _showOldServiceCenterCall(center),
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
                      onPressed: () => _showOldServiceCenterNavigation(center),
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

  // Service Centers Functionality Methods

  /// Fetch nearby service centers using Google Places API
  Future<void> _fetchNearbyServiceCenters() async {
    if (_currentLocation == null) return;

    try {
      // Search for "service center" using Google Places API
      final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${_currentLocation!.latitude},${_currentLocation!.longitude}'
          '&radius=10000'
          '&keyword=service%20center'
          '&type=car_repair'
          '&key=$_googlePlacesApiKey';

      print('Searching for service centers at: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      print('API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Siyanaty Plus Mobile App',
          'Referer': 'https://siyanaty.app',
          'Accept': 'application/json',
        },
      );
      
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<ServiceCenter> centers = (data['results'] as List)
              .map((json) => ServiceCenter.fromJson(json))
              .toList();

          setState(() {
            _serviceCenters = centers;
          });

          _updateMarkersWithServiceCenters();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Found ${centers.length} service centers nearby',
                  style: const TextStyle(fontFamily: 'Orbitron'),
                ),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        } else if (data['status'] == 'REQUEST_DENIED') {
          throw Exception('API Key issue: ${data['error_message'] ?? 'Please check your Google Cloud Console settings'}');
        } else if (data['status'] == 'ZERO_RESULTS') {
          // Try a broader search with different keywords
          await _searchWithAlternativeKeywords();
        } else {
          throw Exception('Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching service centers: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to load service centers';
        if (e.toString().contains('REQUEST_DENIED')) {
          errorMessage = 'API Key Error: Please check Google Cloud Console settings';
        } else if (e.toString().contains('ZERO_RESULTS')) {
          errorMessage = 'No service centers found in this area';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _fetchNearbyServiceCenters(),
            ),
          ),
        );
      }
    }
  }

  /// Try alternative search keywords if no results found
  Future<void> _searchWithAlternativeKeywords() async {
    if (_currentLocation == null) return;

    final List<String> keywords = [
      'car%20repair',
      'auto%20service',
      'garage',
      'automotive%20service',
      'car%20maintenance'
    ];

    for (String keyword in keywords) {
      try {
        final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=${_currentLocation!.latitude},${_currentLocation!.longitude}'
            '&radius=15000'
            '&keyword=$keyword'
            '&type=car_repair'
            '&key=$_googlePlacesApiKey';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Siyanaty Plus Mobile App',
            'Referer': 'https://siyanaty.app',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final List<ServiceCenter> centers = (data['results'] as List)
                .map((json) => ServiceCenter.fromJson(json))
                .toList();

            setState(() {
              _serviceCenters = centers;
            });

            _updateMarkersWithServiceCenters();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Found ${centers.length} automotive services nearby',
                    style: const TextStyle(fontFamily: 'Orbitron'),
                  ),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            }
            return; // Exit after finding results
          }
        }
      } catch (e) {
        print('Alternative search failed for keyword: $keyword');
        continue;
      }
    }

    // If no results found with any keyword
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No service centers found in this area. Try expanding search radius.',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  /// Update map markers with service centers
  void _updateMarkersWithServiceCenters() {
    final Set<Marker> markers = {};

    // Add user location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add service center markers
    for (final center in _serviceCenters) {
      markers.add(
        Marker(
          markerId: MarkerId(center.id),
          position: LatLng(center.lat, center.lng),
          infoWindow: InfoWindow(
            title: center.name,
            snippet: center.address,
            onTap: () => _showServiceCenterBottomSheet(center),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showServiceCenterBottomSheet(center),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    print('Google Maps: Updated markers - ${markers.length} total');
  }

  /// Show service center details in bottom sheet
  void _showServiceCenterBottomSheet(ServiceCenter center) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.build,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            center.name,
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.backgroundGreen,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Details
                    _buildServiceCenterDetail(Icons.location_on, center.address),
                    
                    if (center.rating != null)
                      _buildServiceCenterDetail(
                        Icons.star,
                        '${center.rating!.toStringAsFixed(1)} rating',
                      ),
                    
                    if (center.phoneNumber != null)
                      _buildServiceCenterDetail(Icons.phone, center.phoneNumber!),
                    
                    _buildServiceCenterDetail(
                      center.isOpen ? Icons.schedule : Icons.schedule_outlined,
                      center.isOpen ? 'Open now' : 'Closed',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addToFavorites(center),
                            icon: Icon(
                              _isFavorite(center.id) ? Icons.favorite : Icons.favorite_border,
                            ),
                            label: Text(
                              _isFavorite(center.id) ? 'Favorited' : 'Add to Favorites',
                              style: const TextStyle(fontFamily: 'Orbitron'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFavorite(center.id) 
                                  ? Colors.red 
                                  : AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToServiceCenter(center),
                            icon: const Icon(Icons.directions),
                            label: const Text(
                              'Navigate',
                              style: TextStyle(fontFamily: 'Orbitron'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkAccentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    if (center.phoneNumber != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _callServiceCenter(center),
                          icon: const Icon(Icons.phone),
                          label: const Text(
                            'Call Service Center',
                            style: TextStyle(fontFamily: 'Orbitron'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCenterDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                color: AppTheme.backgroundGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add or remove service center from favorites
  Future<void> _addToFavorites(ServiceCenter center) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in to save favorites',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final favoritesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorite_service_centers');

      if (_isFavorite(center.id)) {
        // Remove from favorites
        await favoritesRef.doc(center.id).delete();
        setState(() {
          _favoriteServiceCenters.removeWhere((c) => c.id == center.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Removed from favorites',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Add to favorites
        await favoritesRef.doc(center.id).set(center.toFirestore());
        setState(() {
          _favoriteServiceCenters.add(center);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Added to favorites ✅',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      print('Error managing favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update favorites: $e',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if service center is in favorites
  bool _isFavorite(String centerId) {
    return _favoriteServiceCenters.any((center) => center.id == centerId);
  }

  /// Navigate to service center using Google Maps
  Future<void> _navigateToServiceCenter(ServiceCenter center) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${center.lat},${center.lng}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to open navigation: $e',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Call service center
  Future<void> _callServiceCenter(ServiceCenter center) async {
    if (center.phoneNumber == null) return;
    
    final url = 'tel:${center.phoneNumber}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Could not make phone call');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to make call: $e',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load user's favorite service centers
  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorite_service_centers')
          .get();

      final favorites = favoritesSnapshot.docs.map((doc) {
        final data = doc.data();
        return ServiceCenter(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? 'Unknown',
          address: data['address'] ?? 'No address',
          lat: (data['lat'] as num).toDouble(),
          lng: (data['lng'] as num).toDouble(),
          rating: (data['rating'] as num?)?.toDouble(),
          phoneNumber: data['phoneNumber'],
          isOpen: data['isOpen'] ?? true,
          types: List<String>.from(data['types'] ?? []),
        );
      }).toList();

      setState(() {
        _favoriteServiceCenters = favorites;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  /// Helper methods for old service center format (Map<String, dynamic>)
  void _showOldServiceCenterCall(Map<String, dynamic> center) {
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

  void _showOldServiceCenterNavigation(Map<String, dynamic> center) {
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

  void _showRemoveFromFavoritesDialog(ServiceCenter center) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Remove from Favorites',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to remove "${center.name}" from your favorites?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _addToFavorites(center); // This will remove it since it's already favorited
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}