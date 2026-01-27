import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/vin_decoder_service.dart';
import '../../../services/car_service.dart' as car_logic;
import '../../../shared/constants/app_theme.dart';
import '../../widgets/screen_with_nav_bar.dart';

class VinLookupScreen extends StatefulWidget {
  const VinLookupScreen({super.key});

  @override
  State<VinLookupScreen> createState() => _VinLookupScreenState();
}

class _VinLookupScreenState extends State<VinLookupScreen> {
  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _vehicleInfo;
  String _loadingMessage = 'Looking up VIN...';
  final VinDecoderService _vinService = VinDecoderService();
  final car_logic.CarService _carService = car_logic.CarService();

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionsCard(),
                  const SizedBox(height: 24),
                  _buildVinInputCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  const Text(
                          'VIN Lookup',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Vehicle Information & Maintenance Recommendations',
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

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'How to Use VIN Lookup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1',
            'Locate your VIN',
            'Find the 17-character VIN on your vehicle\'s dashboard, driver\'s door jamb, or registration documents.',
            Icons.search,
          ),
            const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Enter the VIN',
            'Type or paste the complete VIN into the input field below. Ensure all characters are correct.',
            Icons.edit,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Get vehicle details',
            'Receive comprehensive information about your vehicle including specifications, maintenance history, and recommendations.',
            Icons.directions_car
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: AppTheme.secondaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.8) : Colors.black54,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVinInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Vehicle Identification Number (VIN)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vinController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 17-character VIN',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.6) : Colors.black45,
                fontFamily: 'Orbitron',
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.backgroundGreen.withOpacity(0.3) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 17,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkAccentGreen,
                          AppTheme.backgroundGreen,
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _lookupVin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Lookup VIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.secondaryGreen : Colors.black,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _lookupVin() async {
    final vin = _vinController.text.trim();
    if (vin.length != 17) {
      _showMessage('Please enter a valid 17-character VIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Looking up VIN...';
    });

    try {
      final decoded = await _vinService.decodeVin(vin);
      setState(() {
        _vehicleInfo = {
          'vin': decoded.vin.isNotEmpty ? decoded.vin : vin,
          'make': decoded.make,
          'model': decoded.model,
          'year': int.tryParse(decoded.year) ?? DateTime.now().year,
          'engine': decoded.engine,
          'transmission': decoded.transmission,
          'bodyStyle': decoded.bodyStyle,
          'fuelType': decoded.fuelType,
        };
        _isLoading = false;
      });
      _showVehicleInfoDialog();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = e.toString();
      if (errorMessage.contains('429') || errorMessage.contains('Rate limit')) {
        errorMessage = 'Rate limit exceeded. Please wait 5-10 minutes before trying again.';
      } else if (errorMessage.contains('403')) {
        errorMessage = 'API access denied. Please check your API configuration.';
      } else if (errorMessage.contains('404')) {
        errorMessage = 'VIN not found. Please verify the VIN number is correct.';
      } else if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        errorMessage = 'Request timed out. Please check your internet connection and try again.';
      } else if (errorMessage.contains('failed after')) {
        errorMessage = 'VIN lookup service is temporarily unavailable. Please try again in a few minutes.';
      } else if (errorMessage.contains('Invalid response format')) {
        errorMessage = 'Unable to decode VIN information. Please verify the VIN is correct and try again.';
      }
      
      _showMessage(errorMessage);
    }
  }

  void _showVehicleInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(20),
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
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vehicle info content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Make', _vehicleInfo!['make'] ?? 'N/A'),
                        _buildInfoRow('Model', _vehicleInfo!['model'] ?? 'N/A'),
                        _buildInfoRow('Year', _vehicleInfo!['year']?.toString() ?? 'N/A'),
                        _buildInfoRow('Engine', _vehicleInfo!['engine'] ?? 'N/A'),
                        _buildInfoRow('Transmission', _vehicleInfo!['transmission'] ?? 'N/A'),
                        _buildInfoRow('Body Style', _vehicleInfo!['bodyStyle'] ?? 'N/A'),
                        _buildInfoRow('Fuel Type', _vehicleInfo!['fuelType'] ?? 'N/A'),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Maintenance Recommendations',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _vehicleInfo!['maintenanceTips'] ?? 'Based on your vehicle\'s specifications, we recommend regular maintenance checks every 6 months or 5,000 km.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.9) : Colors.black,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
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
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _saveVehicleToCars();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save to My Cars',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
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
        );
      },
    );
  }

  void _saveVehicleToCars() async {
    final info = _vehicleInfo;
    if (info == null) {
      _showMessage('No vehicle info to save');
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving vehicle...';
    });

    try {
      final vin = (info['vin'] ?? '').toString();
      
      // Check if car with this VIN already exists
      if (vin.isNotEmpty && vin != 'Not specified') {
        final existingCar = await _carService.getCarByVin(vin);
        if (existingCar != null) {
          setState(() => _isLoading = false);
          _showConfirmUpdateDialog(info, existingCar);
          return;
        }
      }

      // Generate a unique license plate placeholder if VIN exists
      String licensePlate = 'Not specified';
      if (vin.isNotEmpty && vin != 'Not specified') {
        // Use last 6 chars of VIN for unique placeholder
        licensePlate = 'VIN-${vin.substring(vin.length - 6)}';
      } else {
        // Use timestamp for unique placeholder
        licensePlate = 'VIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      }

      // Add the car
      final result = await _carService.addCar(
        brand: (info['make'] ?? 'Unknown').toString(),
        model: (info['model'] ?? 'Unknown').toString(),
        year: (info['year'] as int?) ?? DateTime.now().year,
        mileage: 0,
        color: 'Not specified',
        fuelType: (info['fuelType'] ?? 'Not specified').toString(),
        engineCC: (info['engine'] ?? 'Not specified').toString(),
        turbo: false,
        licensePlate: licensePlate,
        vin: vin.isNotEmpty ? vin : 'VIN-${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() => _isLoading = false);

      if (result.isSuccess) {
        _showSuccessDialog();
      } else {
        // Check if it's a duplicate error
        if (result.message.toLowerCase().contains('already exists') ||
            result.message.toLowerCase().contains('duplicate')) {
          _showMessage('This vehicle is already in your garage. Check "My Cars" to view it.');
        } else {
          _showMessage(result.message);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('already exists') ||
          errorMsg.toLowerCase().contains('duplicate')) {
        _showMessage('This vehicle is already in your garage. You can update it from "My Cars".');
      } else {
        _showMessage('Failed to save car: ${e.toString()}');
      }
    }
  }

  void _showConfirmUpdateDialog(Map<String, dynamic> newInfo, dynamic existingCar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vehicle Already Exists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'This vehicle is already in your garage:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.lightBackground.withOpacity(0.8) 
                      : Colors.black87,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${existingCar.brand} ${existingCar.model}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Year: ${existingCar.year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.lightBackground.withOpacity(0.8) 
                            : Colors.black87,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 16),
              Text(
                'You can view and manage this vehicle in "My Cars".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.lightBackground.withOpacity(0.8) 
                      : Colors.black87,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          actions: [
            Center(
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
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 40,
                ),
              ),
                  const SizedBox(height: 16),
              const Text(
                'Vehicle Saved!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          content: Text(
            'The vehicle has been successfully added to your garage. You can now view and manage it in "My Cars".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.lightBackground.withOpacity(0.8) 
                  : Colors.black87,
              fontFamily: 'Orbitron',
            ),
          ),
          actions: [
            Center(
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
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog only, stay on VIN Lookup screen
                    // Clear VIN field and reset state for new lookup
                    _vinController.clear();
                    setState(() {
                      _vehicleInfo = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
