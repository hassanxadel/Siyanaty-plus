import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/backup_reminder.dart';
import '../models/backup_car.dart';

/// Service class for managing reminders with business logic and validation
class ReminderService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserId != null;

  /// Add a new reminder
  Future<ReminderOperationResult> addReminder({
    required int carId,
    required String title,
    required String description,
    required ReminderType type,
    required ReminderPriority priority,
    DateTime? targetDate,
    int? targetMileage,
  }) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to add reminders');
      }
      final userId = _currentUserId!;

      // Validate input data
      final validationResult = _validateReminderData(
        carId: carId,
        title: title,
        description: description,
        targetDate: targetDate,
        targetMileage: targetMileage,
      );

      if (!validationResult.isSuccess) {
        return validationResult;
      }

      // Check if car exists and belongs to user
      final car = await _databaseHelper.getCarById(carId, userId);
      if (car == null) {
        return ReminderOperationResult.error('Selected car not found or does not belong to you');
      }

      // Determine initial status
      ReminderStatus status = ReminderStatus.upcoming;
      if (targetDate != null && targetDate.isBefore(DateTime.now())) {
        status = ReminderStatus.overdue;
      }

      // Create reminder object
      final reminder = BackupReminder(
        carId: carId,
        title: title.trim(),
        description: description.trim(),
        type: type,
        priority: priority,
        targetDate: targetDate,
        targetMileage: targetMileage,
        status: status,
        isCompleted: false,
      );

      // Insert reminder into database
      final id = await _databaseHelper.insertReminder(reminder);
      final savedReminder = await _databaseHelper.getReminderById(id, userId);

      return ReminderOperationResult.success(
        message: 'Reminder added successfully',
        reminder: savedReminder,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to add reminder: ${e.toString()}');
    }
  }

  /// Update an existing reminder
  Future<ReminderOperationResult> updateReminder({
    required int id,
    required int carId,
    required String title,
    required String description,
    required ReminderType type,
    required ReminderPriority priority,
    DateTime? targetDate,
    int? targetMileage,
  }) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to update reminders');
      }
      final userId = _currentUserId!;

      // Check if reminder exists and belongs to user
      final existingReminder = await _databaseHelper.getReminderById(id, userId);
      if (existingReminder == null) {
        return ReminderOperationResult.error('Reminder not found or does not belong to you');
      }

      // Validate input data
      final validationResult = _validateReminderData(
        carId: carId,
        title: title,
        description: description,
        targetDate: targetDate,
        targetMileage: targetMileage,
      );

      if (!validationResult.isSuccess) {
        return validationResult;
      }

      // Check if car exists and belongs to user
      final car = await _databaseHelper.getCarById(carId, userId);
      if (car == null) {
        return ReminderOperationResult.error('Selected car not found or does not belong to you');
      }

      // Determine status (don't change if already completed)
      ReminderStatus status = existingReminder.status;
      if (!existingReminder.isCompleted) {
        if (targetDate != null && targetDate.isBefore(DateTime.now())) {
          status = ReminderStatus.overdue;
        } else {
          status = ReminderStatus.upcoming;
        }
      }

      // Update reminder
      final updatedReminder = existingReminder.copyWith(
        carId: carId,
        title: title.trim(),
        description: description.trim(),
        type: type,
        priority: priority,
        targetDate: targetDate,
        targetMileage: targetMileage,
        status: status,
      );

      await _databaseHelper.updateReminder(updatedReminder);
      final savedReminder = await _databaseHelper.getReminderById(id, userId);

      return ReminderOperationResult.success(
        message: 'Reminder updated successfully',
        reminder: savedReminder,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to update reminder: ${e.toString()}');
    }
  }

  /// Delete a reminder
  Future<ReminderOperationResult> deleteReminder(int id) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to delete reminders');
      }
      final userId = _currentUserId!;

      // Check if reminder exists and belongs to user
      final existingReminder = await _databaseHelper.getReminderById(id, userId);
      if (existingReminder == null) {
        return ReminderOperationResult.error('Reminder not found or does not belong to you');
      }

      await _databaseHelper.deleteReminder(id, userId);

      return ReminderOperationResult.success(
        message: 'Reminder deleted successfully',
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to delete reminder: ${e.toString()}');
    }
  }

  /// Mark reminder as completed
  Future<ReminderOperationResult> markReminderCompleted(int id) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to update reminders');
      }
      final userId = _currentUserId!;

      // Check if reminder exists and belongs to user
      final existingReminder = await _databaseHelper.getReminderById(id, userId);
      if (existingReminder == null) {
        return ReminderOperationResult.error('Reminder not found or does not belong to you');
      }

      if (existingReminder.isCompleted) {
        return ReminderOperationResult.error('Reminder is already completed');
      }

      await _databaseHelper.markReminderCompleted(id, userId);
      final updatedReminder = await _databaseHelper.getReminderById(id, userId);

      return ReminderOperationResult.success(
        message: 'Reminder marked as completed',
        reminder: updatedReminder,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to mark reminder as completed: ${e.toString()}');
    }
  }

  /// Mark reminder as uncompleted (move back to upcoming)
  Future<ReminderOperationResult> markReminderUncompleted(int id) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to update reminders');
      }
      final userId = _currentUserId!;

      // Check if reminder exists and belongs to user
      final existingReminder = await _databaseHelper.getReminderById(id, userId);
      if (existingReminder == null) {
        return ReminderOperationResult.error('Reminder not found or does not belong to you');
      }

      if (!existingReminder.isCompleted) {
        return ReminderOperationResult.error('Reminder is not completed');
      }

      // Update reminder to uncompleted state
      final updatedReminder = existingReminder.copyWith(
        isCompleted: false,
        completedAt: null,
        status: ReminderStatus.upcoming,
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.updateReminder(updatedReminder);
      final savedReminder = await _databaseHelper.getReminderById(id, userId);

      return ReminderOperationResult.success(
        message: 'Reminder moved back to upcoming',
        reminder: savedReminder,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to mark reminder as uncompleted: ${e.toString()}');
    }
  }

  /// Get all reminders for the current user
  Future<ReminderOperationResult> getAllReminders() async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to view reminders');
      }
      final userId = _currentUserId!;

      // Update overdue reminders first
      await _updateOverdueReminders();

      final reminders = await _databaseHelper.getAllReminders(userId);

      return ReminderOperationResult.success(
        message: 'Reminders retrieved successfully',
        reminders: reminders,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to get reminders: ${e.toString()}');
    }
  }

  /// Get all reminders with car information for the current user
  Future<List<ReminderWithCarInfo>> getAllRemindersWithCarInfo() async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return [];
      }
      final userId = _currentUserId!;

      // Update overdue reminders first
      await _updateOverdueReminders();

      final reminderMaps = await _databaseHelper.getAllRemindersWithCarInfo(userId);
      return reminderMaps.map((map) => ReminderWithCarInfo.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get reminders by status
  Future<ReminderOperationResult> getRemindersByStatus(ReminderStatus status) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to view reminders');
      }
      final userId = _currentUserId!;

      // Update overdue reminders first
      await _updateOverdueReminders();

      final reminders = await _databaseHelper.getRemindersByStatus(status, userId);

      return ReminderOperationResult.success(
        message: 'Reminders retrieved successfully',
        reminders: reminders,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to get reminders by status: ${e.toString()}');
    }
  }

  /// Get reminders for a specific car
  Future<ReminderOperationResult> getRemindersByCar(int carId) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to view reminders');
      }
      final userId = _currentUserId!;

      // Check if car exists and belongs to user
      final car = await _databaseHelper.getCarById(carId, userId);
      if (car == null) {
        return ReminderOperationResult.error('Car not found or does not belong to you');
      }

      final reminders = await _databaseHelper.getRemindersByCar(carId, userId);

      return ReminderOperationResult.success(
        message: 'Car reminders retrieved successfully',
        reminders: reminders,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to get car reminders: ${e.toString()}');
    }
  }

  /// Search reminders
  Future<ReminderOperationResult> searchReminders(String query) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return ReminderOperationResult.error('User must be signed in to search reminders');
      }
      final userId = _currentUserId!;

      if (query.trim().isEmpty) {
        return getAllReminders();
      }

      final reminders = await _databaseHelper.searchReminders(query.trim(), userId);

      return ReminderOperationResult.success(
        message: 'Search completed successfully',
        reminders: reminders,
      );

    } catch (e) {
      return ReminderOperationResult.error('Failed to search reminders: ${e.toString()}');
    }
  }

  /// Get reminders count
  Future<int> getRemindersCount() async {
    try {
      if (!isUserAuthenticated) return 0;
      final userId = _currentUserId!;
      return await _databaseHelper.getRemindersCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// Get user's cars for reminder creation
  Future<List<BackupCar>> getUserCars() async {
    try {
      if (!isUserAuthenticated) return [];
      final userId = _currentUserId!;
      return await _databaseHelper.getAllCars(userId);
    } catch (e) {
      return [];
    }
  }

  /// Update overdue reminders automatically
  Future<void> _updateOverdueReminders() async {
    try {
      if (!isUserAuthenticated) return;
      final userId = _currentUserId!;
      await _databaseHelper.updateOverdueRemindersStatus(userId);
    } catch (e) {
      // Silent fail for background operation
    }
  }

  /// Validate reminder data
  ReminderOperationResult _validateReminderData({
    required int carId,
    required String title,
    required String description,
    DateTime? targetDate,
    int? targetMileage,
  }) {
    final List<String> errors = [];

    // Validate car ID
    if (carId <= 0) {
      errors.add('Please select a valid car');
    }

    // Validate title
    if (title.trim().isEmpty) {
      errors.add('Title is required');
    } else if (title.trim().length < 3) {
      errors.add('Title must be at least 3 characters long');
    } else if (title.trim().length > 100) {
      errors.add('Title must be less than 100 characters');
    }

    // Validate description
    if (description.trim().isEmpty) {
      errors.add('Description is required');
    } else if (description.trim().length > 500) {
      errors.add('Description must be less than 500 characters');
    }

    // Validate target date and mileage (at least one should be provided)
    if (targetDate == null && targetMileage == null) {
      errors.add('Please provide either a target date or target mileage');
    }

    // Validate target mileage if provided
    if (targetMileage != null && targetMileage <= 0) {
      errors.add('Target mileage must be greater than 0');
    }

    if (errors.isNotEmpty) {
      return ReminderOperationResult.error(errors.join(', '));
    }

    return ReminderOperationResult.success(message: 'Validation passed');
  }
}

/// Result class for reminder operations
class ReminderOperationResult {
  final bool isSuccess;
  final String message;
  final BackupReminder? reminder;
  final List<BackupReminder>? reminders;
  final List<String>? errors;

  ReminderOperationResult._({
    required this.isSuccess,
    required this.message,
    this.reminder,
    this.reminders,
    this.errors,
  });

  factory ReminderOperationResult.success({
    required String message,
    BackupReminder? reminder,
    List<BackupReminder>? reminders,
  }) {
    return ReminderOperationResult._(
      isSuccess: true,
      message: message,
      reminder: reminder,
      reminders: reminders,
    );
  }

  factory ReminderOperationResult.error(String message) {
    return ReminderOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}
