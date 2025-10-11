import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/ocr_service.dart';
import '../../../models/scan_model.dart';
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
      appBar: AppBar(
        title: const Text(
          'Review & Edit',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy text',
          ),
          IconButton(
            onPressed: _shareText,
            icon: const Icon(Icons.share),
            tooltip: 'Share text',
          ),
        ],
      ),
      body: Column(
        children: [
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Extracted Text',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.backgroundGreen,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_textController.text.length} characters',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  color: AppTheme.darkAccentGreen,
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
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              height: 1.5,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Enhanced OCR',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.backgroundGreen,
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
                              color: AppTheme.darkAccentGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
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
                                  : const Icon(Icons.cloud_upload),
                              label: Text(
                                _isProcessingCloud ? 'Processing...' : 'Use Cloud OCR',
                                style: const TextStyle(fontFamily: 'Orbitron'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
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
              color: Colors.white,
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
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveLocal,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Local',
                          style: TextStyle(fontFamily: 'Orbitron'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAndSync,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text(
                          'Save & Sync',
                          style: TextStyle(fontFamily: 'Orbitron'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkAccentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                      foregroundColor: AppTheme.primaryGreen,
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

      await _ocrService.saveScanToDatabase(scan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
        return;
      }

      final scan = ScanModel(
        text: _textController.text.trim(),
        imagePath: widget.imagePath,
        source: _currentSource,
        timestamp: DateTime.now(),
        userId: user.uid,
      );

      // Save locally first
      await _ocrService.saveScanToDatabase(scan);

      // Then sync to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .add(scan.toFirestore());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Scan saved and synced!',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Failed to save and sync: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
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

  void _showInfoDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Orbitron'),
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
