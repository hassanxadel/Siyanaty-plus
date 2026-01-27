import '../models/car_health_score.dart';
import '../models/backup_car.dart';
import '../database/database_helper.dart';
import '../services/reminder_service.dart';
import '../services/mileage_service.dart';

/// Service for calculating car health scores
class CarHealthService {
  static final CarHealthService _instance = CarHealthService._internal();
  factory CarHealthService() => _instance;
  CarHealthService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ReminderService _reminderService = ReminderService();
  final MileageService _mileageService = MileageService();

  /// Calculate comprehensive health score for a car
  Future<CarHealthScore> calculateHealthScore(BackupCar car) async {
    try {
      // 1. Calculate Maintenance History Score (30 points)
      final maintenanceScore = await _calculateMaintenanceScore(car);

      // 2. Calculate Mileage vs Age Score (25 points)
      final mileageScore = await _calculateMileageScore(car);

      // 3. Calculate Overdue Services Score (25 points)
      final overdueScore = await _calculateOverdueScore(car);

      // 4. Calculate Reported Issues Score (20 points)
      final issuesScore = await _calculateIssuesScore(car);

      // Calculate overall score
      final overallScore = (maintenanceScore + mileageScore + overdueScore + issuesScore).clamp(0.0, 100.0);

      // Determine health status
      final healthStatus = CarHealthScore.getHealthStatus(overallScore);

      // Generate recommendations
      final recommendations = _generateRecommendations(
        car,
        maintenanceScore,
        mileageScore,
        overdueScore,
        issuesScore,
      );

      // Get accumulated mileage for details
      double totalMileage = car.mileage.toDouble();
      try {
        final accumulatedMileage = await _mileageService.calculateAccumulatedMileage(
          car.id.toString(),
          userId: car.userId,
        );
        if (accumulatedMileage > 0) {
          totalMileage = car.mileage + accumulatedMileage;
        }
      } catch (e) {
        print('[CarHealth] Could not get accumulated mileage for details: $e');
      }

      final carAge = _getCarAge(car.year);
      final avgMileagePerYear = carAge > 0 ? totalMileage / carAge : 0.0;

      // Compile details
      final details = {
        'maintenance_count': await _getMaintenanceCount(car.id!, car.userId),
        'overdue_reminders': await _getOverdueRemindersCount(car.id!),
        'total_reminders': await _getTotalRemindersCount(car.id!),
        'car_age_years': carAge,
        'mileage': totalMileage,
        'avg_mileage_per_year': avgMileagePerYear,
      };

      return CarHealthScore(
        carId: car.id!,
        overallScore: overallScore,
        maintenanceScore: maintenanceScore,
        mileageScore: mileageScore,
        overdueScore: overdueScore,
        issuesScore: issuesScore,
        healthStatus: healthStatus,
        recommendations: recommendations,
        details: details,
      );
    } catch (e) {
      print('[CarHealth] Error calculating health score: $e');
      // Return default score on error
      return CarHealthScore(
        carId: car.id!,
        overallScore: 50.0,
        maintenanceScore: 15.0,
        mileageScore: 12.5,
        overdueScore: 12.5,
        issuesScore: 10.0,
        healthStatus: 'fair',
        recommendations: ['Unable to calculate accurate health score'],
        details: {},
      );
    }
  }

  /// Calculate maintenance history score (0-30 points)
  Future<double> _calculateMaintenanceScore(BackupCar car) async {
    try {
      final maintenanceCount = await _getMaintenanceCount(car.id!, car.userId);
      final carAge = _getCarAge(car.year);

      // Expected maintenance: at least 2 per year
      final expectedMaintenance = carAge * 2;
      
      if (expectedMaintenance == 0) {
        // New car, give full score
        return 30.0;
      }

      // Calculate ratio
      final ratio = maintenanceCount / expectedMaintenance;

      // Score based on ratio
      if (ratio >= 1.0) {
        return 30.0; // Excellent maintenance
      } else if (ratio >= 0.75) {
        return 25.0; // Good maintenance
      } else if (ratio >= 0.5) {
        return 20.0; // Fair maintenance
      } else if (ratio >= 0.25) {
        return 15.0; // Poor maintenance
      } else {
        return 10.0; // Very poor maintenance
      }
    } catch (e) {
      print('[CarHealth] Error calculating maintenance score: $e');
      return 15.0; // Default score
    }
  }

  /// Calculate mileage vs age score (0-25 points)
  /// Uses real mileage data from mileage tracker entries
  Future<double> _calculateMileageScore(BackupCar car) async {
    try {
      final carAge = _getCarAge(car.year);
      
      if (carAge == 0) {
        return 25.0; // New car
      }

      // Get accumulated mileage from mileage tracker
      double totalMileage = car.mileage.toDouble();
      
      // Try to get more accurate mileage from mileage entries
      try {
        final accumulatedMileage = await _mileageService.calculateAccumulatedMileage(
          car.id.toString(),
          userId: car.userId,
        );
        if (accumulatedMileage > 0) {
          totalMileage = car.mileage + accumulatedMileage;
        }
      } catch (e) {
        print('[CarHealth] Could not get accumulated mileage: $e');
      }

      // Average mileage per year
      final avgMileagePerYear = totalMileage / carAge;

      // Typical average: 12,000-15,000 km/year
      // Score based on usage intensity
      if (avgMileagePerYear <= 10000) {
        return 25.0; // Low usage, excellent
      } else if (avgMileagePerYear <= 15000) {
        return 22.0; // Normal usage, very good
      } else if (avgMileagePerYear <= 20000) {
        return 18.0; // Above average, good
      } else if (avgMileagePerYear <= 30000) {
        return 14.0; // High usage, fair
      } else {
        return 10.0; // Very high usage, poor
      }
    } catch (e) {
      print('[CarHealth] Error calculating mileage score: $e');
      return 12.5; // Default score
    }
  }

  /// Calculate overdue services score (0-25 points)
  Future<double> _calculateOverdueScore(BackupCar car) async {
    try {
      final totalReminders = await _getTotalRemindersCount(car.id!);
      final overdueReminders = await _getOverdueRemindersCount(car.id!);

      if (totalReminders == 0) {
        // No reminders set, give neutral score
        return 20.0;
      }

      // Calculate overdue percentage
      final overduePercentage = (overdueReminders / totalReminders) * 100;

      // Score based on overdue percentage
      if (overduePercentage == 0) {
        return 25.0; // No overdue, excellent
      } else if (overduePercentage <= 10) {
        return 22.0; // Very few overdue, very good
      } else if (overduePercentage <= 25) {
        return 18.0; // Some overdue, good
      } else if (overduePercentage <= 50) {
        return 12.0; // Many overdue, fair
      } else {
        return 5.0; // Most overdue, poor
      }
    } catch (e) {
      print('[CarHealth] Error calculating overdue score: $e');
      return 12.5; // Default score
    }
  }

  /// Calculate reported issues score (0-20 points)
  Future<double> _calculateIssuesScore(BackupCar car) async {
    try {
      // Check OBD scans for error codes
      final obdScans = await _dbHelper.getOBDScansByCar(car.id!);
      int totalErrorCodes = 0;

      for (var scan in obdScans) {
        final errorCodes = scan['error_codes'] as String?;
        if (errorCodes != null && errorCodes.isNotEmpty) {
          totalErrorCodes += errorCodes.split(',').where((e) => e.isNotEmpty).length;
        }
      }

      // Score based on error codes
      if (totalErrorCodes == 0) {
        return 20.0; // No issues, excellent
      } else if (totalErrorCodes <= 2) {
        return 17.0; // Minor issues, very good
      } else if (totalErrorCodes <= 5) {
        return 14.0; // Some issues, good
      } else if (totalErrorCodes <= 10) {
        return 10.0; // Multiple issues, fair
      } else {
        return 5.0; // Many issues, poor
      }
    } catch (e) {
      print('[CarHealth] Error calculating issues score: $e');
      return 10.0; // Default score
    }
  }

  /// Generate recommendations based on scores
  List<String> _generateRecommendations(
    BackupCar car,
    double maintenanceScore,
    double mileageScore,
    double overdueScore,
    double issuesScore,
  ) {
    final recommendations = <String>[];
    final carAge = _getCarAge(car.year);

    // Maintenance recommendations
    if (maintenanceScore < 20) {
      recommendations.add('📋 Schedule regular maintenance services');
      recommendations.add('📝 Keep detailed service records in the app');
      if (carAge > 5) {
        recommendations.add('🔧 Older cars need more frequent maintenance');
      }
    } else if (maintenanceScore < 25) {
      recommendations.add('✅ Maintain your current service schedule');
    }

    // Mileage recommendations
    if (mileageScore < 15) {
      recommendations.add('⚠️ High mileage detected - consider more frequent oil changes');
      recommendations.add('🔍 Check tire wear and brake pads regularly');
      recommendations.add('💧 Monitor fluid levels more frequently');
    } else if (mileageScore < 20) {
      recommendations.add('📊 Track your mileage regularly using the Mileage Tracker');
    }

    // Overdue recommendations
    if (overdueScore < 15) {
      recommendations.add('🚨 Address overdue service reminders immediately');
      recommendations.add('📅 Update your maintenance schedule');
      recommendations.add('⏰ Enable notifications for upcoming services');
    } else if (overdueScore < 20) {
      recommendations.add('⏳ Some services are approaching - plan ahead');
    }

    // Issues recommendations
    if (issuesScore < 12) {
      recommendations.add('🔴 Diagnostic trouble codes detected - visit a mechanic');
      recommendations.add('🛠️ Clear error codes after repairs');
      recommendations.add('📱 Use OBD-II scanner for detailed diagnostics');
    }

    // Age-based recommendations
    if (carAge >= 10) {
      recommendations.add('🏁 Consider comprehensive inspection for older vehicles');
    } else if (carAge >= 5) {
      recommendations.add('🔄 Regular fluid changes become more important');
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.add('🌟 Your car is in excellent condition!');
      recommendations.add('✨ Continue your current maintenance routine');
      recommendations.add('📈 Keep tracking your car data for best results');
    }

    return recommendations;
  }

  /// Helper methods
  Future<int> _getMaintenanceCount(int carId, String userId) async {
    try {
      // Get actual maintenance records count for this car from the database
      return await _dbHelper.getMaintenanceCountByCarId(carId, userId);
    } catch (e) {
      print('[CarHealth] Error getting maintenance count: $e');
      return 0;
    }
  }

  Future<int> _getTotalRemindersCount(int carId) async {
    try {
      final result = await _reminderService.getRemindersByCar(carId);
      if (!result.isSuccess || result.reminders == null) return 0;
      return result.reminders!.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getOverdueRemindersCount(int carId) async {
    try {
      final result = await _reminderService.getRemindersByCar(carId);
      if (!result.isSuccess || result.reminders == null) return 0;
      
      final now = DateTime.now();
      int count = 0;

      for (var reminder in result.reminders!) {
        if (!reminder.isCompleted) {
          // Check if overdue by date
          if (reminder.targetDate != null) {
            if (reminder.targetDate!.isBefore(now)) {
              count++;
              continue;
            }
          }
          
          // Check if overdue by mileage (would need current car mileage)
          // This is a simplified check
          if (reminder.targetMileage != null && reminder.targetMileage! > 0) {
            // Assume overdue if target mileage is set and reminder is not completed
            // In a real implementation, compare with current car mileage
          }
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  int _getCarAge(int year) {
    final currentYear = DateTime.now().year;
    return (currentYear - year).clamp(0, 100);
  }

  /// Get a detailed health breakdown with explanations
  Future<Map<String, dynamic>> getHealthBreakdown(BackupCar car) async {
    final healthScore = await calculateHealthScore(car);
    
    return {
      'overall': {
        'score': healthScore.overallScore,
        'status': healthScore.healthStatus,
        'color': CarHealthScore.getHealthColor(healthScore.healthStatus),
      },
      'maintenance': {
        'score': healthScore.maintenanceScore,
        'max': 30.0,
        'count': healthScore.details['maintenance_count'],
        'description': 'Based on completed maintenance records',
      },
      'mileage': {
        'score': healthScore.mileageScore,
        'max': 25.0,
        'avgPerYear': healthScore.details['avg_mileage_per_year'],
        'description': 'Based on average mileage per year',
      },
      'services': {
        'score': healthScore.overdueScore,
        'max': 25.0,
        'overdue': healthScore.details['overdue_reminders'],
        'total': healthScore.details['total_reminders'],
        'description': 'Based on service reminders status',
      },
      'issues': {
        'score': healthScore.issuesScore,
        'max': 20.0,
        'description': 'Based on OBD-II diagnostic codes',
      },
      'carInfo': {
        'age': healthScore.details['car_age_years'],
        'mileage': healthScore.details['mileage'],
      },
      'recommendations': healthScore.recommendations,
    };
  }
}

