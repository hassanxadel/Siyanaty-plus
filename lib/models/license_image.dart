class LicenseImage {
  final int? id;
  final int carId;
  final String licenseType; // 'personal' or 'vehicle'
  final String imagePath;
  final String? imageUrl; // Firebase storage URL
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  LicenseImage({
    this.id,
    required this.carId,
    required this.licenseType,
    required this.imagePath,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'licenseType': licenseType,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  factory LicenseImage.fromMap(Map<String, dynamic> map) {
    return LicenseImage(
      id: map['id']?.toInt(),
      carId: map['carId']?.toInt() ?? 0,
      licenseType: map['licenseType'] ?? '',
      imagePath: map['imagePath'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      userId: map['userId'],
    );
  }

  // For Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'carId': carId,
      'licenseType': licenseType,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
    };
  }

  factory LicenseImage.fromFirestore(Map<String, dynamic> data, String documentId) {
    return LicenseImage(
      id: int.tryParse(documentId),
      carId: data['carId']?.toInt() ?? 0,
      licenseType: data['licenseType'] ?? '',
      imagePath: data['imagePath'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['userId'],
    );
  }

  LicenseImage copyWith({
    int? id,
    int? carId,
    String? licenseType,
    String? imagePath,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return LicenseImage(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      licenseType: licenseType ?? this.licenseType,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'LicenseImage(id: $id, carId: $carId, licenseType: $licenseType, imagePath: $imagePath, imageUrl: $imageUrl, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LicenseImage &&
      other.id == id &&
      other.carId == carId &&
      other.licenseType == licenseType &&
      other.imagePath == imagePath &&
      other.imageUrl == imageUrl &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      carId.hashCode ^
      licenseType.hashCode ^
      imagePath.hashCode ^
      imageUrl.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      userId.hashCode;
  }
}
