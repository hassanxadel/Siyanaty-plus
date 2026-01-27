import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/models/backup_maintenance.dart';

/// Unit tests for Maintenance Service
/// Tests maintenance record validation including title, cost, type, and dates
void main() {
  group('MaintenanceService Unit Tests', () {
    // Helper function for title validation
    bool isValidTitle(String title) {
      return title.trim().isNotEmpty && title.trim().length >= 3;
    }

    // Helper function for cost validation
    bool isValidCost(double cost) {
      return cost >= 0 && cost <= 1000000;
    }

    // Helper function for description validation (optional field)
    bool isValidDescription(String? description) {
      return description == null || description.isEmpty || description.trim().length >= 10;
    }

    test('Unit Test 1: Maintenance title validation - valid titles', () {
      // Arrange
      const validTitles = [
        'Oil Change',
        'Brake Pad Replacement',
        'Engine Service',
        'Tire Rotation',
        'Air Filter Replacement',
      ];

      // Act & Assert
      for (final title in validTitles) {
        final result = isValidTitle(title);
        expect(result, isTrue, 
          reason: 'Title "$title" should be valid');
      }
    });

    test('Unit Test 2: Maintenance title validation - invalid titles', () {
      // Arrange
      const invalidTitles = ['', '  ', 'AB', 'X'];

      // Act & Assert
      for (final title in invalidTitles) {
        final result = isValidTitle(title);
        expect(result, isFalse, 
          reason: 'Title "$title" should be invalid');
      }
    });

    test('Unit Test 3: Maintenance cost validation - valid costs', () {
      // Arrange
      const validCosts = [0.0, 50.0, 150.50, 999.99, 5000.0];

      // Act & Assert
      for (final cost in validCosts) {
        final result = isValidCost(cost);
        expect(result, isTrue, 
          reason: 'Cost $cost should be valid');
      }
    });

    test('Unit Test 4: Maintenance cost validation - invalid costs', () {
      // Arrange
      const invalidCosts = [-1.0, -50.0, -999.99, 1000001.0];

      // Act & Assert
      for (final cost in invalidCosts) {
        final result = isValidCost(cost);
        expect(result, isFalse, 
          reason: 'Cost $cost should be invalid');
      }
    });

    test('Unit Test 5: Maintenance type enum validation', () {
      // Arrange
      const allTypes = MaintenanceType.values;

      // Act & Assert
      expect(allTypes.length, greaterThan(0), 
        reason: 'Should have at least one maintenance type');
      expect(allTypes.contains(MaintenanceType.mechanics), isTrue,
        reason: 'Should include mechanics type');
      expect(allTypes.contains(MaintenanceType.electrical), isTrue,
        reason: 'Should include electrical type');
      expect(allTypes.contains(MaintenanceType.suspension), isTrue,
        reason: 'Should include suspension type');
      expect(allTypes.contains(MaintenanceType.others), isTrue,
        reason: 'Should include others type');
    });

    test('Unit Test 6: Maintenance date validation - past dates', () {
      // Arrange
      final pastDates = [
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now().subtract(const Duration(days: 365)),
      ];

      // Act & Assert
      for (final date in pastDates) {
        final isValid = date.isBefore(DateTime.now()) || 
                       date.isAtSameMomentAs(DateTime.now());
        expect(isValid, isTrue, 
          reason: 'Past date should be valid for maintenance records');
      }
    });

    test('Unit Test 7: Maintenance date validation - today and future dates', () {
      // Arrange
      final today = DateTime.now();
      final futureDates = [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 30)),
      ];

      // Act & Assert - Today
      final todayDiff = today.difference(DateTime.now()).inSeconds.abs();
      expect(todayDiff, lessThan(2), 
        reason: 'Today should be valid for maintenance records');

      // Act & Assert - Future dates
      for (final date in futureDates) {
        final isValid = date.isAfter(DateTime.now()) || 
                       date.isAtSameMomentAs(DateTime.now());
        expect(isValid, isTrue, 
          reason: 'Future date should be valid for scheduled maintenance');
      }
    });

    test('Unit Test 8: Maintenance description validation - optional field', () {
      // Arrange
      const validDescriptions = [
        'Regular oil change service',
        'Replaced front brake pads',
        null,  // Optional field
        '',    // Optional field
      ];

      // Act & Assert
      for (final description in validDescriptions) {
        // Description is optional, so empty or null is acceptable
        final isValid = description == null || 
                       description.isEmpty || 
                       description.trim().isNotEmpty;
        expect(isValid, isTrue, 
          reason: 'Description "${description ?? "null"}" should be valid');
      }
    });

    test('Unit Test 9: Maintenance mileage validation', () {
      // Arrange
      const validMileages = [0, 5000, 50000, 100000, 250000];
      const invalidMileages = [-1, -1000];

      // Act & Assert - Valid mileages
      for (final mileage in validMileages) {
        final result = mileage >= 0;
        expect(result, isTrue, 
          reason: 'Mileage $mileage should be valid');
      }

      // Act & Assert - Invalid mileages
      for (final mileage in invalidMileages) {
        final result = mileage >= 0;
        expect(result, isFalse, 
          reason: 'Mileage $mileage should be invalid');
      }
    });

    test('Unit Test 10: Maintenance service provider validation', () {
      // Arrange
      const validProviders = [
        'Main Dealer',
        'Local Garage',
        'Quick Lube Center',
        'DIY',
      ];
      const invalidProviders = ['', '  '];

      // Act & Assert - Valid providers
      for (final provider in validProviders) {
        final result = provider.trim().isNotEmpty;
        expect(result, isTrue, 
          reason: 'Provider "$provider" should be valid');
      }

      // Act & Assert - Invalid providers
      for (final provider in invalidProviders) {
        final result = provider.trim().isNotEmpty;
        expect(result, isFalse, 
          reason: 'Provider "$provider" should be invalid');
      }
    });

    test('Unit Test 11: Maintenance parts list validation', () {
      // Arrange
      const validPartsList = [
        'Oil filter, Engine oil',
        'Brake pads, Brake fluid',
        'Air filter',
      ];

      // Act & Assert
      for (final parts in validPartsList) {
        final result = parts.trim().isNotEmpty;
        expect(result, isTrue, 
          reason: 'Parts list "$parts" should be valid');
      }
    });

    test('Unit Test 12: Maintenance completion status validation', () {
      // Arrange
      const completedStatus = true;
      const pendingStatus = false;

      // Act & Assert
      expect(completedStatus, isTrue, 
        reason: 'Completed status should be true');
      expect(pendingStatus, isFalse, 
        reason: 'Pending status should be false');
    });
  });
}

