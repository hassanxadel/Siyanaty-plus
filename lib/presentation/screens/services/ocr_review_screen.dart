import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/ocr_service.dart';
import '../../../models/scan_model.dart';
import '../../widgets/app_dialog.dart';
import 'ocr_history_screen.dart';

class OcrReviewScreen extends StatefulWidget {
  final String imagePath;
  final String extractedText;
  final String source;
  final ScanModel? existingScan;

  const OcrReviewScreen({
    super.key,
    required this.imagePath,
    required this.extractedText,
    required this.source,
    this.existingScan,
  });

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _textController = TextEditingController();
  bool _isSaving = false;
  bool _isProcessingCloud = false;
  String _currentSource = '';

  @override
  void initState() {
    super.initState();
    _textController.text = widget.extractedText;
    _currentSource = widget.source;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image preview
                  Container(
                    height: 200,
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
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Source indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSourceColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSourceIcon(),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getSourceText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Extracted text editor
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.darkAccentGreen,
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
                                Icons.edit_note,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Extracted Text',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_textController.text.length} characters',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            minLines: 8,
                            decoration: const InputDecoration(
                              hintText: 'Edit the extracted text here...',
                              hintStyle: TextStyle(
                                fontFamily: 'Orbitron',
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Cloud OCR button (if not already from cloud)
                  if (_currentSource != 'cloud') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.cloud,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Enhanced OCR',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'For better accuracy with Arabic text or complex documents, try cloud-based OCR.',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange,
                                    Colors.deepOrange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isProcessingCloud ? null : _processWithCloudOcr,
                                icon: _isProcessingCloud
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload, color: Colors.white),
                                label: Text(
                                  _isProcessingCloud ? 'Processing...' : 'Use Cloud OCR',
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom action buttons
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
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
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveLocal,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            'Save Local',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.darkAccentGreen,
                              AppTheme.primaryGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.darkAccentGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveAndSync,
                          icon: const Icon(Icons.cloud_upload, color: Colors.white),
                          label: const Text(
                            'Save & Sync',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OcrHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text(
                      'View Scan History',
                      style: TextStyle(fontFamily: 'Orbitron'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                          'Review & Edit',
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
                    onPressed: _copyToClipboard,
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: _shareText,
                    icon: const Icon(
                      Icons.share,
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
                  'Review and edit the extracted text',
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

  Color _getSourceColor() {
    switch (_currentSource) {
      case 'cloud':
        return Colors.orange[600]!;
      case 'mlkit':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon() {
    switch (_currentSource) {
      case 'cloud':
        return Icons.cloud;
      case 'mlkit':
        return Icons.phone_android;
      default:
        return Icons.help;
    }
  }

  String _getSourceText() {
    switch (_currentSource) {
      case 'cloud':
        return 'Cloud OCR';
      case 'mlkit':
        return 'On-Device OCR';
      default:
        return 'Unknown';
    }
  }

  Future<void> _processWithCloudOcr() async {
    setState(() {
      _isProcessingCloud = true;
    });

    try {
      // TODO: Implement cloud OCR when Firebase Functions is available
      // For now, show a placeholder message
      _showInfoDialog(
        'Cloud OCR Not Available',
        'Cloud OCR functionality will be available once Firebase Functions is properly configured.',
      );
    } catch (e) {
      _showErrorDialog('Failed to process with cloud OCR: $e');
    } finally {
      setState(() {
        _isProcessingCloud = false;
      });
    }
  }

  Future<void> _saveLocal() async {
    if (_textController.text.trim().isEmpty) {
      _showErrorDialog('Cannot save empty text');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final scan = ScanModel(
        text: _textController.text.trim(),
        imagePath: widget.imagePath,
        source: _currentSource,
        timestamp: DateTime.now(),
        userId: user?.uid,
      );

      await _ocrService.saveScanLocal(scan);
      
      if (mounted) {
        AppSnackbar.show(context, 
          const SnackBar(
            content: Text(
              'Scan saved locally!',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Failed to save scan: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    if (_textController.text.trim().isEmpty) {
      _showErrorDialog('Cannot save empty text');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('Please sign in to sync with cloud');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final scan = ScanModel(
        text: _textController.text.trim(),
        imagePath: widget.imagePath,
        source: _currentSource,
        timestamp: DateTime.now(),
        userId: user.uid,
      );

      // Save ONLY to Firestore (cloud), not locally
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .add(scan.toFirestore());
      
      if (mounted) {
        AppSnackbar.show(context, 
          const SnackBar(
            content: Text(
              'Scan saved to cloud!',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Failed to save to cloud: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    AppSnackbar.show(context, 
      const SnackBar(
        content: Text(
          'Text copied to clipboard!',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareText() {
    // TODO: Implement sharing functionality
    _showInfoDialog(
      'Share Feature',
      'Sharing functionality will be implemented in a future update.',
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

  void _showInfoDialog(String title, String message) {
    if (!mounted) return;

    AppDialog.message(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
    );
  }
}
