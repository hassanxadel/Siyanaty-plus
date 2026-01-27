/// Model for car health score
class CarHealthScore {
  final int carId;
  final double overallScore; // 0-100
  final double maintenanceScore; // 0-30
  final double mileageScore; // 0-25
  final double overdueScore; // 0-25
  final double issuesScore; // 0-20
  final DateTime calculatedAt;
  final String healthStatus; // excellent, good, fair, poor, critical
  final List<String> recommendations;
  final Map<String, dynamic> details;

  CarHealthScore({
    required this.carId,
    required this.overallScore,
    required this.maintenanceScore,
    required this.mileageScore,
    required this.overdueScore,
    required this.issuesScore,
    DateTime? calculatedAt,
    required this.healthStatus,
    this.recommendations = const [],
    this.details = const {},
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  /// Get health status based on score
  static String getHealthStatus(double score) {
    if (score >= 90) return 'excellent';
    if (score >= 75) return 'good';
    if (score >= 60) return 'fair';
    if (score >= 40) return 'poor';
    return 'critical';
  }

  /// Get health status color
  static int getHealthColor(String status) {
    switch (status) {
      case 'excellent':
        return 0xFF10B981; // Green
      case 'good':
        return 0xFF22C55E; // Light Green
      case 'fair':
        return 0xFFF59E0B; // Amber
      case 'poor':
        return 0xFFEF4444; // Red
      case 'critical':
        return 0xFFDC2626; // Dark Red
      default:
        return 0xFF6B7280; // Gray
    }
  }

  /// Get health status display name
  static String getHealthStatusDisplay(String status) {
    switch (status) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'car_id': carId,
      'overall_score': overallScore,
      'maintenance_score': maintenanceScore,
      'mileage_score': mileageScore,
      'overdue_score': overdueScore,
      'issues_score': issuesScore,
      'calculated_at': calculatedAt.millisecondsSinceEpoch,
      'health_status': healthStatus,
      'recommendations': recommendations,
      'details': details,
    };
  }

  /// Create from Map
  factory CarHealthScore.fromMap(Map<String, dynamic> map) {
    return CarHealthScore(
      carId: map['car_id']?.toInt() ?? 0,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0.0,
      maintenanceScore: (map['maintenance_score'] as num?)?.toDouble() ?? 0.0,
      mileageScore: (map['mileage_score'] as num?)?.toDouble() ?? 0.0,
      overdueScore: (map['overdue_score'] as num?)?.toDouble() ?? 0.0,
      issuesScore: (map['issues_score'] as num?)?.toDouble() ?? 0.0,
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(map['calculated_at'] ?? 0),
      healthStatus: map['health_status'] ?? 'unknown',
      recommendations: (map['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'CarHealthScore(carId: $carId, overallScore: $overallScore, healthStatus: $healthStatus)';
  }
}

