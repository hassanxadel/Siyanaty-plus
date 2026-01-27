/// Model for budget tracking
class Budget {
  final int? id;
  final int carId;
  final String category;
  final double monthlyLimit;
  final double? alertThreshold; // percentage (e.g., 80 = alert at 80%)
  final DateTime createdAt;
  final String userId;

  Budget({
    this.id,
    required this.carId,
    required this.category,
    required this.monthlyLimit,
    this.alertThreshold,
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'category': category,
      'monthly_limit': monthlyLimit,
      'alert_threshold': alertThreshold,
      'created_at': createdAt.millisecondsSinceEpoch,
      'user_id': userId,
    };
  }

  /// Create from database Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id']?.toInt(),
      carId: map['car_id']?.toInt() ?? 0,
      category: map['category'] ?? '',
      monthlyLimit: (map['monthly_limit'] as num?)?.toDouble() ?? 0.0,
      alertThreshold: (map['alert_threshold'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      userId: map['user_id'] ?? '',
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'local_id': id,
      'car_id': carId,
      'category': category,
      'monthly_limit': monthlyLimit,
      'alert_threshold': alertThreshold,
      'created_at': createdAt,
      'user_id': userId,
    };
  }

  /// Create from Firestore
  factory Budget.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Budget(
      id: data['local_id']?.toInt(),
      carId: data['car_id']?.toInt() ?? 0,
      category: data['category'] ?? '',
      monthlyLimit: (data['monthly_limit'] as num?)?.toDouble() ?? 0.0,
      alertThreshold: (data['alert_threshold'] as num?)?.toDouble(),
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  Budget copyWith({
    int? id,
    int? carId,
    String? category,
    double? monthlyLimit,
    double? alertThreshold,
    DateTime? createdAt,
    String? userId,
  }) {
    return Budget(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, carId: $carId, category: $category, monthlyLimit: $monthlyLimit)';
  }
}

