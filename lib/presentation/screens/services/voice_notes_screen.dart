import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  bool _isRecording = false;
  bool _isPlaying = false;
  List<VoiceNote> _voiceNotes = [];
  int _currentPlayingIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSampleNotes();
  }

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
                  _buildRecordingCard(),
                  const SizedBox(height: 24),
                  if (_voiceNotes.isNotEmpty) _buildNotesList(),
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
                    'Voice Notes',
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
                  'Quick Maintenance Notes & Reminders',
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
                'How to Use Voice Notes',
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
            'Start Recording',
            'Tap the microphone button to begin recording your maintenance note or reminder.',
            Icons.mic,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Speak Clearly',
            'Hold your device close and speak clearly about the maintenance task, issue, or reminder.',
            Icons.record_voice_over,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Save & Organize',
            'Your voice note will be automatically transcribed and saved with a timestamp for easy access.',
            Icons.save,
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

  Widget _buildRecordingCard() {
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
            'Voice Recorder',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isRecording 
                    ? AppTheme.errorColor.withOpacity(0.3)
                    : AppTheme.primaryGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: _isRecording 
                      ? AppTheme.errorColor
                      : AppTheme.primaryGreen,
                  width: 3,
                ),
              ),
              child: IconButton(
                onPressed: _toggleRecording,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording 
                      ? AppTheme.errorColor
                      : AppTheme.primaryGreen,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isRecording 
                    ? AppTheme.errorColor
                    : (Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black),
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recording in progress...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesList() {
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
                Icons.notes,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Voice Notes',
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
          ..._voiceNotes.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            return _buildNoteItem(index, note);
          }),
        ],
      ),
    );
  }

  Widget _buildNoteItem(int index, VoiceNote note) {
    final isPlaying = _currentPlayingIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying 
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withOpacity(0.3),
          width: isPlaying ? 2 : 1,
        ),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.timestamp,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.7) : Colors.black54,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _togglePlayback(index),
                icon: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying 
                      ? AppTheme.errorColor
                      : AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () => _deleteNote(index),
                icon: const Icon(
                  Icons.delete,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.transcription,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.9) : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: AppTheme.secondaryGreen,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${note.duration} seconds',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }

    HapticFeedback.lightImpact();
  }

  void _startRecording() {
    // Simulate recording start
    _showMessage('Recording started...');
  }

  void _stopRecording() async {
    // Simulate recording stop and processing
    _showMessage('Processing your voice note...');
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Add new voice note
    final newNote = VoiceNote(
      title: 'Maintenance Note ${_voiceNotes.length + 1}',
      transcription: 'This is a sample transcription of your voice note about vehicle maintenance. You can edit this text to add more details.',
      timestamp: DateTime.now().toString().substring(0, 19),
      duration: '15',
    );
    
    setState(() {
      _voiceNotes.insert(0, newNote);
    });
    
    _showMessage('Voice note saved successfully!');
  }

  void _togglePlayback(int index) {
    setState(() {
      if (_currentPlayingIndex == index) {
        _currentPlayingIndex = -1;
        _isPlaying = false;
      } else {
        _currentPlayingIndex = index;
        _isPlaying = true;
      }
    });
    
    HapticFeedback.lightImpact();
    
    if (_isPlaying) {
      _showMessage('Playing voice note...');
    } else {
      _showMessage('Playback stopped');
    }
  }

  void _deleteNote(int index) {
    setState(() {
      _voiceNotes.removeAt(index);
      if (_currentPlayingIndex == index) {
        _currentPlayingIndex = -1;
        _isPlaying = false;
      } else if (_currentPlayingIndex > index) {
        _currentPlayingIndex--;
      }
    });
    
    HapticFeedback.lightImpact();
    _showMessage('Voice note deleted');
  }

  void _loadSampleNotes() {
    _voiceNotes = [
      VoiceNote(
        title: 'Oil Change Reminder',
        transcription: 'Need to change oil at 50,000 km. Check oil level weekly and top up if needed.',
        timestamp: '2024-01-15 10:30:00',
        duration: '12',
      ),
      VoiceNote(
        title: 'Brake Inspection',
        transcription: 'Brakes feel soft, need to inspect brake pads and fluid levels. Schedule appointment with mechanic.',
        timestamp: '2024-01-14 16:45:00',
        duration: '18',
      ),
      VoiceNote(
        title: 'Tire Rotation',
        transcription: 'Tires need rotation at 45,000 km. Check tire pressure monthly and maintain proper inflation.',
        timestamp: '2024-01-13 09:15:00',
        duration: '14',
      ),
    ];
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

class VoiceNote {
  final String title;
  final String transcription;
  final String timestamp;
  final String duration;

  VoiceNote({
    required this.title,
    required this.transcription,
    required this.timestamp,
    required this.duration,
  });
}
