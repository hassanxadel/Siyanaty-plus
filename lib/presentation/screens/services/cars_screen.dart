import 'dart:io';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../../services/car_service.dart';
import '../../../models/backup_car.dart';
import 'package:image_picker/image_picker.dart';


class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final CarService _carService = CarService();
  List<BackupCar> _cars = [];
  List<BackupCar> _filteredCars = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    try {
      final cars = await _carService.getAllCars();
      setState(() {
        _cars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cars: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCars = _cars;
      } else {
        _filteredCars = _cars.where((car) {
          final searchLower = _searchQuery.toLowerCase();
          return car.brand.toLowerCase().contains(searchLower) ||
                 car.model.toLowerCase().contains(searchLower) ||
                 car.year.toString().contains(searchLower) ||
                 (car.licensePlate.toLowerCase().contains(searchLower)) ||
                 (car.vin.toLowerCase().contains(searchLower)) ||
                 (car.color.toLowerCase().contains(searchLower));
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _applyFilters();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _navigateToCarDetails(BackupCar car) {
    showDialog(
      context: context,
      builder: (context) => CarDetailsDialog(
        car: car,
        onEdit: () => _showEditCarDialog(car),
        onDelete: () => _deleteCar(car),
      ),
    );
  }

  void _showEditCarDialog(BackupCar car) {
    Navigator.pop(context); // Close details dialog first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditCarForm(
        car: car,
        onCarUpdated: _loadCars,
      ),
    );
  }

  Future<void> _deleteCar(BackupCar car) async {
    Navigator.pop(context); // Close details dialog first
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.year} ${car.brand} ${car.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await _carService.deleteCar(car.id!);
        if (result.isSuccess) {
          await _loadCars();
          if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
                content: Text(result.message),
        backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting car: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      height: 240,
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'My Cars',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: _toggleSearch,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      'Manage your vehicle ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Add Car button in header
                    Container(
                      width: 180,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.darkAccentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showAddCarSheet,
                          borderRadius: BorderRadius.circular(28),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add Car',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          // Header with gradient background
          _buildHeaderWithBackground(),
          if (_isSearching) _buildSearchBar(),
          
          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
              : _filteredCars.isEmpty 
                ? _buildEmptyState() 
                : _buildCarsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (int i) {},
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;
    return RefreshIndicator(
      onRefresh: _loadCars,
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400, // Give enough height for pull-to-refresh
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 235,
                  height: 130,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isSearching ? Icons.search_off : const IconData(0xe800, fontFamily: 'MyFlutterApp'),
                    size: 75,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isSearching ? 'No cars found' : 'No cars added yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getThemeAwareTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSearching 
                      ? 'Try adjusting your search terms\nor clear the search to see all cars'
                      : 'Add your first car to start tracking\nmaintenance and services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search cars by brand, model, year...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Orbitron',
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontFamily: 'Orbitron'),
      ),
    );
  }

  Widget _buildCarsList() {
    return RefreshIndicator(
      onRefresh: _loadCars,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredCars.length,
        itemBuilder: (context, index) {
          final car = _filteredCars[index];
          return _buildCarCard(car, index);
        },
      ),
    );
  }

  Widget _buildCarCard(BackupCar car, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToCarDetails(car),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: car.imagePath != null && car.imagePath!.isNotEmpty
                          ? Image.file(
                              File(car.imagePath!),
                              width: 90,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                       padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                    color: AppTheme.primaryGreen,
                                    size: 30,
                                  ),
                                );
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                       child: const Icon(
                         IconData(0xe800, fontFamily: 'MyFlutterApp'),
                         color: AppTheme.primaryGreen,
                         size: 30,
                              ),
                       ),
                     ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${car.year} ${car.brand} ${car.model}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${car.mileage} km',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car.licensePlate,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Car details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem('Color', car.color),
                  ),
                  Expanded(
                    child: _buildDetailItem('Fuel', car.fuelType),
                  ),
                  Expanded(
                    child: _buildDetailItem('Engine', car.engineCC),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      
                      onPressed: () => _navigateToCarDetails(car),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                     Expanded(
                     child: ElevatedButton(
                       onPressed: () {
                       // TODO: Add maintenance
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryGreen,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                       ),
                       child: const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             IconData(0xe800, fontFamily: 'MyFlutterApp'),
                             size: 16,
                             
                           ),
                           SizedBox(width: 35),
                           Text(
                             'Service',
                             style: TextStyle(fontSize: 16),
                           ),
                         ],
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

  Widget _buildDetailItem(String label, String value) {
    return Column(
        children: [
          Text(
            label,
            style: TextStyle(
            fontSize: 12,
              color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }


  void _showAddCarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCarForm(onCarAdded: _loadCars),
    );
  }
}

class CarDetailsDialog extends StatelessWidget {
  final BackupCar car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CarDetailsDialog({
    super.key,
    required this.car,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with car image
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: car.imagePath != null && car.imagePath!.isNotEmpty
                        ? Image.file(
                            File(car.imagePath!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                color: AppTheme.primaryGreen,
                                size: 40,
                              );
                            },
                          )
                        : const Icon(
                            IconData(0xe800, fontFamily: 'MyFlutterApp'),
                            color: AppTheme.primaryGreen,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.year} ${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          car.licensePlate,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Car details
            _buildDetailRow('Mileage', '${car.mileage} km'),
            _buildDetailRow('Color', car.color),
            _buildDetailRow('Fuel Type', car.fuelType),
            _buildDetailRow('Engine', car.engineCC + (car.turbo ? ' Turbo' : '')),
            _buildDetailRow('VIN', car.vin),
            _buildDetailRow('Added', _formatDate(car.createdAt)),
            if (car.updatedAt != car.createdAt)
              _buildDetailRow('Last Updated', _formatDate(car.updatedAt)),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class EditCarForm extends StatefulWidget {
  final BackupCar car;
  final VoidCallback onCarUpdated;
  
  const EditCarForm({super.key, required this.car, required this.onCarUpdated});
  
  @override
  State<EditCarForm> createState() => _EditCarFormState();
}

class _EditCarFormState extends State<EditCarForm> {
  final CarService _carService = CarService();
  late String make;
  late String model;
  late String year;
  late String mileage;
  late String color;
  late String fuelType;
  late String engineCc;
  late bool turbo;
  late String license;
  late String vin;
  late String imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current car data
    make = widget.car.brand;
    model = widget.car.model;
    year = widget.car.year.toString();
    mileage = widget.car.mileage.toString();
    color = widget.car.color;
    fuelType = widget.car.fuelType;
    engineCc = widget.car.engineCC;
    turbo = widget.car.turbo;
    license = widget.car.licensePlate;
    vin = widget.car.vin;
    imagePath = widget.car.imagePath ?? '';
  }

  @override
  Widget build(BuildContext context) {
        final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Edit Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Brand*', initialValue: make, onChanged: (v) => make = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Model*', initialValue: model, onChanged: (v) => model = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Year (optional)', initialValue: year, keyboard: TextInputType.number, onChanged: (v) => year = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Mileage (optional)', initialValue: mileage, keyboard: TextInputType.number, onChanged: (v) => mileage = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Color (optional)', initialValue: color, onChanged: (v) => color = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Fuel Type (optional)', initialValue: fuelType, onChanged: (v) => fuelType = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Engine CC (optional)', initialValue: engineCc, keyboard: TextInputType.number, onChanged: (v) => engineCc = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text('Turbo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Switch(
                        value: turbo,
                        onChanged: (v) {
                          setState(() { turbo = v; });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'License Plate (optional)', initialValue: license, onChanged: (v) => license = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'VIN (optional)', initialValue: vin, onChanged: (v) => vin = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    imagePath.isEmpty ? 'No image selected' : 'Image selected: ${imagePath.split('/').last}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      setState(() {
                        imagePath = picked.path;
                      });
                    }
                  },
                  icon: const Icon(Icons.photo),
                  label: const Text('Pick Image', style: TextStyle(fontFamily: 'Orbitron')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  // Only require brand and model as minimum
                  if (make.isEmpty || model.isEmpty) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in at least Brand and Model'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    // Update car using CarService
                    final result = await _carService.updateCar(
                      id: widget.car.id!,
                      brand: make,
                      model: model,
                      year: int.tryParse(year) ?? DateTime.now().year,
                      mileage: int.tryParse(mileage) ?? 0,
                      color: color.isEmpty ? 'Not specified' : color,
                      fuelType: fuelType.isEmpty ? 'Not specified' : fuelType,
                      engineCC: engineCc.isEmpty ? 'Not specified' : engineCc,
                      turbo: turbo,
                      licensePlate: license.isEmpty ? 'Not specified' : license,
                      vin: vin.isEmpty ? 'VIN${DateTime.now().millisecondsSinceEpoch}' : vin,
                      imagePath: imagePath.isEmpty ? null : imagePath,
                    );
                    
                    Navigator.pop(context);
                    
                    if (result.isSuccess) {
                      // Call the callback to reload cars list
                      widget.onCarUpdated();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating car: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    TextInputType? keyboard,
    required Function(String) onChanged,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class AddCarForm extends StatefulWidget {
  final VoidCallback onCarAdded;
  
  const AddCarForm({super.key, required this.onCarAdded});
  
  @override
  State<AddCarForm> createState() => _AddCarFormState();
}

class _AddCarFormState extends State<AddCarForm> {
  final CarService _carService = CarService();
        String make = '';
        String model = '';
        String year = '';
        String mileage = '';
        String color = '';
        String fuelType = '';
        String engineCc = '';
        bool turbo = false;
        String license = '';
        String vin = '';
        String imagePath = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: media.viewInsets.bottom + 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Add New Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 8),
                Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Brand*', onChanged: (v) => make = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Model*', onChanged: (v) => model = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Year (optional)', keyboard: TextInputType.number, onChanged: (v) => year = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Mileage (optional)', keyboard: TextInputType.number, onChanged: (v) => mileage = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Color (optional)', onChanged: (v) => color = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Fuel Type (optional)', onChanged: (v) => fuelType = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Engine CC (optional)', keyboard: TextInputType.number, onChanged: (v) => engineCc = v)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Turbo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Switch(
                            value: turbo,
                            onChanged: (v) {
                              setState(() { turbo = v; });
                            },
                            activeColor: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'License Plate (optional)', onChanged: (v) => license = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'VIN (optional)', onChanged: (v) => vin = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        imagePath.isEmpty ? 'No image selected' : imagePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (picked != null) {
                          setState(() {
                            imagePath = picked.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo),
                      label: const Text('Pick Image', style: TextStyle(fontFamily: 'Orbitron')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      // Only require brand and model as minimum
                      if (make.isEmpty || model.isEmpty) {
                        setState(() {
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in at least Brand and Model'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        // Save to backup system using CarService
                        final result = await _carService.addCar(
                          brand: make,
                        model: model,
                        year: int.tryParse(year) ?? DateTime.now().year,
                          mileage: int.tryParse(mileage) ?? 0,
                          color: color.isEmpty ? 'Not specified' : color,
                          fuelType: fuelType.isEmpty ? 'Not specified' : fuelType,
                          engineCC: engineCc.isEmpty ? 'Not specified' : engineCc,
                          turbo: turbo,
                          licensePlate: license.isEmpty ? 'Not specified' : license,
                          vin: vin.isEmpty ? 'VIN${DateTime.now().millisecondsSinceEpoch}' : vin,
                          imagePath: imagePath.isEmpty ? null : imagePath,
                        );
                        
                        Navigator.pop(context);
                        
                        if (result.isSuccess) {
                          // Call the callback to reload cars list
                          widget.onCarAdded();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding car: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                      setState(() {
                            _isLoading = false;
                      });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
  }

  Widget _field({
    required String label,
    TextInputType? keyboard,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboard,
          onChanged: onChanged,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

} 