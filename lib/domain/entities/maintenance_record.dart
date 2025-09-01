// maintenance_types.dart was removed - using string constants instead

class MaintenanceRecord {
  final String id;
  final String carId;
  final String userId;
  final String title;
  final String description;
  final String type;
  final double cost;
  final double mileage;
  final DateTime date;
  final String? serviceCenterName;
  final String? serviceCenter;
  final String? technician;
  final List<String> parts;
  final String? notes;
  final String? receiptImageUrl;
  final List<String> attachments;
  final DateTime? nextServiceDate;
  final double? nextServiceMileage;
  final bool isRecurring;
  final int? recurringIntervalMonths;
  final double? recurringIntervalMiles;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    required this.id,
    required this.carId,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.cost,
    required this.mileage,
    required this.date,
    this.serviceCenterName,
    this.serviceCenter,
    this.technician,
    this.parts = const [],
    this.notes,
    this.receiptImageUrl,
    this.attachments = const [],
    this.nextServiceDate,
    this.nextServiceMileage,
    this.isRecurring = false,
    this.recurringIntervalMonths,
    this.recurringIntervalMiles,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedCost => 'EGP ${cost.toStringAsFixed(2)}';

  String get formattedMileage => '${mileage.toStringAsFixed(0)} km';

  String get typeDisplayName => type;

  bool get hasAttachments => attachments.isNotEmpty || receiptImageUrl != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carId': carId,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'cost': cost,
      'mileage': mileage,
      'date': date.toIso8601String(),
      'serviceCenterName': serviceCenterName,
      'serviceCenter': serviceCenter,
      'technician': technician,
      'parts': parts,
      'notes': notes,
      'receiptImageUrl': receiptImageUrl,
      'attachments': attachments,
      'nextServiceDate': nextServiceDate?.toIso8601String(),
      'nextServiceMileage': nextServiceMileage,
      'isRecurring': isRecurring,
      'recurringIntervalMonths': recurringIntervalMonths,
      'recurringIntervalMiles': recurringIntervalMiles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      carId: json['carId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String? ?? 'Other',
      cost: (json['cost'] as num).toDouble(),
      mileage: (json['mileage'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      serviceCenterName: json['serviceCenterName'] as String?,
      serviceCenter: json['serviceCenter'] as String?,
      technician: json['technician'] as String?,
      parts: List<String>.from(json['parts'] as List? ?? []),
      notes: json['notes'] as String?,
      receiptImageUrl: json['receiptImageUrl'] as String?,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      nextServiceDate: json['nextServiceDate'] != null
          ? DateTime.parse(json['nextServiceDate'] as String)
          : null,
      nextServiceMileage: json['nextServiceMileage'] != null
          ? (json['nextServiceMileage'] as num).toDouble()
          : null,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringIntervalMonths: json['recurringIntervalMonths'] as int?,
      recurringIntervalMiles: json['recurringIntervalMiles'] != null
          ? (json['recurringIntervalMiles'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  MaintenanceRecord copyWith({
    String? id,
    String? carId,
    String? userId,
    String? title,
    String? description,
    String? type,
    double? cost,
    double? mileage,
    DateTime? date,
    String? serviceCenterName,
    String? serviceCenter,
    String? technician,
    List<String>? parts,
    String? notes,
    String? receiptImageUrl,
    List<String>? attachments,
    DateTime? nextServiceDate,
    double? nextServiceMileage,
    bool? isRecurring,
    int? recurringIntervalMonths,
    double? recurringIntervalMiles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
      date: date ?? this.date,
      serviceCenterName: serviceCenterName ?? this.serviceCenterName,
      serviceCenter: serviceCenter ?? this.serviceCenter,
      technician: technician ?? this.technician,
      parts: parts ?? this.parts,
      notes: notes ?? this.notes,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      attachments: attachments ?? this.attachments,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalMonths: recurringIntervalMonths ?? this.recurringIntervalMonths,
      recurringIntervalMiles: recurringIntervalMiles ?? this.recurringIntervalMiles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}