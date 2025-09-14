class BackupReminder {
  final int? id;
  final int carId; // Reference to the car in the local database
  final String title;
  final String description;
  final ReminderType type;
  final ReminderPriority priority;
  final DateTime? targetDate;
  final int? targetMileage;
  final ReminderStatus status;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackupReminder({
    this.id,
    required this.carId,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.targetDate,
    this.targetMileage,
    required this.status,
    required this.isCompleted,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'target_date': targetDate?.toIso8601String(),
      'target_mileage': targetMileage,
      'status': status.name,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BackupReminder.fromMap(Map<String, dynamic> map) {
    return BackupReminder(
      id: map['id']?.toInt(),
      carId: map['car_id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.maintenance,
      ),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ReminderPriority.medium,
      ),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      targetMileage: map['target_mileage']?.toInt(),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReminderStatus.upcoming,
      ),
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'car_id': carId,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'target_date': targetDate?.toIso8601String(),
      'target_mileage': targetMileage,
      'status': status.name,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BackupReminder.fromFirebaseMap(Map<String, dynamic> map) {
    return BackupReminder(
      carId: map['car_id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.maintenance,
      ),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ReminderPriority.medium,
      ),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      targetMileage: map['target_mileage']?.toInt(),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReminderStatus.upcoming,
      ),
      isCompleted: map['is_completed'] ?? false,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  BackupReminder copyWith({
    int? id,
    int? carId,
    String? title,
    String? description,
    ReminderType? type,
    ReminderPriority? priority,
    DateTime? targetDate,
    int? targetMileage,
    ReminderStatus? status,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackupReminder(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      targetDate: targetDate ?? this.targetDate,
      targetMileage: targetMileage ?? this.targetMileage,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper method to get display text for the reminder
  String get displayText {
    if (targetDate != null && targetMileage != null) {
      return 'Due: ${_formatDate(targetDate!)} or ${targetMileage}km';
    } else if (targetDate != null) {
      return 'Due: ${_formatDate(targetDate!)}';
    } else if (targetMileage != null) {
      return 'Due: ${targetMileage}km';
    }
    return 'No due date set';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Check if reminder is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    
    final now = DateTime.now();
    if (targetDate != null && targetDate!.isBefore(now)) {
      return true;
    }
    
    // Note: For mileage-based reminders, we would need current car mileage
    // This would be checked in the service layer
    return false;
  }
}

enum ReminderType {
  maintenance,
  inspection,
  insurance,
  registration,
  oilChange,
  tireRotation,
  brakeService,
  custom
}

enum ReminderPriority {
  low,
  medium,
  high,
  urgent
}

enum ReminderStatus {
  upcoming,
  overdue,
  completed
}

// Extension to get display names and icons
extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.maintenance:
        return 'Maintenance';
      case ReminderType.inspection:
        return 'Inspection';
      case ReminderType.insurance:
        return 'Insurance';
      case ReminderType.registration:
        return 'Registration';
      case ReminderType.oilChange:
        return 'Oil Change';
      case ReminderType.tireRotation:
        return 'Tire Rotation';
      case ReminderType.brakeService:
        return 'Brake Service';
      case ReminderType.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.maintenance:
        return '🔧';
      case ReminderType.inspection:
        return '🔍';
      case ReminderType.insurance:
        return '📋';
      case ReminderType.registration:
        return '📄';
      case ReminderType.oilChange:
        return '🛢️';
      case ReminderType.tireRotation:
        return '🛞';
      case ReminderType.brakeService:
        return '🛑';
      case ReminderType.custom:
        return '📝';
    }
  }
}

extension ReminderPriorityExtension on ReminderPriority {
  String get displayName {
    switch (this) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.urgent:
        return 'Urgent';
    }
  }

  String get colorHex {
    switch (this) {
      case ReminderPriority.low:
        return '#4CAF50'; // Green
      case ReminderPriority.medium:
        return '#FF9800'; // Orange
      case ReminderPriority.high:
        return '#F44336'; // Red
      case ReminderPriority.urgent:
        return '#9C27B0'; // Purple
    }
  }
}

/// Class for reminders with car information for display purposes
class ReminderWithCarInfo {
  final BackupReminder reminder;
  final String carBrand;
  final String carModel;
  final int carYear;
  final String carLicensePlate;

  ReminderWithCarInfo({
    required this.reminder,
    required this.carBrand,
    required this.carModel,
    required this.carYear,
    required this.carLicensePlate,
  });

  factory ReminderWithCarInfo.fromMap(Map<String, dynamic> map) {
    return ReminderWithCarInfo(
      reminder: BackupReminder.fromMap(map),
      carBrand: map['car_brand'] ?? '',
      carModel: map['car_model'] ?? '',
      carYear: map['car_year']?.toInt() ?? 0,
      carLicensePlate: map['car_license_plate'] ?? '',
    );
  }

  String get carDisplayName => '$carBrand $carModel ($carYear)';
}
