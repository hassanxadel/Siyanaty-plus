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
          if (entry.tripFrequency == TripFrequency.oneTime || entry.id == null) {
            // One-time trips were already added when created.
            continue;
          }

          // Anchor from the last time this entry was credited, or its creation
          // if it never has been. Counting whole ELAPSED periods (rather than
          // "is today the right day?") makes the update both idempotent —
          // running twice in a day credits nothing the second time — and
          // catch-up safe: if the task didn't run for 3 days, 3 days are
          // credited now. This is the fix for the daily double-count/miss,
          // the weekly "only fires on the exact weekday" gap, and the monthly
          // day-of-month gap.
          final anchor = entry.lastAppliedAt ?? entry.createdAt;
          final periods = _elapsedPeriods(entry.tripFrequency, anchor, now);
          if (periods <= 0) continue;

          totalMileageToAdd += entry.mileage * periods;

          // Advance the anchor by exactly the credited periods (not to `now`),
          // so the leftover partial period carries forward instead of drifting.
          final newAnchor = _advance(entry.tripFrequency, anchor, periods);
          await MileageDatabaseHelper.markApplied(db, entry.id!, newAnchor);

          print('Credited ${entry.mileage * periods} km for entry '
              '${entry.id} ($periods period(s))');
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

  /// Number of whole recurrence periods between [anchor] and [now].
  static int _elapsedPeriods(TripFrequency freq, DateTime anchor, DateTime now) {
    if (!now.isAfter(anchor)) return 0;
    switch (freq) {
      case TripFrequency.daily:
        return now.difference(anchor).inDays;
      case TripFrequency.weekly:
        return now.difference(anchor).inDays ~/ 7;
      case TripFrequency.monthly:
        return _wholeMonthsBetween(anchor, now);
      case TripFrequency.oneTime:
        return 0;
    }
  }

  /// Advance [anchor] forward by [periods] recurrence periods.
  static DateTime _advance(TripFrequency freq, DateTime anchor, int periods) {
    switch (freq) {
      case TripFrequency.daily:
        return anchor.add(Duration(days: periods));
      case TripFrequency.weekly:
        return anchor.add(Duration(days: 7 * periods));
      case TripFrequency.monthly:
        return _addMonths(anchor, periods);
      case TripFrequency.oneTime:
        return anchor;
    }
  }

  /// Completed calendar-month anniversaries between [from] and [to].
  /// e.g. Jan 15 → Mar 14 is 1 (the Feb 15 anniversary passed, Mar 15 has not).
  static int _wholeMonthsBetween(DateTime from, DateTime to) {
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    // If we haven't yet reached the anniversary day/time this month, the
    // current month doesn't count as complete.
    final anniversary = _addMonths(from, months);
    if (anniversary.isAfter(to)) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// Add [months] to [date], clamping the day to the target month's length so
  /// e.g. Jan 31 + 1 month = Feb 28/29 rather than rolling into March.
  static DateTime _addMonths(DateTime date, int months) {
    final totalMonth = date.month - 1 + months;
    final year = date.year + (totalMonth ~/ 12);
    final month = totalMonth % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day < lastDayOfMonth ? date.day : lastDayOfMonth;
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
    );
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

