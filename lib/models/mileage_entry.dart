import 'package:cloud_firestore/cloud_firestore.dart';

/// Trip frequency types for automated mileage calculation
enum TripFrequency {
  oneTime,    // One-time trip, no repetition
  daily,      // Daily trip (e.g., commute)
  weekly,     // Weekly trip
  monthly,    // Monthly trip
}

/// Extension to get display names for trip frequencies
extension TripFrequencyExtension on TripFrequency {
  String get displayName {
    switch (this) {
      case TripFrequency.oneTime:
        return 'One-Time Trip';
      case TripFrequency.daily:
        return 'Daily Trip';
      case TripFrequency.weekly:
        return 'Weekly Trip';
      case TripFrequency.monthly:
        return 'Monthly Trip';
    }
  }

  String get description {
    switch (this) {
      case TripFrequency.oneTime:
        return 'This trip will be counted once';
      case TripFrequency.daily:
        return 'Mileage added daily to your car';
      case TripFrequency.weekly:
        return 'Mileage added weekly to your car';
      case TripFrequency.monthly:
        return 'Mileage added monthly to your car';
    }
  }
}

class MileageEntry {
  final int? id;
  final double mileage;
  final double fuel;
  final double cost;
  final DateTime date;
  final String? notes;
  final String? entryName;
  final String? userId;
  final String? carId;  // Link to specific car
  final TripFrequency tripFrequency;  // How often this trip occurs
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The last time this recurring entry's mileage was credited to the car by
  /// the background updater. Null until first credited (treated as
  /// [createdAt]). Drives the catch-up math so mileage is never double-counted
  /// or missed regardless of when the periodic task actually runs.
  final DateTime? lastAppliedAt;

  MileageEntry({
    this.id,
    required this.mileage,
    required this.fuel,
    required this.cost,
    required this.date,
    this.notes,
    this.entryName,
    this.userId,
    this.carId,
    this.tripFrequency = TripFrequency.oneTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastAppliedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from database map
  factory MileageEntry.fromMap(Map<String, dynamic> map) {
    // Parse trip frequency from string
    TripFrequency parseTripFrequency(String? value) {
      if (value == null) return TripFrequency.oneTime;
      switch (value) {
        case 'daily':
          return TripFrequency.daily;
        case 'weekly':
          return TripFrequency.weekly;
        case 'monthly':
          return TripFrequency.monthly;
        default:
          return TripFrequency.oneTime;
      }
    }

    return MileageEntry(
      id: map['id'] as int?,
      mileage: (map['mileage'] as num).toDouble(),
      fuel: (map['fuel'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      // Handle both snake_case (database) and camelCase (legacy)
      entryName: map['entry_name'] as String? ?? map['entryName'] as String?,
      userId: map['user_id'] as String? ?? map['userId'] as String?,
      carId: map['car_id'] as String? ?? map['carId'] as String?,
      tripFrequency: parseTripFrequency(map['trip_frequency'] as String? ?? map['tripFrequency'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String? ?? map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['updatedAt'] as String),
      lastAppliedAt: (map['last_applied_at'] ?? map['lastAppliedAt']) != null
          ? DateTime.parse(map['last_applied_at'] as String? ?? map['lastAppliedAt'] as String)
          : null,
    );
  }

  // Convert to database map (using snake_case for database columns)
  Map<String, dynamic> toMap() {
    String tripFrequencyToString(TripFrequency freq) {
      switch (freq) {
        case TripFrequency.daily:
          return 'daily';
        case TripFrequency.weekly:
          return 'weekly';
        case TripFrequency.monthly:
          return 'monthly';
        default:
          return 'oneTime';
      }
    }

    return {
      'id': id,
      'mileage': mileage,
      'fuel': fuel,
      'cost': cost,
      'date': date.toIso8601String(),
      'notes': notes,
      'entry_name': entryName,  // Use snake_case for database
      'user_id': userId,         // Use snake_case for database
      'car_id': carId,           // Use snake_case for database
      'trip_frequency': tripFrequencyToString(tripFrequency),  // Use snake_case for database
      'created_at': createdAt.toIso8601String(),  // Use snake_case for database
      'updated_at': updatedAt.toIso8601String(),  // Use snake_case for database
      'last_applied_at': lastAppliedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory MileageEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    TripFrequency parseTripFrequency(String? value) {
      if (value == null) return TripFrequency.oneTime;
      switch (value) {
        case 'daily':
          return TripFrequency.daily;
        case 'weekly':
          return TripFrequency.weekly;
        case 'monthly':
          return TripFrequency.monthly;
        default:
          return TripFrequency.oneTime;
      }
    }

    return MileageEntry(
      id: null, // Firestore doesn't use integer IDs
      mileage: (data['mileage'] as num).toDouble(),
      fuel: (data['fuel'] as num).toDouble(),
      cost: (data['cost'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      entryName: data['entryName'] as String?,
      userId: data['userId'] as String?,
      carId: data['carId'] as String?,
      tripFrequency: parseTripFrequency(data['tripFrequency'] as String?),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastAppliedAt: data['lastAppliedAt'] != null
          ? (data['lastAppliedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    String tripFrequencyToString(TripFrequency freq) {
      switch (freq) {
        case TripFrequency.daily:
          return 'daily';
        case TripFrequency.weekly:
          return 'weekly';
        case TripFrequency.monthly:
          return 'monthly';
        default:
          return 'oneTime';
      }
    }

    return {
      'mileage': mileage,
      'fuel': fuel,
      'cost': cost,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'entryName': entryName,
      'userId': userId,
      'carId': carId,
      'tripFrequency': tripFrequencyToString(tripFrequency),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastAppliedAt':
          lastAppliedAt != null ? Timestamp.fromDate(lastAppliedAt!) : null,
    };
  }

  // Create a copy with updated values
  MileageEntry copyWith({
    int? id,
    double? mileage,
    double? fuel,
    double? cost,
    DateTime? date,
    String? notes,
    String? entryName,
    String? userId,
    String? carId,
    TripFrequency? tripFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAppliedAt,
  }) {
    return MileageEntry(
      id: id ?? this.id,
      mileage: mileage ?? this.mileage,
      fuel: fuel ?? this.fuel,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      entryName: entryName ?? this.entryName,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      tripFrequency: tripFrequency ?? this.tripFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastAppliedAt: lastAppliedAt ?? this.lastAppliedAt,
    );
  }

  // Calculate fuel efficiency (L/100km)
  double calculateEfficiency(double distanceDriven) {
    if (distanceDriven <= 0) return 0;
    return (fuel / distanceDriven) * 100;
  }

  @override
  String toString() {
    return 'MileageEntry(id: $id, mileage: $mileage, fuel: $fuel, cost: $cost, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MileageEntry &&
        other.id == id &&
        other.mileage == mileage &&
        other.fuel == fuel &&
        other.cost == cost &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        mileage.hashCode ^
        fuel.hashCode ^
        cost.hashCode ^
        date.hashCode;
  }
}
