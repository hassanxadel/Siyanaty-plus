import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/ocr_service.dart';
import 'ocr_review_screen.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String? _lastImagePath;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'OCR Scanner',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showCamera && _isCameraInitialized
          ? _buildCameraPreview()
          : _buildMainInterface(),
    );
  }

  Widget _buildMainInterface() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.document_scanner,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan Documents',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.backgroundGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture or select an image to extract text using AI',
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
          
          const SizedBox(height: 30),
          
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
          
          const SizedBox(height: 16),
          
          if (_isCameraInitialized)
            _buildActionButton(
              icon: Icons.videocam,
              title: 'Camera Preview',
              subtitle: 'Show live camera preview',
              onTap: () {
                setState(() {
                  _showCamera = true;
                });
              },
              isEnabled: !_isProcessing,
            ),
          
          const Spacer(),
          
          // Last image preview
          if (_lastImagePath != null) ...[
            const Text(
              'Last Captured Image:',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.backgroundGreen,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_lastImagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _processImage(_lastImagePath!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Processing...',
                          style: TextStyle(fontFamily: 'Orbitron'),
                        ),
                      ],
                    )
                  : const Text(
                      'Process Last Image',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
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
                    Icons.arrow_back,
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
          color: isEnabled ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled ? AppTheme.primaryGreen : Colors.grey,
                borderRadius: BorderRadius.circular(10),
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
                      color: isEnabled ? AppTheme.backgroundGreen : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: isEnabled ? AppTheme.darkAccentGreen : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? AppTheme.primaryGreen : Colors.grey,
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
      final XFile? image = await _ocrService.captureImageFromCamera();
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
      final XFile image = await _cameraController!.takePicture();
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
      final XFile? image = await _ocrService.pickImageFromGallery();
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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
        ],
      ),
    );
  }
}
