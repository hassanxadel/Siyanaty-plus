import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/ocr_service.dart';
import '../../../models/scan_model.dart';
import 'ocr_review_screen.dart';


class OcrHistoryScreen extends StatefulWidget {
  const OcrHistoryScreen({super.key});

  @override
  State<OcrHistoryScreen> createState() => _OcrHistoryScreenState();
}

class _OcrHistoryScreenState extends State<OcrHistoryScreen> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _searchController = TextEditingController();
  List<ScanModel> _scans = [];
  List<ScanModel> _filteredScans = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadScans();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterScans();
    });
  }

  void _filterScans() {
    if (_searchQuery.isEmpty) {
      _filteredScans = List.from(_scans);
    } else {
      _filteredScans = _scans.where((scan) {
        return scan.text.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _scans = await _ocrService.getAllScans(user.uid);
      } else {
        _scans = await _ocrService.getAllScans(null);
      }
      _filterScans();
    } catch (e) {
      _showErrorDialog('Failed to load scans: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading scans...',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredScans.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredScans.length,
                        itemBuilder: (context, index) {
                          final scan = _filteredScans[index];
                          return _buildScanItem(scan);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Scan History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_filteredScans.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'View and manage your saved OCR scans',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Search bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search scans...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear, color: AppTheme.primaryGreen, size: 20),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: AppTheme.backgroundGreen,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats row
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.document_scanner,
                        label: 'Total',
                        value: _scans.length.toString(),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.search,
                        label: 'Filtered',
                        value: _filteredScans.length.toString(),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.cloud,
                        label: 'Cloud',
                        value: _scans.where((s) => s.source == 'cloud').length.toString(),
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            color: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.document_scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matching scans found' : 'No scans yet',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start by scanning your first document',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Scan Document',
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
        ],
      ),
    );
  }

  Widget _buildScanItem(ScanModel scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _openScanForReview(scan),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey[800],
                ),
                child: scan.imagePath != null && File(scan.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(scan.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text preview
                    Text(
                      scan.text.length > 100
                          ? '${scan.text.substring(0, 100)}...'
                          : scan.text,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                      const SizedBox(height: 8),
                    
                    // Metadata
                    Row(
                      children: [
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSourceColor(scan.source),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSourceIcon(scan.source),
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getSourceText(scan.source),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'Orbitron',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Timestamp
                        Text(
                          _formatTimestamp(scan.timestamp),
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) => _handleScanAction(value, scan),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(fontFamily: 'Orbitron'),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'cloud':
        return Colors.orange[600]!;
      case 'mlkit':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'cloud':
        return Icons.cloud;
      case 'mlkit':
        return Icons.phone_android;
      default:
        return Icons.help;
    }
  }

  String _getSourceText(String source) {
    switch (source) {
      case 'cloud':
        return 'Cloud';
      case 'mlkit':
        return 'Device';
      default:
        return 'Unknown';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openScanForReview(ScanModel scan) {
    if (scan.imagePath != null && File(scan.imagePath!).existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OcrReviewScreen(
            imagePath: scan.imagePath!,
            extractedText: scan.text,
            source: scan.source,
            existingScan: scan,
          ),
        ),
      ).then((_) => _loadScans());
    } else {
      _showErrorDialog('Image file not found');
    }
  }

  void _handleScanAction(String action, ScanModel scan) {
    switch (action) {
      case 'edit':
        _openScanForReview(scan);
        break;
      case 'delete':
        _confirmDeleteScan(scan);
        break;
    }
  }

  void _confirmDeleteScan(ScanModel scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Scan',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        content: const Text(
          'Are you sure you want to delete this scan? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScan(scan);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteScan(ScanModel scan) async {
    try {
      if (scan.id != null) {
        await _ocrService.deleteScan(scan.id!, null);
        
        // Also delete the image file if it exists
        if (scan.imagePath != null && File(scan.imagePath!).existsSync()) {
          await File(scan.imagePath!).delete();
        }
        
        _loadScans(); // Refresh the list
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Scan deleted successfully',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to delete scan: $e');
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
