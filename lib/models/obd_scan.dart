/// Model for OBD-II scan data
class OBDScan {
  final int? id;
  final int carId;
  final DateTime scanDate;
  final double? rpm;
  final double? speed;
  final double? coolantTemp;
  final double? fuelLevel;
  final double? throttlePosition;
  final double? engineLoad;
  final List<String> errorCodes;
  final String? notes;
  final DateTime createdAt;

  OBDScan({
    this.id,
    required this.carId,
    required this.scanDate,
    this.rpm,
    this.speed,
    this.coolantTemp,
    this.fuelLevel,
    this.throttlePosition,
    this.engineLoad,
    this.errorCodes = const [],
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'scan_date': scanDate.millisecondsSinceEpoch,
      'rpm': rpm,
      'speed': speed,
      'coolant_temp': coolantTemp,
      'fuel_level': fuelLevel,
      'throttle_position': throttlePosition,
      'engine_load': engineLoad,
      'error_codes': errorCodes.join(','), // Store as comma-separated string
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database Map
  factory OBDScan.fromMap(Map<String, dynamic> map) {
    return OBDScan(
      id: map['id']?.toInt(),
      carId: map['car_id']?.toInt() ?? 0,
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scan_date'] ?? 0),
      rpm: map['rpm']?.toDouble(),
      speed: map['speed']?.toDouble(),
      coolantTemp: map['coolant_temp']?.toDouble(),
      fuelLevel: map['fuel_level']?.toDouble(),
      throttlePosition: map['throttle_position']?.toDouble(),
      engineLoad: map['engine_load']?.toDouble(),
      errorCodes: (map['error_codes'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'local_id': id,
      'car_id': carId,
      'scan_date': scanDate,
      'rpm': rpm,
      'speed': speed,
      'coolant_temp': coolantTemp,
      'fuel_level': fuelLevel,
      'throttle_position': throttlePosition,
      'engine_load': engineLoad,
      'error_codes': errorCodes,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  /// Create from Firestore
  factory OBDScan.fromFirestore(Map<String, dynamic> data, String documentId) {
    return OBDScan(
      id: data['local_id']?.toInt(),
      carId: data['car_id']?.toInt() ?? 0,
      scanDate: (data['scan_date'] as dynamic)?.toDate() ?? DateTime.now(),
      rpm: data['rpm']?.toDouble(),
      speed: data['speed']?.toDouble(),
      coolantTemp: data['coolant_temp']?.toDouble(),
      fuelLevel: data['fuel_level']?.toDouble(),
      throttlePosition: data['throttle_position']?.toDouble(),
      engineLoad: data['engine_load']?.toDouble(),
      errorCodes: (data['error_codes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: data['notes'],
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  OBDScan copyWith({
    int? id,
    int? carId,
    DateTime? scanDate,
    double? rpm,
    double? speed,
    double? coolantTemp,
    double? fuelLevel,
    double? throttlePosition,
    double? engineLoad,
    List<String>? errorCodes,
    String? notes,
    DateTime? createdAt,
  }) {
    return OBDScan(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      scanDate: scanDate ?? this.scanDate,
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      coolantTemp: coolantTemp ?? this.coolantTemp,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      engineLoad: engineLoad ?? this.engineLoad,
      errorCodes: errorCodes ?? this.errorCodes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OBDScan(id: $id, carId: $carId, scanDate: $scanDate, rpm: $rpm, speed: $speed, errorCodes: $errorCodes)';
  }
}

