import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../database/mileage_database_helper.dart';
import '../models/mileage_entry.dart';
import '../services/car_service.dart';

/// Background service for automatic mileage updates
/// Runs daily to update car mileage based on recurring trip entries
class MileageBackgroundService {
  static const String _taskName = 'mileageUpdateTask';
  static const String _uniqueName = 'mileageUpdate';

  /// Initialize the background service
  /// Should be called in main.dart before runApp()
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
  }

  /// Register periodic task to run daily
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 24), // Run once per day
      initialDelay: const Duration(hours: 1), // Start after 1 hour
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Cancel the periodic task
  static Future<void> cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName(_uniqueName);
  }

  /// Update mileage for all cars with recurring trips
  static Future<void> updateAllCarMileage() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;
      
      // Get all mileage entries for this user
      final db = await DatabaseHelper.instance.database;
      final entries = await MileageDatabaseHelper.getEntries(db, userId: userId);
      
      // Group entries by car
      final Map<String, List<MileageEntry>> entriesByCar = {};
      for (final entry in entries) {
        if (entry.carId != null) {
          entriesByCar.putIfAbsent(entry.carId!, () => []).add(entry);
        }
      }
      
      // Update mileage for each car
      final carService = CarService();
      final now = DateTime.now();
      
      for (final carId in entriesByCar.keys) {
        final carEntries = entriesByCar[carId]!;
        double totalMileageToAdd = 0;
        
        for (final entry in carEntries) {
          // Calculate mileage to add based on frequency
          switch (entry.tripFrequency) {
            case TripFrequency.oneTime:
              // One-time trips were already added when created
              break;
              
            case TripFrequency.daily:
              // For daily trips, we need to check if we've already counted today
              // We'll add the daily mileage
              final daysSinceCreation = now.difference(entry.createdAt).inDays;
              if (daysSinceCreation >= 0) {
                // Add today's mileage
                totalMileageToAdd += entry.mileage;
              }
              break;
              
            case TripFrequency.weekly:
              // Check if it's the right day of the week
              final daysSinceCreation = now.difference(entry.createdAt).inDays;
              final creationDayOfWeek = entry.createdAt.weekday;
              final currentDayOfWeek = now.weekday;
              
              // If it's the same day of week as creation, add mileage
              if (currentDayOfWeek == creationDayOfWeek && daysSinceCreation >= 7) {
                totalMileageToAdd += entry.mileage;
              }
              break;
              
            case TripFrequency.monthly:
              // Check if it's the right day of the month
              final creationDay = entry.createdAt.day;
              final currentDay = now.day;
              
              // If it's the same day of month as creation, add mileage
              if (currentDay == creationDay && 
                  now.month != entry.updatedAt.month) {
                totalMileageToAdd += entry.mileage;
              }
              break;
          }
        }
        
        // Update car mileage if there's mileage to add
        if (totalMileageToAdd > 0) {
          await carService.updateCarMileage(
            int.parse(carId),
            totalMileageToAdd,
          );
          
          print('Updated car $carId with $totalMileageToAdd km');
        }
      }
      
      print('Mileage update completed successfully');
    } catch (e) {
      print('Error updating car mileage: $e');
    }
  }
}

/// Callback dispatcher for background tasks
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background task started: $task');
      
      switch (task) {
        case 'mileageUpdateTask':
          await MileageBackgroundService.updateAllCarMileage();
          break;
        default:
          print('Unknown task: $task');
      }
      
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

