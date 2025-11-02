import 'package:cloud_firestore/cloud_firestore.dart';

class MileageEntry {
  final int? id;
  final double mileage;
  final double fuel;
  final double cost;
  final DateTime date;
  final String? notes;
  final String? entryName;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MileageEntry({
    this.id,
    required this.mileage,
    required this.fuel,
    required this.cost,
    required this.date,
    this.notes,
    this.entryName,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Create from database map
  factory MileageEntry.fromMap(Map<String, dynamic> map) {
    return MileageEntry(
      id: map['id'] as int?,
      mileage: (map['mileage'] as num).toDouble(),
      fuel: (map['fuel'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      entryName: map['entryName'] as String?,
      userId: map['userId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mileage': mileage,
      'fuel': fuel,
      'cost': cost,
      'date': date.toIso8601String(),
      'notes': notes,
      'entryName': entryName,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory MileageEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MileageEntry(
      id: null, // Firestore doesn't use integer IDs
      mileage: (data['mileage'] as num).toDouble(),
      fuel: (data['fuel'] as num).toDouble(),
      cost: (data['cost'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      entryName: data['entryName'] as String?,
      userId: data['userId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'mileage': mileage,
      'fuel': fuel,
      'cost': cost,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'entryName': entryName,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
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
