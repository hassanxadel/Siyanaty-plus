class VoiceNote {
  final int? id;
  final String title;
  final String? description;
  final String filePath;
  final int duration; // Duration in seconds
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  VoiceNote({
    this.id,
    required this.title,
    this.description,
    required this.filePath,
    required this.duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from database map
  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      // Handle both snake_case (database) and camelCase (legacy)
      filePath: (map['file_path'] ?? map['filePath']) as String,
      duration: map['duration'] as int,
      createdAt: DateTime.parse((map['created_at'] ?? map['createdAt']) as String),
      updatedAt: DateTime.parse((map['updated_at'] ?? map['updatedAt']) as String),
      userId: (map['user_id'] ?? map['userId']) as String?,
    );
  }

  // Convert to database map (using snake_case for database columns)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_path': filePath,  // Use snake_case for database
      'duration': duration,
      'created_at': createdAt.toIso8601String(),  // Use snake_case for database
      'updated_at': updatedAt.toIso8601String(),  // Use snake_case for database
      'user_id': userId,  // Use snake_case for database
    };
  }

  // Create a copy with updated values
  VoiceNote copyWith({
    int? id,
    String? title,
    String? description,
    String? filePath,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId ?? this.userId,
    );
  }

  // Format duration as MM:SS
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'VoiceNote(id: $id, title: $title, duration: $duration, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceNote &&
        other.id == id &&
        other.title == title &&
        other.filePath == filePath &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        filePath.hashCode ^
        duration.hashCode;
  }
}
