class ScanModel {
  final int? id;
  final String text;
  final String? imagePath;
  final String source; // 'mlkit', 'cloud', 'manual'
  final DateTime timestamp;
  final String? userId;

  ScanModel({
    this.id,
    required this.text,
    this.imagePath,
    required this.source,
    required this.timestamp,
    this.userId,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imagePath': imagePath,
      'source': source,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'user_id': userId, // Changed to snake_case for database
    };
  }

  // Create from Map (database)
  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      id: map['id'],
      text: map['text'] ?? '',
      imagePath: map['imagePath'],
      source: map['source'] ?? 'mlkit',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      userId: map['user_id'] ?? map['userId'], // Support both snake_case and camelCase
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'imagePath': imagePath,
      'source': source,
      'timestamp': timestamp,
      'userId': userId,
    };
  }

  // Create from Firestore
  factory ScanModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ScanModel(
      id: documentId.hashCode, // Use document ID hash as local ID
      text: data['text'] ?? '',
      imagePath: data['imagePath'],
      source: data['source'] ?? 'mlkit',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      userId: data['userId'],
    );
  }

  // Create a copy with updated fields
  ScanModel copyWith({
    int? id,
    String? text,
    String? imagePath,
    String? source,
    DateTime? timestamp,
    String? userId,
  }) {
    return ScanModel(
      id: id ?? this.id,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'ScanModel(id: $id, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, source: $source, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanModel &&
        other.id == id &&
        other.text == text &&
        other.imagePath == imagePath &&
        other.source == source &&
        other.timestamp == timestamp &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        imagePath.hashCode ^
        source.hashCode ^
        timestamp.hashCode ^
        userId.hashCode;
  }
}
