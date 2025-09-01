import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = false;
  String? _scannedData;
  Map<String, dynamic>? _partInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildScannerCard(),
                  const SizedBox(height: 24),
                  if (_partInfo != null) _buildPartInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (i) {}),
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
                    'Barcode Scanner',
                    style: TextStyle(
                      fontSize: 28,
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
                  'Part Details & Product Information',
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
                'How to Use Barcode Scanner',
                style: TextStyle(
                  fontSize: 16,
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
            'Choose Method',
            'Select between camera scanning for live barcodes or file import for existing barcode images.',
            Icons.qr_code_scanner,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Capture or Select',
            'Use camera to scan barcodes in real-time, or browse and select barcode images from your device.',
            Icons.folder_open,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Get Part Info',
            'The scanner will automatically decode the barcode and provide detailed part information and guides.',
            Icons.auto_awesome,
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

  Widget _buildScannerCard() {
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
            'Barcode Scanner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.5),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: AppTheme.primaryGreen,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose Your Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan with camera or import from files',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.7) : Colors.black54,
                          fontFamily: 'Orbitron',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Scanning frame overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryGreen,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Corner indicators
                Positioned(
                  top: 75,
                  left: 50,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        left: BorderSide(color: AppTheme.primaryGreen, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 75,
                  right: 50,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        right: BorderSide(color: AppTheme.primaryGreen, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 75,
                  left: 50,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        left: BorderSide(color: AppTheme.primaryGreen, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 75,
                  right: 50,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryGreen, width: 3),
                        right: BorderSide(color: AppTheme.primaryGreen, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Camera Scan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startCameraScan,
              icon: Icon(
                _isScanning ? Icons.stop : Icons.camera_alt,
                color: Colors.white,
              ),
              label: Text(
                _isScanning ? 'Scanning...' : 'Scan with Camera',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Import from Files Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _importFromFiles,
              icon: const Icon(
                Icons.folder_open,
                color: Colors.white,
              ),
              label: const Text(
                'Import from Files',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkAccentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Clear Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _partInfo == null ? null : _clearResults,
              icon: const Icon(
                Icons.clear,
                color: Colors.white,
              ),
              label: const Text(
                'Clear Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartInfoCard() {
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
                Icons.build,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Part Information',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Barcode', _partInfo!['barcode'] ?? 'N/A'),
                _buildInfoRow('Part Number', _partInfo!['partNumber'] ?? 'N/A'),
                _buildInfoRow('Part Name', _partInfo!['partName'] ?? 'N/A'),
                _buildInfoRow('Manufacturer', _partInfo!['manufacturer'] ?? 'N/A'),
                _buildInfoRow('Compatibility', _partInfo!['compatibility'] ?? 'N/A'),
                _buildInfoRow('Price Range', _partInfo!['priceRange'] ?? 'N/A'),
                _buildInfoRow('Warranty', _partInfo!['warranty'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installation Guide',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGreen,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _partInfo!['installationGuide'] ?? 'This part can be installed at home with basic tools. Follow the manufacturer\'s instructions for proper installation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.9) : Colors.black,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewInstallationGuide,
                  icon: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'View Guide',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _findNearbyStores,
                  icon: const Icon(
                    Icons.store,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Find Stores',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
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

  void _startCameraScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        // Simulate barcode processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Mock part data from camera
        setState(() {
          _partInfo = {
            'barcode': '1234567890123',
            'partNumber': 'TOY-2020-001',
            'partName': 'Oil Filter',
            'manufacturer': 'Toyota Genuine Parts',
            'compatibility': 'Toyota Camry 2018-2023',
            'priceRange': 'EGP 115 - EGP 225',
            'warranty': '12 months / 12,000 km',
            'installationGuide': 'This oil filter can be replaced during routine oil changes. Ensure the engine is cool and follow proper safety procedures.',
          };
          _isScanning = false;
        });

        HapticFeedback.lightImpact();
        _showMessage('Barcode scanned successfully from camera!');
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showMessage('Error accessing camera: $e');
    }
  }

  void _importFromFiles() async {
    setState(() {
      _isScanning = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null) {
        // Simulate barcode processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Mock part data from file
        setState(() {
          _partInfo = {
            'barcode': '9876543210987',
            'partNumber': 'HON-2019-002',
            'partName': 'Brake Pads',
            'manufacturer': 'Honda Genuine Parts',
            'compatibility': 'Honda Accord 2017-2022',
            'priceRange': 'EGP 180 - EGP 350',
            'warranty': '24 months / 24,000 km',
            'installationGuide': 'Brake pad replacement requires proper tools and safety equipment. Consider professional installation for optimal safety.',
          };
          _isScanning = false;
        });

        HapticFeedback.lightImpact();
        _showMessage('Barcode imported and processed successfully!');
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showMessage('Error importing file: $e');
    }
  }

  void _clearResults() {
    setState(() {
      _partInfo = null;
      _scannedData = null;
    });
    HapticFeedback.lightImpact();
  }

  void _viewInstallationGuide() {
    HapticFeedback.lightImpact();
    _showMessage('Opening installation guide...');
  }

  void _findNearbyStores() {
    HapticFeedback.lightImpact();
    _showMessage('Searching for nearby auto parts stores...');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
