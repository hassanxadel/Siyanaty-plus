import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/backup_car.dart';
import '../database/database_helper.dart';

/// Result class for car operations
class CarOperationResult {
  final bool isSuccess;
  final String message;
  final BackupCar? car;
  final List<String>? errors;

  CarOperationResult._({
    required this.isSuccess,
    required this.message,
    this.car,
    this.errors,
  });

  factory CarOperationResult.success({
    required String message,
    BackupCar? car,
  }) {
    return CarOperationResult._(
      isSuccess: true,
      message: message,
      car: car,
    );
  }

  factory CarOperationResult.error(String message) {
    return CarOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}

/// Service class for car management operations
/// Provides business logic layer between UI and database
class CarService {
  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();
  
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;
  
  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;
  
  /// Add a new car with validation
  Future<CarOperationResult> addCar({
    required String brand,
    required String model,
    required int year,
    required int mileage,
    required String color,
    required String fuelType,
    required String engineCC,
    required bool turbo,
    required String licensePlate,
    required String vin,
    String? imagePath,
  }) async {
    try {
      // Validate input data
      final validationResult = _validateCarData(
        brand: brand,
        model: model,
        year: year,
        mileage: mileage,
        color: color,
        fuelType: fuelType,
        engineCC: engineCC,
        licensePlate: licensePlate,
        vin: vin,
      );
      
      if (!validationResult.isSuccess) {
        return validationResult;
      }
      
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return CarOperationResult.error('User must be signed in to add cars');
      }
      
      final userId = _currentUserId!;
      
      // Check for duplicate VIN for this user
      if (await _databaseHelper.vinExists(vin, userId)) {
        return CarOperationResult.error('You already have a car with this VIN');
      }
      
      // Check for duplicate license plate for this user
      if (await _databaseHelper.licensePlateExists(licensePlate, userId)) {
        return CarOperationResult.error('You already have a car with this license plate');
      }
      
      // Validate image path if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        if (!await File(imagePath).exists()) {
          return CarOperationResult.error('Selected image file does not exist');
        }
      }
      
      // Create car object
      final car = BackupCar(
        userId: userId,
        brand: brand.trim(),
        model: model.trim(),
        year: year,
        mileage: mileage,
        color: color.trim(),
        fuelType: fuelType.trim(),
        engineCC: engineCC.trim(),
        turbo: turbo,
        licensePlate: licensePlate.trim().toUpperCase(),
        vin: vin.trim().toUpperCase(),
        imagePath: imagePath,
      );
      
      // Insert car into database
      final id = await _databaseHelper.insertCar(car);
      final savedCar = await _databaseHelper.getCarById(id, userId);
      
      return CarOperationResult.success(
        message: 'Car added successfully',
        car: savedCar,
      );
      
    } catch (e) {
      return CarOperationResult.error('Failed to add car: ${e.toString()}');
    }
  }
  
  /// Update an existing car
  Future<CarOperationResult> updateCar({
    required int id,
    required String brand,
    required String model,
    required int year,
    required int mileage,
    required String color,
    required String fuelType,
    required String engineCC,
    required bool turbo,
    required String licensePlate,
    required String vin,
    String? imagePath,
  }) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return CarOperationResult.error('User must be signed in to update cars');
      }
      
      final userId = _currentUserId!;
      
      // Check if car exists for this user
      final existingCar = await _databaseHelper.getCarById(id, userId);
      if (existingCar == null) {
        return CarOperationResult.error('Car not found');
      }
      
      // Validate input data
      final validationResult = _validateCarData(
        brand: brand,
        model: model,
        year: year,
        mileage: mileage,
        color: color,
        fuelType: fuelType,
        engineCC: engineCC,
        licensePlate: licensePlate,
        vin: vin,
      );
      
      if (!validationResult.isSuccess) {
        return validationResult;
      }
      
      // Check for duplicate VIN (excluding current car) for this user
      if (await _databaseHelper.vinExists(vin, userId, excludeId: id)) {
        return CarOperationResult.error('You already have a car with this VIN');
      }
      
      // Check for duplicate license plate (excluding current car) for this user
      if (await _databaseHelper.licensePlateExists(licensePlate, userId, excludeId: id)) {
        return CarOperationResult.error('You already have a car with this license plate');
      }
      
      // Validate image path if provided and it's a new image (different from existing)
      // Skip validation if it's the same path (might be restored from cloud with missing file)
      String? finalImagePath = imagePath;
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          // If the image doesn't exist and it's the same as existing path, clear it
          // If it's a new path that doesn't exist, that's an error
          if (imagePath == existingCar.imagePath) {
            // Old restored path that no longer exists - clear it
            finalImagePath = null;
          } else {
            return CarOperationResult.error('Selected image file does not exist');
          }
        }
      }
      
      // Update car object
      final updatedCar = existingCar.copyWith(
        brand: brand.trim(),
        model: model.trim(),
        year: year,
        mileage: mileage,
        color: color.trim(),
        fuelType: fuelType.trim(),
        engineCC: engineCC.trim(),
        turbo: turbo,
        licensePlate: licensePlate.trim().toUpperCase(),
        vin: vin.trim().toUpperCase(),
        imagePath: finalImagePath,
        updatedAt: DateTime.now(),
      );
      
      // Update car in database
      final rowsAffected = await _databaseHelper.updateCar(updatedCar);
      
      if (rowsAffected == 0) {
        return CarOperationResult.error('Failed to update car');
      }
      
      final savedCar = await _databaseHelper.getCarById(id, userId);
      
      return CarOperationResult.success(
        message: 'Car updated successfully',
        car: savedCar,
      );
      
    } catch (e) {
      return CarOperationResult.error('Failed to update car: ${e.toString()}');
    }
  }
  
  /// Delete a car for the current user
  Future<CarOperationResult> deleteCar(int id) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return CarOperationResult.error('User must be signed in to delete cars');
      }
      
      final userId = _currentUserId!;
      
      // Check if car exists for this user
      final existingCar = await _databaseHelper.getCarById(id, userId);
      if (existingCar == null) {
        return CarOperationResult.error('Car not found');
      }
      
      // Delete car from database
      final rowsAffected = await _databaseHelper.deleteCar(id, userId);
      
      if (rowsAffected == 0) {
        return CarOperationResult.error('Failed to delete car');
      }
      
      // Delete associated image file if exists
      if (existingCar.imagePath != null && existingCar.imagePath!.isNotEmpty) {
        try {
          final imageFile = File(existingCar.imagePath!);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        } catch (e) {
          // Log error but don't fail the operation
          print('Warning: Could not delete image file: $e');
        }
      }
      
      return CarOperationResult.success(
        message: 'BackupCar deleted successfully',
      );
      
    } catch (e) {
      return CarOperationResult.error('Failed to delete car: ${e.toString()}');
    }
  }
  
  /// Get all cars for the current user
  Future<List<BackupCar>> getAllCars() async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be signed in to access cars');
      }
      return await _databaseHelper.getAllCars(_currentUserId!);
    } catch (e) {
      throw Exception('Failed to retrieve cars: ${e.toString()}');
    }
  }
  
  /// Get car by ID for the current user
  Future<BackupCar?> getCarById(int id) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be signed in to access cars');
      }
      return await _databaseHelper.getCarById(id, _currentUserId!);
    } catch (e) {
      throw Exception('Failed to retrieve car: ${e.toString()}');
    }
  }
  
  /// Search cars for the current user
  Future<List<BackupCar>> searchCars(String query) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be signed in to search cars');
      }
      if (query.trim().isEmpty) {
        return await getAllCars();
      }
      return await _databaseHelper.searchCars(query.trim(), _currentUserId!);
    } catch (e) {
      throw Exception('Failed to search cars: ${e.toString()}');
    }
  }
  
  /// Get cars count for the current user
  Future<int> getCarsCount() async {
    try {
      if (!isUserAuthenticated) {
        return 0;
      }
      return await _databaseHelper.getCarsCount(_currentUserId!);
    } catch (e) {
      throw Exception('Failed to get cars count: ${e.toString()}');
    }
  }
  
  /// Get car by VIN for the current user
  Future<BackupCar?> getCarByVin(String vin) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be signed in to access cars');
      }
      return await _databaseHelper.getCarByVin(vin.trim().toUpperCase(), _currentUserId!);
    } catch (e) {
      throw Exception('Failed to retrieve car by VIN: ${e.toString()}');
    }
  }
  
  /// Get car by license plate for the current user
  Future<BackupCar?> getCarByLicensePlate(String licensePlate) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be signed in to access cars');
      }
      return await _databaseHelper.getCarByLicensePlate(licensePlate.trim().toUpperCase(), _currentUserId!);
    } catch (e) {
      throw Exception('Failed to retrieve car by license plate: ${e.toString()}');
    }
  }
  
  /// Validate car data
  CarOperationResult _validateCarData({
    required String brand,
    required String model,
    required int year,
    required int mileage,
    required String color,
    required String fuelType,
    required String engineCC,
    required String licensePlate,
    required String vin,
  }) {
    // Only brand and model are required
    if (brand.trim().isEmpty) {
      return CarOperationResult.error('Brand is required');
    }
    
    if (model.trim().isEmpty) {
      return CarOperationResult.error('Model is required');
    }
    
    // Validate year
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return CarOperationResult.error('Year must be between 1900 and ${currentYear + 1}');
    }
    
    // Validate mileage
    if (mileage < 0) {
      return CarOperationResult.error('Mileage cannot be negative');
    }
    
    if (mileage > 9999999) {
      return CarOperationResult.error('Mileage seems too high');
    }
    
    // Validate VIN length only if provided (standard VIN is 17 characters)
    if (vin.trim().isNotEmpty && vin.trim() != 'Not specified' && vin.trim().length != 17 && !vin.startsWith('VIN')) {
      return CarOperationResult.error('VIN must be exactly 17 characters');
    }
    
    // Validate license plate length only if provided
    if (licensePlate.trim().isNotEmpty && licensePlate.trim() != 'Not specified' && 
        (licensePlate.trim().length < 2 || licensePlate.trim().length > 10)) {
      return CarOperationResult.error('License plate must be between 2 and 10 characters');
    }
    
    return CarOperationResult.success(message: 'Validation passed');
  }

  /// Update car mileage by adding distance
  /// Used by automated mileage tracking system
  Future<CarOperationResult> updateCarMileage(int carId, double additionalMileage) async {
    try {
      // Check if user is authenticated
      if (!isUserAuthenticated) {
        return CarOperationResult.error('User must be signed in to update car mileage');
      }
      
      final userId = _currentUserId!;
      
      // Get existing car
      final existingCar = await _databaseHelper.getCarById(carId, userId);
      if (existingCar == null) {
        return CarOperationResult.error('Car not found');
      }
      
      // Calculate new mileage
      final newMileage = existingCar.mileage + additionalMileage.toInt();
      
      // Validate new mileage
      if (newMileage < 0) {
        return CarOperationResult.error('Mileage cannot be negative');
      }
      
      if (newMileage > 9999999) {
        return CarOperationResult.error('Mileage exceeds maximum value');
      }
      
      // Update car with new mileage
      final updatedCar = existingCar.copyWith(
        mileage: newMileage,
        updatedAt: DateTime.now(),
      );
      
      // Update car in database
      final rowsAffected = await _databaseHelper.updateCar(updatedCar);
      
      if (rowsAffected == 0) {
        return CarOperationResult.error('Failed to update car mileage');
      }
      
      final savedCar = await _databaseHelper.getCarById(carId, userId);
      
      return CarOperationResult.success(
        message: 'Car mileage updated successfully',
        car: savedCar,
      );
      
    } catch (e) {
      return CarOperationResult.error('Failed to update car mileage: ${e.toString()}');
    }
  }
}

