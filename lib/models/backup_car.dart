/// Car model for backup system - compatible with the add car form
/// Contains all necessary fields for car management and backup
class BackupCar {
  final int? id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String color;
  final String fuelType;
  final String engineCC;
  final bool turbo;
  final String licensePlate;
  final String vin;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackupCar({
    this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.color,
    required this.fuelType,
    required this.engineCC,
    required this.turbo,
    required this.licensePlate,
    required this.vin,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Convert BackupCar object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
      'color': color,
      'fuel_type': fuelType,
      'engine_cc': engineCC,
      'turbo': turbo ? 1 : 0,
      'license_plate': licensePlate,
      'vin': vin,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert BackupCar object to Map for Firebase operations
  Map<String, dynamic> toFirebaseMap() {
    return {
      'user_id': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
      'color': color,
      'fuel_type': fuelType,
      'engine_cc': engineCC,
      'turbo': turbo,
      'license_plate': licensePlate,
      'vin': vin,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create BackupCar object from database Map
  factory BackupCar.fromMap(Map<String, dynamic> map) {
    return BackupCar(
      id: map['id']?.toInt(),
      userId: map['user_id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      mileage: map['mileage']?.toInt() ?? 0,
      color: map['color'] ?? '',
      fuelType: map['fuel_type'] ?? '',
      engineCC: map['engine_cc'] ?? '',
      turbo: map['turbo'] == 1,
      licensePlate: map['license_plate'] ?? '',
      vin: map['vin'] ?? '',
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Create BackupCar object from Firebase Map
  factory BackupCar.fromFirebaseMap(Map<String, dynamic> map) {
    return BackupCar(
      userId: map['user_id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      mileage: map['mileage']?.toInt() ?? 0,
      color: map['color'] ?? '',
      fuelType: map['fuel_type'] ?? '',
      engineCC: map['engine_cc'] ?? '',
      turbo: map['turbo'] ?? false,
      licensePlate: map['license_plate'] ?? '',
      vin: map['vin'] ?? '',
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Create a copy of BackupCar with updated fields
  BackupCar copyWith({
    int? id,
    String? userId,
    String? brand,
    String? model,
    int? year,
    int? mileage,
    String? color,
    String? fuelType,
    String? engineCC,
    bool? turbo,
    String? licensePlate,
    String? vin,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackupCar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      color: color ?? this.color,
      fuelType: fuelType ?? this.fuelType,
      engineCC: engineCC ?? this.engineCC,
      turbo: turbo ?? this.turbo,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'BackupCar{id: $id, brand: $brand, model: $model, year: $year, licensePlate: $licensePlate}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupCar &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vin == other.vin;

  @override
  int get hashCode => id.hashCode ^ vin.hashCode;
}
