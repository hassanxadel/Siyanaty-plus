import 'dart:convert';

/// Model for trip logging
class Trip {
  final int? id;
  final int carId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? startLocation;
  final String? endLocation;
  final double? distance; // in kilometers
  final String tripType; // business, personal
  final String? purpose;
  final List<Map<String, double>>? routeData; // List of lat/lng coordinates
  final DateTime createdAt;
  final String userId;

  Trip({
    this.id,
    required this.carId,
    required this.startTime,
    this.endTime,
    this.startLocation,
    this.endLocation,
    this.distance,
    required this.tripType,
    this.purpose,
    this.routeData,
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'start_location': startLocation,
      'end_location': endLocation,
      'distance': distance,
      'trip_type': tripType,
      'purpose': purpose,
      'route_data': routeData != null ? jsonEncode(routeData) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'user_id': userId,
    };
  }

  /// Create from database Map
  factory Trip.fromMap(Map<String, dynamic> map) {
    List<Map<String, double>>? parsedRoute;
    if (map['route_data'] != null && map['route_data'] is String) {
      try {
        final decoded = jsonDecode(map['route_data'] as String) as List;
        parsedRoute = decoded.map((e) => Map<String, double>.from(e as Map)).toList();
      } catch (e) {
        parsedRoute = null;
      }
    }

    return Trip(
      id: map['id']?.toInt(),
      carId: map['car_id']?.toInt() ?? 0,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] ?? 0),
      endTime: map['end_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end_time']) : null,
      startLocation: map['start_location'],
      endLocation: map['end_location'],
      distance: (map['distance'] as num?)?.toDouble(),
      tripType: map['trip_type'] ?? TripType.personal,
      purpose: map['purpose'],
      routeData: parsedRoute,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      userId: map['user_id'] ?? '',
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'local_id': id,
      'car_id': carId,
      'start_time': startTime,
      'end_time': endTime,
      'start_location': startLocation,
      'end_location': endLocation,
      'distance': distance,
      'trip_type': tripType,
      'purpose': purpose,
      'route_data': routeData,
      'created_at': createdAt,
      'user_id': userId,
    };
  }

  /// Create from Firestore
  factory Trip.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<Map<String, double>>? parsedRoute;
    if (data['route_data'] != null && data['route_data'] is List) {
      try {
        parsedRoute = (data['route_data'] as List)
            .map((e) => Map<String, double>.from(e as Map))
            .toList();
      } catch (e) {
        parsedRoute = null;
      }
    }

    return Trip(
      id: data['local_id']?.toInt(),
      carId: data['car_id']?.toInt() ?? 0,
      startTime: (data['start_time'] as dynamic)?.toDate() ?? DateTime.now(),
      endTime: data['end_time'] != null ? (data['end_time'] as dynamic).toDate() : null,
      startLocation: data['start_location'],
      endLocation: data['end_location'],
      distance: (data['distance'] as num?)?.toDouble(),
      tripType: data['trip_type'] ?? TripType.personal,
      purpose: data['purpose'],
      routeData: parsedRoute,
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  /// Get duration in minutes
  int? getDurationMinutes() {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMinutes;
  }

  /// Get duration as formatted string
  String? getDurationString() {
    final minutes = getDurationMinutes();
    if (minutes == null) return null;
    
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  Trip copyWith({
    int? id,
    int? carId,
    DateTime? startTime,
    DateTime? endTime,
    String? startLocation,
    String? endLocation,
    double? distance,
    String? tripType,
    String? purpose,
    List<Map<String, double>>? routeData,
    DateTime? createdAt,
    String? userId,
  }) {
    return Trip(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      distance: distance ?? this.distance,
      tripType: tripType ?? this.tripType,
      purpose: purpose ?? this.purpose,
      routeData: routeData ?? this.routeData,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, carId: $carId, startTime: $startTime, distance: $distance, tripType: $tripType)';
  }
}

/// Trip types
class TripType {
  static const String business = 'business';
  static const String personal = 'personal';

  static List<String> get all => [business, personal];

  static String getDisplayName(String type) {
    switch (type) {
      case business:
        return 'Business';
      case personal:
        return 'Personal';
      default:
        return type;
    }
  }
}

