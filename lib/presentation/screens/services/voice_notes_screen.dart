import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../models/voice_note.dart';
import '../../../services/voice_note_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<VoiceNote> _voiceNotes = [];
  List<VoiceNote> _filteredNotes = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _currentPlayingIndex = -1;
  String? _recordingPath;
  String? _userId;
  String _searchQuery = '';
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeAudio();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  Future<void> _initializeAudio() async {
    try {
      // Initialize recorder with proper audio session
      await _recorder.openRecorder();
      
      // Set audio session category for recording
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      
      // Initialize player
      await _player.openPlayer();
      
      print('Audio initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
      // Show error to user if initialization fails
      if (mounted) {
        _showErrorDialog('Failed to initialize audio system. Recording may not work properly.\n\nError: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterNotes();
    });
  }

  void _filterNotes() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_voiceNotes);
    } else {
      _filteredNotes = _voiceNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
               (note.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _voiceNoteService.getAllVoiceNotes(userId: _userId);
      final stats = await _voiceNoteService.getStatistics(userId: _userId);
      
      setState(() {
        _voiceNotes = notes;
        _statistics = stats;
      });
      _filterNotes();
    } catch (e) {
      _showErrorDialog('Failed to load voice notes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstructionsCard(),
                        const SizedBox(height: 24),
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _buildRecordingCard(),
                        const SizedBox(height: 24),
                        if (_voiceNotes.isNotEmpty) _buildSearchBar(),
                        if (_voiceNotes.isNotEmpty) const SizedBox(height: 16),
                        if (_filteredNotes.isNotEmpty) _buildNotesList(),
                        if (_voiceNotes.isNotEmpty && _filteredNotes.isEmpty) _buildEmptySearchState(),
                        if (_voiceNotes.isEmpty) _buildEmptyState(),
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
                  // Expanded title between two equal-width controls keeps
                  // "Voice Notes" optically centred on the screen.
                  const Expanded(
                    child: Text(
                      'Voice Notes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: AppTheme.backgroundGreen,
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: AppTheme.secondaryGreen.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'cleanup_files',
                        child: Row(
                          children: [
                            Icon(
                              Icons.cleaning_services,
                              size: 16,
                              color: AppTheme.secondaryGreen,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Cleanup Files',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                                color: AppTheme.lightBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_metadata',
                        child: Row(
                          children: [
                            Icon(
                              Icons.file_download,
                              size: 16,
                              color: AppTheme.secondaryGreen,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Export Metadata',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                                color: AppTheme.lightBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
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
                  'Record and manage your voice notes',
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How to Use Voice Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1',
            'Record',
            'Tap the record button to start recording your voice note.',
            Icons.mic,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Save',
            'Add a title and optional description, then save your recording.',
            Icons.save,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Manage',
            'Play, edit, or delete your voice notes anytime.',
            Icons.library_music,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
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
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
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
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice Notes Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Notes',
                  '${_statistics['noteCount'] ?? 0}',
                  Icons.library_music,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Duration',
                  _formatDuration(_statistics['totalDuration'] ?? 0),
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg Duration',
                  _formatDuration((_statistics['averageDuration'] ?? 0).round()),
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: _voiceNoteService.getTotalStorageUsed(userId: _userId),
                  builder: (context, snapshot) {
                    final storage = snapshot.data ?? 0;
                    return _buildStatItem(
                      'Storage Used',
                      _voiceNoteService.formatFileSize(storage),
                      Icons.storage,
                      Colors.purple,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
              const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard() {
    return Container(
      width: double.infinity,
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
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        children: [
          const Text(
            'Record Voice Note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
            const SizedBox(height: 20),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isRecording
                      ? [Colors.red, Colors.redAccent]
                      : [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (_isRecording ? Colors.red : AppTheme.secondaryGreen)
                      .withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: AppTheme.glowShadow(
                  accent: _isRecording ? Colors.red : AppTheme.secondaryGreen,
                  elevated: true,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'Recording...' : 'Tap to Record',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_recordingPath != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Recording Complete!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:                   Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkAccentGreen,
                          AppTheme.backgroundGreen,
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.45),
                        width: 1,
                      ),
                      boxShadow: AppTheme.glowShadow(),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _saveRecording,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:                   Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkAccentGreen,
                          AppTheme.backgroundGreen,
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.45),
                        width: 1,
                      ),
                      boxShadow: AppTheme.glowShadow(),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _discardRecording,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Discard',
                        style: TextStyle(
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Orbitron',
        ),
        decoration: InputDecoration(
          hintText: 'Search voice notes...',
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'Orbitron',
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear, color: Colors.white),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return Container(
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
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.library_music,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your Voice Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._filteredNotes.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            return _buildNoteItem(index, note);
          }),
        ],
      ),
    );
  }

  Widget _buildNoteItem(int index, VoiceNote note) {
    final isPlaying = _isPlaying && _currentPlayingIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.createdAt.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleNoteAction(value, note),
                // Dark panel with a green rim so the menu reads as part of the
                // app rather than a stock white Material sheet.
                color: AppTheme.backgroundGreen,
                elevation: 14,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppTheme.secondaryGreen.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                itemBuilder: (context) => [
                  _buildNoteMenuItem(
                    value: 'edit',
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: AppTheme.secondaryGreen,
                  ),
                  _buildNoteMenuItem(
                    value: 'delete',
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppDialog.destructive,
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: AppTheme.lightBackground,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (note.description != null && note.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPlaying
                        ? [Colors.red, Colors.redAccent]
                        : [Colors.green, Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => _togglePlayback(index, note),
                  icon: Icon(
                    isPlaying ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration: ${note.formattedDuration}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _voiceNoteService.getVoiceNoteFileSize(note.filePath),
                      builder: (context, snapshot) {
                        final size = snapshot.data ?? 0;
                        return Text(
                          'Size: ${_voiceNoteService.formatFileSize(size)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: 'Orbitron',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
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
          Icon(
            Icons.mic_none,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Voice Notes Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the record button above to create your first voice note',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Matching Notes Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    // Check permissions
    final micPermission = await _voiceNoteService.requestMicrophonePermission();
    if (!micPermission) {
      _showMessage('Microphone permission is required to record voice notes');
      return;
    }

    try {
      _recordingPath = await _voiceNoteService.generateFilePath();
      
      // Try different codecs in order of preference
      bool recordingStarted = false;
      
      // First try: AAC MP4 (most compatible)
      if (!recordingStarted) {
        try {
          await _recorder.startRecorder(
            toFile: _recordingPath,
            codec: Codec.aacMP4,
            bitRate: 128000,
            sampleRate: 44100,
          );
          recordingStarted = true;
          print('Recording started with AAC MP4 codec');
        } catch (e) {
          print('AAC MP4 codec failed: $e');
        }
      }
      
      // Second try: AAC ADTS
      if (!recordingStarted) {
        try {
          await _recorder.startRecorder(
            toFile: _recordingPath,
            codec: Codec.aacADTS,
            bitRate: 128000,
            sampleRate: 44100,
          );
          recordingStarted = true;
          print('Recording started with AAC ADTS codec');
        } catch (e) {
          print('AAC ADTS codec failed: $e');
        }
      }
      
      // Third try: PCM16 (fallback)
      if (!recordingStarted) {
        try {
          await _recorder.startRecorder(
            toFile: _recordingPath,
            codec: Codec.pcm16,
            sampleRate: 44100,
          );
          recordingStarted = true;
          print('Recording started with PCM16 codec');
        } catch (e) {
          print('PCM16 codec failed: $e');
        }
      }
      
      if (recordingStarted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        // Start timer to update duration
        _startRecordingTimer();

        HapticFeedback.lightImpact();
        _showMessage('Recording started');
      } else {
        _showErrorDialog('Failed to start recording: No compatible audio codec found');
      }
    } catch (e) {
      _showErrorDialog('Failed to start recording: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      
      // Stop the timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      setState(() {
        _isRecording = false;
      });

      HapticFeedback.lightImpact();
      
      // Show dialog asking if user wants to save or discard
      if (mounted) {
        _showSaveOrDiscardDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to stop recording: $e');
    }
  }
  
  Future<void> _showSaveOrDiscardDialog() async {
    final save = await AppDialog.show(
      context,
      title: 'Recording Stopped',
      message: 'Would you like to save this recording?',
      icon: Icons.mic_none,
      cancelLabel: 'Discard',
      confirmLabel: 'Save',
      // Discarding throws the recording away, so it gets the destructive tint.
      cancelAccent: AppDialog.destructive,
      barrierDismissible: false,
    );

    if (!mounted) return;

    if (save == true) {
      _saveRecording();
    } else {
      _discardRecording();
    }
  }
  
  void _discardRecording() {
    // Delete the recording file
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Error deleting recording: $e');
      }
    }
    
    setState(() {
      _recordingPath = null;
      _recordingDuration = 0;
    });
    
    _showMessage('Recording discarded');
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration++;
        });
      }
    });
  }

  Future<void> _saveRecording() async {
    if (_recordingPath == null) return;

    // Stop recording if still recording
    if (_isRecording) {
      await _stopRecording();
    }

    _showVoiceNoteForm(
      title: 'Save Voice Note',
      subtitle: 'Give this recording a name so you can find it later',
      icon: Icons.save_outlined,
      confirmLabel: 'Save',
      onConfirm: _saveVoiceNote,
    );
  }

  /// Shared title/description form used for both saving a new recording and
  /// editing an existing note. Built from the app-wide dialog kit so it stays
  /// identical to every other pop-up card.
  void _showVoiceNoteForm({
    required String title,
    required String subtitle,
    required IconData icon,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    AppDialog.custom<void>(
      context,
      title: title,
      message: subtitle,
      icon: icon,
      content: Column(
        children: [
          AppDialogField(
            controller: _titleController,
            label: 'Title',
            hint: 'Enter title',
            icon: Icons.title,
          ),
          const SizedBox(height: 16),
          AppDialogField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Description (optional)',
            icon: Icons.notes,
            maxLines: 3,
          ),
        ],
      ),
      actionsBuilder: (dialogContext) => [
        AppDialogAction(
          label: 'Cancel',
          onTap: () {
            Navigator.pop(dialogContext);
            _clearInputs();
          },
        ),
        AppDialogAction(
          label: confirmLabel,
          filled: true,
          onTap: () {
            Navigator.pop(dialogContext);
            onConfirm();
          },
        ),
      ],
    );
  }

  /// Styled entry for the per-note edit/delete menu.
  PopupMenuItem<String> _buildNoteMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVoiceNote() async {
    if (_recordingPath == null || _titleController.text.trim().isEmpty) {
      _showMessage('Please enter a title for the voice note');
      return;
    }

    try {
      // Get file duration (simplified - in a real app you'd use audio analysis)
      final file = File(_recordingPath!);
      final fileSize = await file.length();
      final estimatedDuration = (fileSize / 8000).round(); // Rough estimate

      final voiceNote = VoiceNote(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        filePath: _recordingPath!,
        duration: estimatedDuration,
        userId: _userId,
      );

      await _voiceNoteService.addVoiceNote(voiceNote);
      
      setState(() {
        _recordingPath = null;
      });
      
      _clearInputs();
      await _loadData();
      
      _showMessage('Voice note saved successfully!');
    } catch (e) {
      _showErrorDialog('Failed to save voice note: $e');
    }
  }


  Future<void> _togglePlayback(int index, VoiceNote note) async {
    if (_isPlaying && _currentPlayingIndex == index) {
      // Stop current playback
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentPlayingIndex = -1;
      });
    } else {
      // Start playback
      if (_isPlaying) {
        await _player.stopPlayer();
      }
      
      bool playbackStarted = false;
      
      // Try different codecs for playback
      final codecs = [Codec.aacMP4, Codec.aacADTS, Codec.pcm16];
      
      for (final codec in codecs) {
        if (!playbackStarted) {
          try {
            await _player.startPlayer(
              fromURI: note.filePath,
              codec: codec,
            );
            playbackStarted = true;
            print('Playback started with ${codec.toString()} codec');
            
            setState(() {
              _isPlaying = true;
              _currentPlayingIndex = index;
            });
            
            // Listen for playback completion
            _player.onProgress!.listen((event) {
              if (event.position >= event.duration) {
                setState(() {
                  _isPlaying = false;
                  _currentPlayingIndex = -1;
                });
              }
            });
            break;
          } catch (e) {
            print('Playback failed with ${codec.toString()}: $e');
          }
        }
      }
      
      if (!playbackStarted) {
        _showErrorDialog('Failed to play voice note: No compatible audio codec found for playback');
      }
    }
  }

  void _handleNoteAction(String action, VoiceNote note) {
    switch (action) {
      case 'edit':
        _editNote(note);
        break;
      case 'delete':
        _confirmDeleteNote(note);
        break;
    }
  }

  void _editNote(VoiceNote note) {
    _titleController.text = note.title;
    _descriptionController.text = note.description ?? '';
    
    _showVoiceNoteForm(
      title: 'Edit Voice Note',
      subtitle: 'Update the name or description of this note',
      icon: Icons.edit_outlined,
      confirmLabel: 'Update',
      onConfirm: () => _updateNote(note),
    );
  }

  Future<void> _updateNote(VoiceNote note) async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Please enter a title for the voice note');
      return;
    }

    try {
      final updatedNote = note.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      await _voiceNoteService.updateVoiceNote(updatedNote);
      await _loadData();
      _clearInputs();
      _showMessage('Voice note updated successfully!');
    } catch (e) {
      _showErrorDialog('Failed to update voice note: $e');
    }
  }

  Future<void> _confirmDeleteNote(VoiceNote note) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Voice Note',
      message:
          'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _deleteNote(note);
    }
  }

  Future<void> _deleteNote(VoiceNote note) async {
    if (note.id == null) return;

    try {
      await _voiceNoteService.deleteVoiceNote(note.id!);
      await _loadData();
      HapticFeedback.lightImpact();
      _showMessage('Voice note deleted successfully');
    } catch (e) {
      _showErrorDialog('Failed to delete voice note: $e');
    }
  }

  void _clearInputs() {
    _titleController.clear();
    _descriptionController.clear();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'cleanup_files':
        _cleanupFiles();
        break;
      case 'export_metadata':
        _exportMetadata();
        break;
    }
  }

  Future<void> _cleanupFiles() async {
    try {
      _showMessage('Cleaning up orphaned files...');
      final deletedCount = await _voiceNoteService.cleanupOrphanedFiles(userId: _userId);
      _showMessage('Cleaned up $deletedCount orphaned files');
      await _loadData(); // Refresh stats
    } catch (e) {
      _showErrorDialog('Cleanup failed: $e');
    }
  }

  Future<void> _exportMetadata() async {
    try {
      final metadata = await _voiceNoteService.exportMetadataAsJson(userId: _userId);
      
      if (!mounted) return;

      AppDialog.custom<void>(
        context,
        title: 'Export Metadata',
        icon: Icons.file_download_outlined,
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glowFieldDecoration(),
          child: Text(
            metadata,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.5,
              color: AppTheme.lightBackground.withOpacity(0.9),
            ),
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Export failed: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showErrorDialog(String message) {
    AppDialog.message(
      context,
      title: 'Error',
      message: message,
      icon: Icons.error_outline,
      isError: true,
    );
  }
}