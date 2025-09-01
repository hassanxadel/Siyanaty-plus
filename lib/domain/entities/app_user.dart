import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? profileImageUrl;
  final String role;
  final bool isActive;
  final UserPreferences preferences;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.profileImageUrl,
    this.role = 'user',
    this.isActive = true,
    required this.preferences,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      fullName: data['fullName'] as String,
      phoneNumber: data['phoneNumber'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      role: data['role'] as String? ?? 'user',
      isActive: data['isActive'] as bool? ?? true,
      preferences: UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>? ?? {}),
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>? ?? {}),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    try {
      // Handle Firestore Timestamp
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      // Handle String timestamps
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      // Handle DateTime objects
      if (timestamp is DateTime) {
        return timestamp;
      }
    } catch (e) {
      // If parsing fails, return null or current time for required fields
      return null;
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'isActive': isActive,
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profileImageUrl,
    String? role,
    bool? isActive,
    UserPreferences? preferences,
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class UserPreferences {
  final String theme;
  final bool notifications;
  final String language;

  const UserPreferences({
    this.theme = 'dark',
    this.notifications = true,
    this.language = 'en',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] as String? ?? 'dark',
      notifications: map['notifications'] as bool? ?? true,
      language: map['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'notifications': notifications,
      'language': language,
    };
  }
}

class UserStats {
  final int totalCars;
  final int totalMaintenanceRecords;
  final int totalReminders;

  const UserStats({
    this.totalCars = 0,
    this.totalMaintenanceRecords = 0,
    this.totalReminders = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalCars: map['totalCars'] as int? ?? 0,
      totalMaintenanceRecords: map['totalMaintenanceRecords'] as int? ?? 0,
      totalReminders: map['totalReminders'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCars': totalCars,
      'totalMaintenanceRecords': totalMaintenanceRecords,
      'totalReminders': totalReminders,
    };
  }

  UserStats copyWith({
    int? totalCars,
    int? totalMaintenanceRecords,
    int? totalReminders,
  }) {
    return UserStats(
      totalCars: totalCars ?? this.totalCars,
      totalMaintenanceRecords: totalMaintenanceRecords ?? this.totalMaintenanceRecords,
      totalReminders: totalReminders ?? this.totalReminders,
    );
  }
}
