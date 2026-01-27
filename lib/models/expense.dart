/// Model for car expenses
class Expense {
  final int? id;
  final int carId;
  final String category; // fuel, maintenance, insurance, repair, etc.
  final double amount;
  final DateTime date;
  final String? description;
  final String? receiptImage;
  final DateTime createdAt;
  final String userId;

  Expense({
    this.id,
    required this.carId,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.receiptImage,
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'category': category,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'receipt_image': receiptImage,
      'created_at': createdAt.millisecondsSinceEpoch,
      'user_id': userId,
    };
  }

  /// Create from database Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toInt(),
      carId: map['car_id']?.toInt() ?? 0,
      category: map['category'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      description: map['description'],
      receiptImage: map['receipt_image'],
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
      'amount': amount,
      'date': date,
      'description': description,
      'receipt_image': receiptImage,
      'created_at': createdAt,
      'user_id': userId,
    };
  }

  /// Create from Firestore
  factory Expense.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: data['local_id']?.toInt(),
      carId: data['car_id']?.toInt() ?? 0,
      category: data['category'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      description: data['description'],
      receiptImage: data['receipt_image'],
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  Expense copyWith({
    int? id,
    int? carId,
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    String? receiptImage,
    DateTime? createdAt,
    String? userId,
  }) {
    return Expense(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptImage: receiptImage ?? this.receiptImage,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, carId: $carId, category: $category, amount: $amount, date: $date)';
  }
}

/// Expense categories
class ExpenseCategory {
  static const String fuel = 'fuel';
  static const String maintenance = 'maintenance';
  static const String insurance = 'insurance';
  static const String repair = 'repair';
  static const String parking = 'parking';
  static const String toll = 'toll';
  static const String carWash = 'car_wash';
  static const String registration = 'registration';
  static const String other = 'other';

  static List<String> get all => [
        fuel,
        maintenance,
        insurance,
        repair,
        parking,
        toll,
        carWash,
        registration,
        other,
      ];

  static String getDisplayName(String category) {
    switch (category) {
      case fuel:
        return 'Fuel';
      case maintenance:
        return 'Maintenance';
      case insurance:
        return 'Insurance';
      case repair:
        return 'Repair';
      case parking:
        return 'Parking';
      case toll:
        return 'Toll';
      case carWash:
        return 'Car Wash';
      case registration:
        return 'Registration';
      case other:
        return 'Other';
      default:
        return category;
    }
  }
}

