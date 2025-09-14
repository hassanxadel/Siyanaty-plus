# Car Management System - Setup Instructions

## Overview
This document provides complete setup instructions for implementing the car management system with local SQLite database and Firebase cloud backup functionality.

## Dependencies

Add these dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1
  
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  
  # Image handling
  image_picker: ^1.0.4
  
  # State management (if not already added)
  provider: ^6.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## Firebase Setup

### 1. Firebase Console Configuration

Since your app is already connected to Firebase, you need to:

1. **Open Firebase Console** → Go to your existing project
2. **Enable Firestore Database**:
   - Navigate to "Firestore Database" in the left sidebar
   - Click "Create database"
   - Choose "Start in production mode" (recommended)
   - Select your preferred location

3. **Firebase Storage** (Optional - Not Required):
   - Firebase Storage is not needed for this implementation
   - Car images are stored locally on the device only
   - Skip this step entirely

4. **Set up Firestore Security Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // Allow access to user's cars subcollection
         match /cars/{carId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```


### 2. Firestore Database Structure

The system will create the following structure automatically:

```
/users/{userId}/
├── last_backup_time: timestamp
├── last_backup_success_count: number
├── last_backup_failure_count: number
└── cars/{carId}/
    ├── brand: string
    ├── model: string
    ├── year: number
    ├── mileage: number
    ├── color: string
    ├── fuel_type: string
    ├── engine_cc: string
    ├── turbo: boolean
    ├── license_plate: string
    ├── vin: string
    ├── image_path: string (local path only)
    ├── local_id: number (reference to local SQLite ID)
    ├── created_at: string (ISO 8601)
    ├── updated_at: string (ISO 8601)
    └── backup_timestamp: timestamp
```

## Implementation Steps

### 1. Add the Model and Services

Copy the following files to your project:
- `lib/models/car.dart`
- `lib/database/database_helper.dart`
- `lib/services/car_service.dart`
- `lib/services/firebase_backup_service.dart`
- `lib/widgets/backup_button_widget.dart`

### 2. Initialize Database

Add this to your main app initialization:

```dart
// In your main.dart or app initialization
import 'package:flutter/material.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (if not already done)
  await Firebase.initializeApp();
  
  // Initialize database
  await DatabaseHelper.instance.database;
  
  runApp(MyApp());
}
```

### 3. Add Backup Button to Settings Screen

In your settings screen, add the backup widget:

```dart
import '../widgets/backup_button_widget.dart';

// In your settings screen build method
Widget build(BuildContext context) {
  return Scaffold(
    // ... other settings content
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ... other settings widgets
          
          const SizedBox(height: 24),
          const BackupButtonWidget(),
          
          // ... other settings widgets
        ],
      ),
    ),
  );
}
```

### 4. Update Your Car Management Screen

Update your existing car management screen to use the new services:

```dart
import '../services/car_service.dart';
import '../models/car.dart';

class MyCarsScreen extends StatefulWidget {
  // ... existing code
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final CarService _carService = CarService();
  List<Car> _cars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cars = await _carService.getAllCars();
      setState(() {
        _cars = cars;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cars: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCar() async {
    // Example of adding a car
    final result = await _carService.addCar(
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
      _loadCars(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ... rest of your implementation
}
```

## Usage Examples

### Adding a Car
```dart
final carService = CarService();

final result = await carService.addCar(
  brand: 'Honda',
  model: 'Civic',
  year: 2022,
  mileage: 25000,
  color: 'Blue',
  fuelType: 'Gasoline',
  engineCC: '2.0L',
  turbo: true,
  licensePlate: 'XYZ789',
  vin: '2HGFC2F59NH123456',
  imagePath: '/path/to/image.jpg', // Optional
);

if (result.isSuccess) {
  print('Car added successfully: ${result.car?.id}');
} else {
  print('Error: ${result.message}');
}
```

### Updating a Car
```dart
final result = await carService.updateCar(
  id: 1,
  brand: 'Honda',
  model: 'Civic',
  year: 2022,
  mileage: 26000, // Updated mileage
  color: 'Blue',
  fuelType: 'Gasoline',
  engineCC: '2.0L',
  turbo: true,
  licensePlate: 'XYZ789',
  vin: '2HGFC2F59NH123456',
);
```

### Searching Cars
```dart
final cars = await carService.searchCars('Toyota');
```

### Backup to Cloud
```dart
final backupService = FirebaseBackupService();
final result = await backupService.backupAllCarsToFirebase();

if (result.isSuccess) {
  print('Backup completed: ${result.carsProcessed} cars backed up');
} else {
  print('Backup failed: ${result.message}');
}
```

## Error Handling

The system includes comprehensive error handling:

1. **Database Errors**: Handled by `DatabaseException`
2. **Validation Errors**: Handled by `CarOperationResult`
3. **Firebase Errors**: Handled by service-level try-catch blocks
4. **Network Errors**: Automatically handled by Firebase SDK

## Security Considerations

1. **Data Validation**: All inputs are validated before database operations
2. **User Authentication**: Firebase backup requires user authentication
3. **Data Isolation**: Users can only access their own data
4. **Unique Constraints**: VIN and license plate uniqueness enforced
5. **Image Security**: Images stored in user-specific Firebase Storage paths

## Performance Optimization

1. **Database Indexing**: Indexes on frequently queried fields
2. **Batch Operations**: Firebase writes use batch operations
3. **Lazy Loading**: Cars loaded on-demand
4. **Connection Pooling**: SQLite connection reuse
5. **Error Recovery**: Partial backup/restore support

## Testing

To test the implementation:

1. **Add Test Cars**: Use the car management screen to add test data
2. **Test Backup**: Use the backup button in settings
3. **Test Restore**: Clear local data and restore from cloud
4. **Test Offline**: Ensure local operations work without internet
5. **Test Validation**: Try invalid data to test validation

## Troubleshooting

### Common Issues:

1. **"User not authenticated"**: Ensure user is signed in to Firebase
2. **"VIN already exists"**: Each car must have unique VIN
3. **"Image not found"**: Check local image file permissions
4. **"Database locked"**: Ensure proper database connection cleanup
5. **"Firebase Storage not configured"**: 
   - This is expected - images are stored locally only
   - No Firebase Storage setup required

### Debug Steps:

1. Check Firebase console for data
2. Enable Firebase debug logging
3. Check device storage permissions
4. Verify network connectivity
5. Check Firestore security rules

This completes the full implementation of the car management system with local SQLite storage and Firebase cloud backup functionality.
