import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../models/voice_note.dart';
import '../../../services/voice_note_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

/// Explicit recorder lifecycle. Modelling this as a state machine (rather than
/// loose booleans) is what prevents the old "discard silently restarts a
/// recording" class of bug: the record control only exists in [idle] with no
/// pending review, so a new recording can never begin on its own.
enum _RecState { idle, recording, paused }

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen>
    with WidgetsBindingObserver {
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
  String? _userId;
  String _searchQuery = '';
  bool _audioReady = false;

  // Recorder state machine.
  _RecState _recState = _RecState.idle;
  bool _reviewPending = false; // stopped recording awaiting save / discard
  String? _activeRecordingPath;
  int _recordedSeconds = 0; // active (pause-excluded) recorded seconds
  final List<double> _levels = []; // normalised 0..1 decibel history (waveform)
  StreamSubscription<RecordingDisposition>? _recSub;

  // Player state (only one note plays at a time).
  int? _playingNoteId; // which note's panel is expanded
  bool _playerPlaying = false;
  Duration _playPos = Duration.zero;
  Duration _playTotal = Duration.zero;
  bool _isSeeking = false;
  StreamSubscription<PlaybackDisposition>? _playSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _initializeAudio();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeAudio() async {
    try {
      await _recorder.openRecorder();
      await _recorder
          .setSubscriptionDuration(const Duration(milliseconds: 100));
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 100));
      _audioReady = true;
      AppLogger.info('Voice notes audio initialised');
    } catch (e, s) {
      AppLogger.error('Failed to initialise audio', error: e, stackTrace: s);
      if (mounted) {
        _showErrorDialog(
            'Failed to initialise the audio system. Recording may not work.');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recSub?.cancel();
    _playSub?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding during an active recording: pause so no audio is lost and
    // the OS can't silently kill the capture mid-stream.
    if (state == AppLifecycleState.paused &&
        _recState == _RecState.recording) {
      _pauseRecording();
    }
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
    setState(() => _isLoading = true);
    try {
      final notes = await _voiceNoteService.getAllVoiceNotes(userId: _userId);
      final stats = await _voiceNoteService.getStatistics(userId: _userId);
      if (!mounted) return;
      setState(() {
        _voiceNotes = notes;
        _statistics = stats;
      });
      _filterNotes();
    } catch (e, s) {
      AppLogger.error('Failed to load voice notes', error: e, stackTrace: s);
      if (mounted) _showErrorDialog('Failed to load voice notes.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecordCard(),
                          const SizedBox(height: 24),
                          if (_voiceNotes.isNotEmpty) ...[
                            _buildSearchBar(),
                            const SizedBox(height: 16),
                          ],
                          if (_filteredNotes.isNotEmpty) _buildNotesList(),
                          if (_voiceNotes.isNotEmpty && _filteredNotes.isEmpty)
                            _buildEmptySearchState(),
                          if (_voiceNotes.isEmpty) _buildEmptyState(),
                          const SizedBox(height: 24),
                          _buildStatsCard(),
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
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
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
                    tooltip: 'More options',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: AppTheme.secondaryGreen.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      _buildHeaderMenuItem(
                          'cleanup_files',
                          CupertinoIcons.sparkles,
                          'Cleanup Files'),
                      _buildHeaderMenuItem(
                          'export_metadata',
                          CupertinoIcons.square_arrow_down,
                          'Export Metadata'),
                    ],
                    child: const Icon(CupertinoIcons.ellipsis_vertical,
                        color: Colors.white, size: 26),
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

  PopupMenuItem<String> _buildHeaderMenuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryGreen),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              color: AppTheme.lightBackground,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Record card (state machine driven)
  // ---------------------------------------------------------------------------

  BoxDecoration _cardDecoration() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.glowShadow(),
      );

  Widget _buildRecordCard() {
    final recording = _recState != _RecState.idle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 24),
          if (_reviewPending)
            _buildReviewContent()
          else if (recording)
            _buildActiveContent()
          else
            _buildIdleContent(),
        ],
      ),
    );
  }

  Widget _buildIdleContent() {
    return Column(
      children: [
        _buildRecordButton(),
        const SizedBox(height: 16),
        const Text(
          'Tap to Record',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontFamily: 'Orbitron'),
        ),
      ],
    );
  }

  Widget _buildActiveContent() {
    final paused = _recState == _RecState.paused;
    return Column(
      children: [
        _buildWaveform(),
        const SizedBox(height: 16),
        _buildTimerPill(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircleControl(
              icon: CupertinoIcons.trash_fill,
              label: 'Discard recording',
              color: AppDialog.destructive,
              onTap: _discardActive,
            ),
            _buildRecordButton(),
            _buildCircleControl(
              icon: paused
                  ? CupertinoIcons.play_fill
                  : CupertinoIcons.pause_fill,
              label: paused ? 'Resume recording' : 'Pause recording',
              color: AppTheme.costHighlight,
              onTap: paused ? _resumeRecording : _pauseRecording,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          paused ? 'Paused' : 'Recording…',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Orbitron',
            color: paused ? AppTheme.costHighlight : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContent() {
    return Column(
      children: [
        const Icon(CupertinoIcons.checkmark_seal_fill,
            color: AppTheme.secondaryGreen, size: 40),
        const SizedBox(height: 12),
        const Text(
          'Recording ready',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatClock(Duration(seconds: _recordedSeconds)),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Orbitron',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _buildPillButton(
                label: 'Discard',
                icon: CupertinoIcons.trash,
                accent: AppDialog.destructive,
                onTap: _discardActive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPillButton(
                label: 'Save',
                icon: CupertinoIcons.tray_arrow_down,
                accent: AppTheme.secondaryGreen,
                onTap: _saveActive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Large morphing record control: green circle (mic) when idle, red rounded
  /// square (stop) while recording — the Apple Voice Memos transition.
  Widget _buildRecordButton() {
    final recording = _recState != _RecState.idle;
    final accent = recording ? Colors.red : AppTheme.secondaryGreen;
    return Semantics(
      button: true,
      label: recording ? 'Stop recording' : 'Start recording',
      child: GestureDetector(
        onTap: recording ? _stopToReview : _startRecording,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: recording
                  ? [Colors.red, Colors.redAccent]
                  : [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
            ),
            borderRadius: BorderRadius.circular(recording ? 22 : 42),
            border: Border.all(color: accent.withOpacity(0.6), width: 2),
            boxShadow: AppTheme.glowShadow(accent: accent, elevated: true),
          ),
          child: Icon(
            recording ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleControl({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.55), width: 1.3),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  /// Live waveform built from the recorder's decibel history. Updates freeze
  /// automatically while paused because [_onRecProgress] stops appending.
  Widget _buildWaveform() {
    const barCount = 34;
    final paused = _recState == _RecState.paused;
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final idx = _levels.length - barCount + i;
          final level =
              (idx >= 0 && idx < _levels.length) ? _levels[idx] : 0.0;
          final height = (6 + level * 46).clamp(6.0, 52.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: paused
                  ? AppTheme.secondaryGreen.withOpacity(0.4)
                  : AppTheme.secondaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimerPill() {
    final paused = _recState == _RecState.paused;
    return Opacity(
      opacity: paused ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
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
              _formatClock(Duration(seconds: _recordedSeconds)),
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
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.16),
        border: Border.all(color: accent.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes list
  // ---------------------------------------------------------------------------

  Widget _buildNotesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(CupertinoIcons.waveform, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Your Voice Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
        ..._filteredNotes.map(_buildNoteItem),
      ],
    );
  }

  Widget _buildNoteItem(VoiceNote note) {
    final open = _playingNoteId == note.id;
    return Dismissible(
      key: ValueKey(note.id ?? note.filePath),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteNote(note),
      onDismissed: (_) {
        // Remove locally first so the dismissed widget leaves the tree before
        // the async DB delete / reload runs.
        setState(() {
          _voiceNotes.removeWhere((n) => n.id == note.id);
          _filterNotes();
        });
        _deleteNote(note);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppDialog.destructive.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.trash_fill, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundGreen, AppTheme.primaryGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryGreen.withOpacity(open ? 0.6 : 0.25),
            width: 1,
          ),
          boxShadow: AppTheme.glowShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPlayCircle(note, open),
                const SizedBox(width: 12),
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
                        '${note.createdAt.toLocal().toString().split(' ')[0]}  ·  ${note.formattedDuration}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNoteMenu(note),
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
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildPlayerPanel(note),
              crossFadeState: open
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayCircle(VoiceNote note, bool open) {
    final showPause = open && _playerPlaying;
    return Semantics(
      button: true,
      label: showPause ? 'Pause ${note.title}' : 'Play ${note.title}',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _togglePlay(note),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: showPause
                    ? [AppTheme.costHighlight, const Color(0xFFE0A91F)]
                    : [AppTheme.secondaryGreen, AppTheme.primaryGreen],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              showPause ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteMenu(VoiceNote note) {
    return PopupMenuButton<String>(
      tooltip: 'Note options',
      onSelected: (value) => _handleNoteAction(value, note),
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
          icon: CupertinoIcons.pencil,
          label: 'Edit',
          color: AppTheme.secondaryGreen,
        ),
        _buildNoteMenuItem(
          value: 'delete',
          icon: CupertinoIcons.trash,
          label: 'Delete',
          color: AppDialog.destructive,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGreen.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.secondaryGreen.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: const Icon(CupertinoIcons.ellipsis,
            color: AppTheme.lightBackground, size: 20),
      ),
    );
  }

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

  /// Expandable playback panel: seekable scrubber, elapsed / -remaining,
  /// skip ±15s, play/pause, and stop (collapses the panel).
  Widget _buildPlayerPanel(VoiceNote note) {
    final total = _playTotal.inMilliseconds > 0
        ? _playTotal
        : Duration(seconds: note.duration);
    final maxMs =
        total.inMilliseconds <= 0 ? 1.0 : total.inMilliseconds.toDouble();
    final posMs = _playPos.inMilliseconds.toDouble().clamp(0.0, maxMs);
    var remaining = total - _playPos;
    if (remaining < Duration.zero) remaining = Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          const Divider(color: Colors.white24, height: 20),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppTheme.secondaryGreen,
              inactiveTrackColor: AppTheme.secondaryGreen.withOpacity(0.25),
              thumbColor: AppTheme.costHighlight,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: posMs,
              max: maxMs,
              onChangeStart: (_) => _isSeeking = true,
              onChanged: (v) =>
                  setState(() => _playPos = Duration(milliseconds: v.round())),
              onChangeEnd: (v) async {
                _isSeeking = false;
                await _seekTo(Duration(milliseconds: v.round()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatClock(_playPos),
                    style: _timeStyle),
                Text('-${_formatClock(remaining)}', style: _timeStyle),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlaybackControl(
                icon: CupertinoIcons.gobackward_15,
                label: 'Skip back 15 seconds',
                onTap: () => _skip(-15),
              ),
              _buildPlaybackControl(
                icon: _playerPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                label: _playerPlaying ? 'Pause' : 'Play',
                big: true,
                onTap: () => _togglePlay(note),
              ),
              _buildPlaybackControl(
                icon: CupertinoIcons.stop_fill,
                label: 'Stop',
                onTap: _stopPlayback,
              ),
              _buildPlaybackControl(
                icon: CupertinoIcons.goforward_15,
                label: 'Skip forward 15 seconds',
                onTap: () => _skip(15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _timeStyle = TextStyle(
    fontSize: 12,
    color: Colors.white70,
    fontFamily: 'Orbitron',
  );

  Widget _buildPlaybackControl({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool big = false,
  }) {
    final size = big ? 52.0 : 44.0;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: big
                  ? AppTheme.secondaryGreen.withOpacity(0.25)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: big ? 26 : 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
        decoration: InputDecoration(
          hintText: 'Search voice notes…',
          hintStyle:
              const TextStyle(color: Colors.white54, fontFamily: 'Orbitron'),
          prefixIcon:
              const Icon(CupertinoIcons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _searchController.clear,
                  tooltip: 'Clear search',
                  icon: const Icon(CupertinoIcons.clear, color: Colors.white),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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
                  CupertinoIcons.waveform,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Duration',
                  _formatDuration(_statistics['totalDuration'] ?? 0),
                  CupertinoIcons.clock,
                  AppTheme.costHighlight,
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
                  CupertinoIcons.timer,
                  AppTheme.infoBlue,
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
                      CupertinoIcons.folder,
                      AppTheme.secondaryGreen,
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
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.mic,
                size: 72, color: Colors.white.withOpacity(0.5)),
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
                  fontSize: 14, color: Colors.white70, fontFamily: 'Orbitron'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search,
                size: 60, color: Colors.white.withOpacity(0.5)),
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
                  fontSize: 14, color: Colors.white70, fontFamily: 'Orbitron'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recorder logic
  // ---------------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (!_audioReady) {
      _showErrorDialog('Audio system is not ready yet. Please try again.');
      return;
    }
    final granted = await _voiceNoteService.requestMicrophonePermission();
    if (!granted) {
      await _showPermissionDialog();
      return;
    }
    try {
      final path = await _voiceNoteService.generateFilePath();
      final started = await _startRecorderWithFallback(path);
      if (!started) {
        _showErrorDialog('No compatible audio codec found for recording.');
        return;
      }
      await _recSub?.cancel();
      _recSub = _recorder.onProgress!.listen(_onRecProgress);
      if (!mounted) return;
      setState(() {
        _activeRecordingPath = path;
        _recState = _RecState.recording;
        _recordedSeconds = 0;
        _levels.clear();
      });
      HapticFeedback.mediumImpact();
    } catch (e, s) {
      AppLogger.error('Failed to start recording', error: e, stackTrace: s);
      _showErrorDialog('Failed to start recording.');
    }
  }

  Future<bool> _startRecorderWithFallback(String path) async {
    for (final codec in const [Codec.aacMP4, Codec.aacADTS, Codec.pcm16]) {
      try {
        await _recorder.startRecorder(
          toFile: path,
          codec: codec,
          bitRate: 128000,
          sampleRate: 44100,
        );
        AppLogger.info('Recording started with $codec');
        return true;
      } catch (e) {
        AppLogger.warning('Recorder codec $codec unavailable', error: e);
      }
    }
    return false;
  }

  void _onRecProgress(RecordingDisposition d) {
    if (!mounted || _recState != _RecState.recording) return;
    final db = (d.decibels ?? 0).clamp(0, 120).toDouble();
    setState(() {
      // duration from the recorder natively excludes paused time.
      _recordedSeconds = d.duration.inSeconds;
      _levels.add(db / 120.0);
      if (_levels.length > 80) _levels.removeAt(0);
    });
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pauseRecorder();
      if (!mounted) return;
      setState(() => _recState = _RecState.paused);
      HapticFeedback.lightImpact();
    } catch (e) {
      AppLogger.warning('Pause recorder not supported', error: e);
      _showMessage('Pause is not supported on this device');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      if (!mounted) return;
      setState(() => _recState = _RecState.recording);
      HapticFeedback.lightImpact();
    } catch (e) {
      AppLogger.warning('Resume recorder failed', error: e);
      _showMessage('Could not resume recording');
    }
  }

  Future<void> _stopToReview() async {
    try {
      await _recorder.stopRecorder();
      await _recSub?.cancel();
      _recSub = null;
      if (!mounted) return;
      setState(() {
        _recState = _RecState.idle;
        _reviewPending = true;
      });
      HapticFeedback.mediumImpact();
    } catch (e, s) {
      AppLogger.error('Failed to stop recording', error: e, stackTrace: s);
      _showErrorDialog('Failed to stop recording.');
    }
  }

  /// Confirm-and-discard, shared by the recording/paused/review states. Always
  /// returns the page to [idle] — nothing auto-starts.
  Future<void> _discardActive() async {
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Discard this recording?'),
        message: const Text('The recording will be permanently deleted.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard Recording'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      if (_recState != _RecState.idle && !_recorder.isStopped) {
        await _recorder.stopRecorder();
      }
    } catch (e) {
      AppLogger.warning('Stop during discard failed', error: e);
    }
    await _recSub?.cancel();
    _recSub = null;

    if (_activeRecordingPath != null) {
      try {
        final file = File(_activeRecordingPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        AppLogger.error('Failed to delete discarded recording', error: e);
      }
    }

    if (!mounted) return;
    setState(() {
      _recState = _RecState.idle;
      _reviewPending = false;
      _activeRecordingPath = null;
      _recordedSeconds = 0;
      _levels.clear();
    });
    HapticFeedback.mediumImpact();
    _showMessage('Recording discarded');
  }

  void _saveActive() {
    _showVoiceNoteForm(
      title: 'Save Voice Note',
      subtitle: 'Give this recording a name so you can find it later',
      icon: CupertinoIcons.tray_arrow_down,
      confirmLabel: 'Save',
      onConfirm: _saveVoiceNote,
    );
  }

  Future<void> _saveVoiceNote() async {
    final path = _activeRecordingPath;
    if (path == null || _titleController.text.trim().isEmpty) {
      _showMessage('Please enter a title for the voice note');
      return;
    }
    try {
      final voiceNote = VoiceNote(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        filePath: path,
        duration: _recordedSeconds, // measured active seconds, not an estimate
        userId: _userId,
      );
      await _voiceNoteService.addVoiceNote(voiceNote);
      if (!mounted) return;
      setState(() {
        _reviewPending = false;
        _activeRecordingPath = null;
        _recordedSeconds = 0;
        _levels.clear();
      });
      _clearInputs();
      await _loadData();
      HapticFeedback.lightImpact();
      _showMessage('Voice note saved successfully!');
    } catch (e, s) {
      AppLogger.error('Failed to save voice note', error: e, stackTrace: s);
      _showErrorDialog('Failed to save voice note.');
    }
  }

  // ---------------------------------------------------------------------------
  // Playback logic (single player, one note at a time)
  // ---------------------------------------------------------------------------

  Future<void> _togglePlay(VoiceNote note) async {
    if (_recState != _RecState.idle) {
      _showMessage('Stop recording before playing');
      return;
    }
    if (_playingNoteId == note.id) {
      // Finished playback leaves the player stopped (not paused) — restart it
      // rather than trying to resume a stopped player.
      if (!_playerPlaying && _player.isStopped) {
        await _startPlayback(note);
        return;
      }
      try {
        if (_playerPlaying) {
          await _player.pausePlayer();
          if (mounted) setState(() => _playerPlaying = false);
        } else {
          await _player.resumePlayer();
          if (mounted) setState(() => _playerPlaying = true);
        }
        HapticFeedback.selectionClick();
      } catch (e) {
        AppLogger.warning('Toggle playback failed', error: e);
      }
      return;
    }
    await _startPlayback(note);
  }

  Future<void> _startPlayback(VoiceNote note) async {
    if (!_audioReady) {
      _showErrorDialog('Audio system is not ready yet. Please try again.');
      return;
    }
    if (!await _voiceNoteService.voiceNoteFileExists(note.filePath)) {
      _showErrorDialog('This recording file could not be found.');
      return;
    }
    try {
      if (!_player.isStopped) await _player.stopPlayer();
      await _playSub?.cancel();
      _playSub = _player.onProgress!.listen((d) {
        if (!mounted || _isSeeking) return;
        setState(() {
          _playPos = d.position;
          _playTotal = d.duration;
        });
      });
      if (!mounted) return;
      setState(() {
        _playingNoteId = note.id;
        _playerPlaying = true;
        _playPos = Duration.zero;
        _playTotal = Duration(seconds: note.duration);
      });
      HapticFeedback.selectionClick();
      void onFinished() {
        if (!mounted) return;
        setState(() {
          _playerPlaying = false;
          _playPos = Duration.zero;
        });
      }

      // Notes are recorded as AAC-MP4 (.m4a), but fall back for any legacy
      // file saved with a different codec rather than failing outright.
      var started = false;
      for (final codec in const [Codec.aacMP4, Codec.aacADTS]) {
        try {
          await _player.startPlayer(
            fromURI: note.filePath,
            codec: codec,
            whenFinished: onFinished,
          );
          started = true;
          break;
        } catch (e) {
          AppLogger.warning('Playback codec $codec failed', error: e);
        }
      }
      if (!started) throw Exception('No compatible playback codec');
    } catch (e, s) {
      AppLogger.error('Failed to play voice note', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _playingNoteId = null;
          _playerPlaying = false;
        });
      }
      _showErrorDialog('Failed to play this recording.');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      if (!_player.isStopped) await _player.stopPlayer();
    } catch (e) {
      AppLogger.warning('Stop playback failed', error: e);
    }
    await _playSub?.cancel();
    _playSub = null;
    if (!mounted) return;
    setState(() {
      _playingNoteId = null;
      _playerPlaying = false;
      _playPos = Duration.zero;
      _playTotal = Duration.zero;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _seekTo(Duration pos) async {
    try {
      await _player.seekToPlayer(pos);
    } catch (e) {
      AppLogger.warning('Seek failed', error: e);
    }
  }

  Future<void> _skip(int seconds) async {
    var target = _playPos + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (_playTotal > Duration.zero && target > _playTotal) {
      target = _playTotal;
    }
    setState(() => _playPos = target);
    await _seekTo(target);
  }

  // ---------------------------------------------------------------------------
  // Shared dialogs / helpers
  // ---------------------------------------------------------------------------

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

  Future<void> _showPermissionDialog() async {
    final open = await AppDialog.show(
      context,
      title: 'Microphone Access Needed',
      message:
          'Recording voice notes requires microphone access. Open settings to grant permission.',
      icon: Icons.mic_off_outlined,
      cancelLabel: 'Not Now',
      confirmLabel: 'Open Settings',
    );
    if (open == true) {
      await openAppSettings();
    }
  }

  void _handleNoteAction(String action, VoiceNote note) {
    switch (action) {
      case 'edit':
        _editNote(note);
        break;
      case 'delete':
        _deleteFromMenu(note);
        break;
    }
  }

  void _editNote(VoiceNote note) {
    _titleController.text = note.title;
    _descriptionController.text = note.description ?? '';
    _showVoiceNoteForm(
      title: 'Edit Voice Note',
      subtitle: 'Update the name or description of this note',
      icon: CupertinoIcons.pencil,
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
      final updated = note.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      await _voiceNoteService.updateVoiceNote(updated);
      await _loadData();
      _clearInputs();
      _showMessage('Voice note updated successfully!');
    } catch (e, s) {
      AppLogger.error('Failed to update voice note', error: e, stackTrace: s);
      _showErrorDialog('Failed to update voice note.');
    }
  }

  /// Confirmation shared by the swipe gesture and the menu. Stops playback of
  /// the target note first so we never delete a file that's open in the player.
  Future<bool> _confirmDeleteNote(VoiceNote note) async {
    if (_playingNoteId == note.id) await _stopPlayback();
    if (!mounted) return false;
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Voice Note',
      message:
          'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    return confirmed == true;
  }

  Future<void> _deleteFromMenu(VoiceNote note) async {
    if (await _confirmDeleteNote(note)) {
      await _deleteNote(note);
    }
  }

  Future<void> _deleteNote(VoiceNote note) async {
    if (note.id == null) return;
    try {
      await _voiceNoteService.deleteVoiceNote(note.id!);
      await _loadData();
      HapticFeedback.lightImpact();
      _showMessage('Voice note deleted');
    } catch (e, s) {
      AppLogger.error('Failed to delete voice note', error: e, stackTrace: s);
      _showErrorDialog('Failed to delete voice note.');
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
      _showMessage('Cleaning up orphaned files…');
      final deletedCount =
          await _voiceNoteService.cleanupOrphanedFiles(userId: _userId);
      _showMessage('Cleaned up $deletedCount orphaned files');
      await _loadData();
    } catch (e, s) {
      AppLogger.error('Cleanup failed', error: e, stackTrace: s);
      _showErrorDialog('Cleanup failed.');
    }
  }

  Future<void> _exportMetadata() async {
    try {
      final metadata =
          await _voiceNoteService.exportMetadataAsJson(userId: _userId);
      if (!mounted) return;
      AppDialog.custom<void>(
        context,
        title: 'Export Metadata',
        icon: CupertinoIcons.square_arrow_down,
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
    } catch (e, s) {
      AppLogger.error('Export failed', error: e, stackTrace: s);
      _showErrorDialog('Export failed.');
    }
  }

  /// MM:SS for stats (always 2-digit minutes).
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  /// M:SS clock for the recorder/player (Apple Voice Memos style, e.g. 0:12).
  String _formatClock(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    AppSnackbar.show(
      context,
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
