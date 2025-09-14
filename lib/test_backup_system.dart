/// Test file to demonstrate the backup system usage
/// This shows how to use the user-specific car management and backup functionality
/// NOTE: User must be signed in to Firebase Auth for these operations to work
library;

import 'services/car_service.dart';
import 'services/firebase_backup_service.dart';

/// Example usage of the car backup system
void testBackupSystem() async {
  final carService = CarService();
  final backupService = FirebaseBackupService();

  try {
    // 1. Add a car to local database
    print('Adding car to local database...');
    final result = await carService.addCar(
      brand: 'Toyota',
      model: 'Camry',
      year: 2023,
      mileage: 15000,
      color: 'White',
      fuelType: 'Gasoline',
      engineCC: '2.5L',
      turbo: false,
      licensePlate: 'ABC123',
      vin: '1HGBH41JXMN109186',
    );

    if (result.isSuccess) {
      print('✅ Car added successfully: ${result.message}');
    } else {
      print('❌ Failed to add car: ${result.message}');
      return;
    }

    // 2. Get all cars from local database (user-specific)
    print('\nRetrieving all cars from local database for current user...');
    final cars = await carService.getAllCars();
    print('📱 Local cars count for current user: ${cars.length}');
    for (final car in cars) {
      print('  - ${car.brand} ${car.model} (${car.year}) - Owner: ${car.userId}');
    }

    // 3. Get backup status
    print('\nChecking backup status...');
    final status = await backupService.getBackupStatus();
    print('🔐 Authenticated: ${status.isAuthenticated}');
    print('📱 Local cars for current user: ${status.localCarsCount}');
    print('☁️ Cloud cars for current user: ${status.cloudCarsCount}');
    if (status.lastBackupTime != null) {
      print('⏰ Last backup: ${status.lastBackupTime}');
    }

    // 4. Backup to cloud (only if authenticated)
    if (status.isAuthenticated) {
      print('\nBacking up cars to cloud...');
      final backupResult = await backupService.backupAllCarsToFirebase();
      
      if (backupResult.isSuccess) {
        print('✅ Backup successful: ${backupResult.message}');
        print('📤 Cars backed up: ${backupResult.carsProcessed}');
      } else if (backupResult.isPartialSuccess) {
        print('⚠️ Partial backup: ${backupResult.message}');
        print('📤 Cars backed up: ${backupResult.carsProcessed}');
        if (backupResult.errors != null) {
          print('❌ Errors:');
          for (final error in backupResult.errors!) {
            print('  - $error');
          }
        }
      } else {
        print('❌ Backup failed: ${backupResult.message}');
      }
    } else {
      print('⚠️ User not authenticated - backup skipped');
    }

    print('\n🎉 Test completed successfully!');
    
  } catch (e) {
    print('💥 Test failed with error: $e');
  }
}

/// Example of how to integrate with your car form
Future<void> addCarFromForm({
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
  final carService = CarService();
  
  final result = await carService.addCar(
    brand: brand,
    model: model,
    year: year,
    mileage: mileage,
    color: color,
    fuelType: fuelType,
    engineCC: engineCC,
    turbo: turbo,
    licensePlate: licensePlate,
    vin: vin,
    imagePath: imagePath,
  );
  
  if (result.isSuccess) {
    print('Car added successfully!');
    
    // Optionally backup immediately
    final backupService = FirebaseBackupService();
    if (result.car != null) {
      final backupResult = await backupService.backupCarToFirebase(result.car!);
      if (backupResult.isSuccess) {
        print('Car backed up to cloud!');
      }
    }
  } else {
    print('Failed to add car: ${result.message}');
  }
}

/// Example of how to restore from cloud
Future<void> restoreFromCloud() async {
  final backupService = FirebaseBackupService();
  
  final result = await backupService.restoreCarsFromFirebase();
  
  if (result.isSuccess) {
    print('Restore successful: ${result.message}');
    print('Cars restored: ${result.carsProcessed}');
  } else if (result.isPartialSuccess) {
    print('Partial restore: ${result.message}');
    print('Cars restored: ${result.carsProcessed}');
    if (result.errors != null) {
      print('Errors:');
      for (final error in result.errors!) {
        print('  - $error');
      }
    }
  } else {
    print('Restore failed: ${result.message}');
  }
}
