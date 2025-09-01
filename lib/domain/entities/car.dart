class Car {
  final String id;
  final String userId;
  final String name;
  final String make;
  final String model;
  final int year;
  final String? vin;
  final String? licensePlate;
  final String color;
  final String engine;
  final String transmission;
  final String fuelType;
  final double currentMileage;
  final DateTime? lastServiceDate;
  final DateTime? purchaseDate;
  final String? imageUrl;
  final CarHealth health;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.userId,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    this.licensePlate,
    required this.color,
    required this.engine,
    required this.transmission,
    required this.fuelType,
    required this.currentMileage,
    this.lastServiceDate,
    this.purchaseDate,
    this.imageUrl,
    required this.health,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$year $make $model';

  double get healthPercentage => health.overallScore;

  String get formattedMileage => '${currentMileage.toStringAsFixed(0)} km';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'licensePlate': licensePlate,
      'color': color,
      'engine': engine,
      'transmission': transmission,
      'fuelType': fuelType,
      'currentMileage': currentMileage,
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'purchaseDate': purchaseDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'health': health.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'licensePlate': licensePlate,
      'color': color,
      'mileage': currentMileage,
      'fuelType': fuelType,
      'engineSize': engine,
      'transmission': transmission,
      'imagePath': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      vin: json['vin'] as String?,
      licensePlate: json['licensePlate'] as String?,
      color: json['color'] as String,
      engine: json['engine'] as String,
      transmission: json['transmission'] as String,
      fuelType: json['fuelType'] as String,
      currentMileage: (json['currentMileage'] as num).toDouble(),
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.parse(json['lastServiceDate'] as String)
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      health: CarHealth.fromJson(json['health'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: '${map['year']} ${map['make']} ${map['model']}',
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      vin: map['vin'] as String?,
      licensePlate: map['licensePlate'] as String?,
      color: map['color'] as String? ?? 'Unknown',
      engine: map['engineSize'] as String? ?? 'Unknown',
      transmission: map['transmission'] as String? ?? 'Unknown',
      fuelType: map['fuelType'] as String? ?? 'Unknown',
      currentMileage: (map['mileage'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imagePath'] as String?,
      health: CarHealth.initial(),
      isActive: (map['isActive'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Car copyWith({
    String? id,
    String? userId,
    String? name,
    String? make,
    String? model,
    int? year,
    String? vin,
    String? licensePlate,
    String? color,
    String? engine,
    String? transmission,
    String? fuelType,
    double? currentMileage,
    DateTime? lastServiceDate,
    DateTime? purchaseDate,
    String? imageUrl,
    CarHealth? health,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Car(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      engine: engine ?? this.engine,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      currentMileage: currentMileage ?? this.currentMileage,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      imageUrl: imageUrl ?? this.imageUrl,
      health: health ?? this.health,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CarHealth {
  final double overallScore;
  final ComponentHealth engine;
  final ComponentHealth brakes;
  final ComponentHealth battery;
  final ComponentHealth tires;
  final ComponentHealth fluids;
  final DateTime lastUpdated;
  final List<String> warnings;
  final List<String> recommendations;

  CarHealth({
    required this.overallScore,
    required this.engine,
    required this.brakes,
    required this.battery,
    required this.tires,
    required this.fluids,
    required this.lastUpdated,
    this.warnings = const [],
    this.recommendations = const [],
  });

  factory CarHealth.initial() {
    return CarHealth(
      overallScore: 100.0,
      engine: ComponentHealth.good(),
      brakes: ComponentHealth.good(),
      battery: ComponentHealth.good(),
      tires: ComponentHealth.good(),
      fluids: ComponentHealth.good(),
      lastUpdated: DateTime.now(),
      warnings: [],
      recommendations: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'engine': engine.toJson(),
      'brakes': brakes.toJson(),
      'battery': battery.toJson(),
      'tires': tires.toJson(),
      'fluids': fluids.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'warnings': warnings,
      'recommendations': recommendations,
    };
  }

  factory CarHealth.fromJson(Map<String, dynamic> json) {
    return CarHealth(
      overallScore: (json['overallScore'] as num).toDouble(),
      engine: ComponentHealth.fromJson(json['engine'] as Map<String, dynamic>),
      brakes: ComponentHealth.fromJson(json['brakes'] as Map<String, dynamic>),
      battery: ComponentHealth.fromJson(json['battery'] as Map<String, dynamic>),
      tires: ComponentHealth.fromJson(json['tires'] as Map<String, dynamic>),
      fluids: ComponentHealth.fromJson(json['fluids'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      warnings: List<String>.from(json['warnings'] as List? ?? []),
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
    );
  }
}

class ComponentHealth {
  final HealthStatus status;
  final double score;
  final DateTime lastChecked;
  final String? notes;

  ComponentHealth({
    required this.status,
    required this.score,
    required this.lastChecked,
    this.notes,
  });

  factory ComponentHealth.good() {
    return ComponentHealth(
      status: HealthStatus.good,
      score: 100.0,
      lastChecked: DateTime.now(),
    );
  }

  factory ComponentHealth.warning() {
    return ComponentHealth(
      status: HealthStatus.warning,
      score: 70.0,
      lastChecked: DateTime.now(),
    );
  }

  factory ComponentHealth.critical() {
    return ComponentHealth(
      status: HealthStatus.critical,
      score: 30.0,
      lastChecked: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'score': score,
      'lastChecked': lastChecked.toIso8601String(),
      'notes': notes,
    };
  }

  factory ComponentHealth.fromJson(Map<String, dynamic> json) {
    return ComponentHealth(
      status: HealthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HealthStatus.good,
      ),
      score: (json['score'] as num).toDouble(),
      lastChecked: DateTime.parse(json['lastChecked'] as String),
      notes: json['notes'] as String?,
    );
  }
}

enum HealthStatus { good, warning, critical }