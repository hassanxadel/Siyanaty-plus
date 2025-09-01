import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../../domain/entities/car.dart';
import 'package:image_picker/image_picker.dart';


class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final List<Car> _cars = [
    Car(
      id: '1',
      userId: 'user1',
      name: 'Toyota Camry',
      make: 'Toyota',
      model: 'Camry',
      year: 2020,
      color: 'White',
      engine: '2.5L 4-Cylinder',
      transmission: 'Automatic',
      fuelType: 'Gasoline',
      currentMileage: 45230,
      licensePlate: 'ABC-123',
      lastServiceDate: DateTime(2024, 12, 15),
      health: CarHealth.initial(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Car(
      id: '2',
      userId: 'user1',
      name: 'Honda Civic',
      make: 'Honda',
      model: 'Civic',
      year: 2018,
      color: 'Black',
      engine: '1.5L Turbo',
      transmission: 'CVT',
      fuelType: 'Gasoline',
      currentMileage: 62150,
      licensePlate: 'XYZ-789',
      lastServiceDate: DateTime(2024, 11, 10),
      health: CarHealth(
        overallScore: 72.0,
        engine: ComponentHealth.good(),
        brakes: ComponentHealth.warning(),
        battery: ComponentHealth.good(),
        tires: ComponentHealth.good(),
        fluids: ComponentHealth.warning(),
        lastUpdated: DateTime.now(),
        warnings: ['Brake pads wear'],
        recommendations: ['Schedule brake inspection'],
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];



  void _navigateToCarDetails(Car car) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening details for ${car.displayName}'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'My Cars',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // TODO: Implement search
                    },
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Manage your vehicle fleet hassan',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          // Header with gradient background
          _buildHeaderWithBackground(),
          
          // Content
          Expanded(
            child: _cars.isEmpty ? _buildEmptyState() : _buildCarsList(),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showAddCarSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Car', style: TextStyle(fontFamily: 'Orbitron')), 
            ),
          ),
        ),
          ),
          BottomNavBar(
            currentIndex: 0,
            onTap: (int i) {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                     Container(
            width: 190,
            height: 60,
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.05),
               borderRadius: BorderRadius.circular(20),
             ),
             child: Icon(
               const IconData(0xe800, fontFamily: 'MyFlutterApp'),
               size: 100,
               color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.3),
             ),
           ),
          const SizedBox(height: 24),
          Text(
            'No cars added yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getThemeAwareTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first car to start tracking\nmaintenance and services',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddCarDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Car'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _cars.length,
      itemBuilder: (context, index) {
        final car = _cars[index];
        return _buildCarCard(car, index);
      },
    );
  }

  Widget _buildCarCard(Car car, int index) {
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
                                         child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: AppTheme.primaryGreen.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: const Icon(
                         IconData(0xe800, fontFamily: 'MyFlutterApp'),
                         color: AppTheme.primaryGreen,
                         size: 30,
                       ),
                     ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${car.currentMileage.toStringAsFixed(0)} km',
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
                      color: AppTheme.getHealthColor(car.healthPercentage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${car.healthPercentage.toInt()}%',
                      style: TextStyle(
                        color: AppTheme.getHealthColor(car.healthPercentage),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Health indicators
              Row(
                children: [
                  _buildHealthIndicator('Engine', car.health.engine.status == HealthStatus.good),
                  _buildHealthIndicator('Brakes', car.health.brakes.status == HealthStatus.good),
                  _buildHealthIndicator('Battery', car.health.battery.status == HealthStatus.good),
                  _buildHealthIndicator('Tires', car.health.tires.status == HealthStatus.good),
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

  Widget _buildHealthIndicator(String label, bool isGood) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isGood ? AppTheme.goodHealth : AppTheme.warningHealth,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGood ? Icons.check : Icons.warning,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddCarDialog() {
    _showAddCarSheet();
  }

  void _showAddCarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Brand', onChanged: (v) => make = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Model', onChanged: (v) => model = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Year', keyboard: TextInputType.number, onChanged: (v) => year = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Mileage', keyboard: TextInputType.number, onChanged: (v) => mileage = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Color', onChanged: (v) => color = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Fuel Type', onChanged: (v) => fuelType = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Engine CC', keyboard: TextInputType.number, onChanged: (v) => engineCc = v)),
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
                    Expanded(child: _field(label: 'License Plate', onChanged: (v) => license = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'VIN', onChanged: (v) => vin = v)),
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
                  child: ElevatedButton(
                    onPressed: () {
                      if (make.isEmpty || model.isEmpty || year.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      final car = Car(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: 'user1',
                        name: '$year $make $model',
                        make: make,
                        model: model,
                        year: int.tryParse(year) ?? DateTime.now().year,
                        color: color.isEmpty ? 'Unknown' : color,
                        engine: engineCc.isEmpty ? 'Unknown' : '${engineCc}cc ${turbo ? 'Turbo' : 'NA'}',
                        transmission: 'Unknown',
                        fuelType: fuelType.isEmpty ? 'Unknown' : fuelType,
                        currentMileage: double.tryParse(mileage) ?? 0,
                        licensePlate: license.isEmpty ? null : license,
                        vin: vin.isEmpty ? null : vin,
                        imageUrl: imagePath.isEmpty ? null : imagePath,
                        lastServiceDate: null,
                        health: CarHealth.initial(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      setState(() {
                        _cars.add(car);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field({required String label, TextInputType keyboard = TextInputType.text, required ValueChanged<String> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: label,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkModeCardBackground : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
} 