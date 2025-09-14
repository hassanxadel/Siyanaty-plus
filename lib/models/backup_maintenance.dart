
enum MaintenanceType {
  mechanics,
  electrical,
  suspension,
  others;


  String get displayName {
    switch (this) {
      case MaintenanceType.mechanics:
        return 'Mechanics';
      case MaintenanceType.electrical:
        return 'Electrical';
      case MaintenanceType.suspension:
        return 'Suspension';
      case MaintenanceType.others:
      return 'Others';
    }
  }

  String get displayText => displayName;
}

class BackupMaintenance {
  final int? id;
  final int reminderId; // FK to reminder
  final String title;
  final String description;
  final double cost;
  final DateTime maintenanceDate;
  final MaintenanceType type;
  final String? mechanicName;
  final String? invoiceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BackupMaintenance({
    this.id,
    required this.reminderId,
    required this.title,
    required this.description,
    required this.cost,
    required this.maintenanceDate,
    required this.type,
    this.mechanicName,
    this.invoiceNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'title': title,
      'description': description,
      'cost': cost,
      'maintenance_date': maintenanceDate.toIso8601String(),
      'type': type.name,
      'mechanic_name': mechanicName,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BackupMaintenance.fromMap(Map<String, dynamic> map) {
    return BackupMaintenance(
      id: map['id']?.toInt(),
      reminderId: (map['reminder_id'] ?? 0).toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      maintenanceDate: DateTime.parse(map['maintenance_date'] ?? DateTime.now().toIso8601String()),
      type: MaintenanceType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'mechanics'),
        orElse: () => MaintenanceType.mechanics,
      ),
      mechanicName: map['mechanic_name'],
      invoiceNumber: map['invoice_number'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  BackupMaintenance copyWith({
    int? id,
    int? reminderId,
    String? title,
    String? description,
    double? cost,
    DateTime? maintenanceDate,
    MaintenanceType? type,
    String? mechanicName,
    String? invoiceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackupMaintenance(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      type: type ?? this.type,
      mechanicName: mechanicName ?? this.mechanicName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firebase-specific methods
  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'title': title,
      'description': description,
      'cost': cost,
      'maintenance_date': maintenanceDate.toIso8601String(),
      'type': type.name,
      'mechanic_name': mechanicName,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BackupMaintenance.fromFirebaseMap(Map<String, dynamic> map) {
    return BackupMaintenance(
      id: map['id']?.toInt(),
      reminderId: (map['reminder_id'] ?? 0).toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      maintenanceDate: DateTime.parse(map['maintenance_date'] ?? DateTime.now().toIso8601String()),
      type: MaintenanceType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'mechanics'),
        orElse: () => MaintenanceType.mechanics,
      ),
      mechanicName: map['mechanic_name'],
      invoiceNumber: map['invoice_number'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupMaintenance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BackupMaintenance(id: $id, title: $title, cost: $cost, type: ${type.displayName})';
  }
}

// Class to combine maintenance with reminder and car info for UI display
class MaintenanceWithInfo {
  final BackupMaintenance maintenance;
  final String reminderTitle;
  final String carBrand;
  final String carModel;
  final int carYear;
  final String carLicensePlate;

  MaintenanceWithInfo({
    required this.maintenance,
    required this.reminderTitle,
    required this.carBrand,
    required this.carModel,
    required this.carYear,
    required this.carLicensePlate,
  });

  factory MaintenanceWithInfo.fromMap(Map<String, dynamic> map) {
    return MaintenanceWithInfo(
      maintenance: BackupMaintenance.fromMap(map),
      reminderTitle: map['reminder_title'] ?? '',
      carBrand: map['car_brand'] ?? '',
      carModel: map['car_model'] ?? '',
      carYear: map['car_year']?.toInt() ?? 0,
      carLicensePlate: map['car_license_plate'] ?? '',
    );
  }

  String get carDisplayName => '$carBrand $carModel ($carYear)';
  String get reminderDisplayName => reminderTitle;
}
