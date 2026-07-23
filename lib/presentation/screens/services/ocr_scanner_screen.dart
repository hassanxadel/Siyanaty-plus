import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/ocr_service.dart';
import '../../../services/car_service.dart';
import 'ocr_review_screen.dart';
import 'ocr_history_screen.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _documentNameController = TextEditingController();
  bool _isProcessing = false;
  String? _lastImagePath;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  String? _selectedCarId;
  List<dynamic> _cars = [];

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final carService = CarService();
      final cars = await carService.getAllCars();
      if (mounted) {
                        setState(() {
                          _cars = cars;
                          if (_cars.isNotEmpty) {
                            _selectedCarId = _cars.first.id.toString();
                          }
                        });
      }
    } catch (e) {
      print('Error loading cars: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _documentNameController.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      showNavBar: !_showCamera,
      child: Scaffold(
        body: _showCamera && _isCameraInitialized
            ? _buildCameraPreview()
          : Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildMainInterface(),
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
                          'OCR Scanner',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OcrHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Scan documents and extract text using AI',
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

  Widget _buildMainInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show either the "Scan Documents" header or the uploaded image
          if (_lastImagePath == null) ...[
            // Header - only show when no image is uploaded
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkAccentGreen,
                    AppTheme.backgroundGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scan Documents',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Capture or select an image to extract text using AI',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ] else ...[
            // Show uploaded image when available
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(_lastImagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Image info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkAccentGreen,
                    AppTheme.backgroundGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Image ready for processing',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _lastImagePath = null;
                      });
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Document name and car selection
            _buildTextField(
              controller: _documentNameController,
              hintText: 'Document Name (e.g., Insurance Card)',
              icon: Icons.description,
            ),
            const SizedBox(height: 12),
            _buildCarDropdown(),
            const SizedBox(height: 20),
          ],
          
          // Action buttons
          _buildActionButton(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Use camera to capture document',
            onTap: _showCamera ? null : _captureFromCamera,
            isEnabled: !_isProcessing && _isCameraInitialized,
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            subtitle: 'Select existing image from gallery',
            onTap: _pickFromGallery,
            isEnabled: !_isProcessing,
          ),
          
          const SizedBox(height: 30),
          
          // Process button - only show when image is available
          if (_lastImagePath != null) ...[
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
                onPressed: _isProcessing ? null : () => _processImage(_lastImagePath!),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Extract Text with AI',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        
        // Camera controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Back button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showCamera = false;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                // Capture button
                GestureDetector(
                  onTap: _isProcessing ? null : _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _isProcessing ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 3,
                      ),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: AppTheme.primaryGreen,
                            size: 30,
                          ),
                  ),
                ),
                
                // Gallery button
                IconButton(
                  onPressed: _isProcessing ? null : _pickFromGallery,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isEnabled ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.darkAccentGreen,
            ],
          ) : null,
          color: isEnabled ? null : AppTheme.darkAccentGreen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isEnabled ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.darkAccentGreen,
                  ],
                ) : null,
                color: isEnabled ? null : Colors.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : Colors.grey[400],
                    ),
                  ),
                    const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: isEnabled ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? Colors.white : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _ocrService.captureImageFromCamera();
      if (image != null) {
        final String savedPath = await _ocrService.saveImageToAppDirectory(image);
        setState(() {
          _lastImagePath = savedPath;
        });
        await _processImage(savedPath);
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_isProcessing || _cameraController == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final String savedPath = await _ocrService.saveImageToAppDirectory(image);
      
      setState(() {
        _lastImagePath = savedPath;
        _showCamera = false;
      });
      
      await _processImage(savedPath);
    } catch (e) {
      _showErrorDialog('Failed to take picture: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _ocrService.pickImageFromGallery();
      if (image != null) {
        final String savedPath = await _ocrService.saveImageToAppDirectory(image);
        setState(() {
          _lastImagePath = savedPath;
        });
        await _processImage(savedPath);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(String imagePath) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final String extractedText = await _ocrService.recognizeTextFromImage(imagePath);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OcrReviewScreen(
              imagePath: imagePath,
              extractedText: extractedText,
              source: 'mlkit',
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to extract text: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Orbitron',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'Orbitron',
          ),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCarDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showCarSelectionDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedCarId != null && _cars.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _cars
                                      .firstWhere((car) =>
                                          car.id.toString() == _selectedCarId)
                                      .imagePath !=
                                  null
                              ? Image.file(
                                  File(_cars
                                      .firstWhere((car) =>
                                          car.id.toString() == _selectedCarId)
                                      .imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        )
                      : const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCarId != null && _cars.isNotEmpty
                            ? '${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).brand} ${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).model}'
                            : 'Select Car',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                        const SizedBox(height: 4),
                      Text(
                        _selectedCarId != null && _cars.isNotEmpty
                            ? 'Year: ${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).year}'
                            : 'Tap to choose vehicle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Car list
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    final isSelected = _selectedCarId == car.id.toString();
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCarId = car.id.toString();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.darkAccentGreen,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.darkAccentGreen.withOpacity(0.5),
                                    AppTheme.backgroundGreen.withOpacity(0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: car.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.directions_car,
                                            color: Colors.white,
                                            size: isSelected ? 28 : 24,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Year: ${car.year}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (car.licensePlate != null &&
                                      car.licensePlate!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'License: ${car.licensePlate}',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
                const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    AppDialog.message(
      context,
      title: 'Error',
      message: message,
      icon: Icons.error_outline,
      isError: true,
    );
  }
}
