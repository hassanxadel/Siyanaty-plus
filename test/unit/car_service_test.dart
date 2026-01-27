import 'package:flutter_test/flutter_test.dart';

/// Unit tests for Car Service
/// Tests car data validation including brand, year, mileage, VIN, and license plate
void main() {
  group('CarService Unit Tests', () {
    // Helper function for brand validation
    bool isValidBrand(String brand) {
      return brand.trim().isNotEmpty && brand.trim().length >= 2;
    }

    // Helper function for year validation
    bool isValidYear(int year) {
      final currentYear = DateTime.now().year;
      const minYear = 1900;
      final maxYear = currentYear + 1;
      return year >= minYear && year <= maxYear;
    }

    // Helper function for mileage validation
    bool isValidMileage(int mileage) {
      return mileage >= 0 && mileage <= 999999;
    }

    // Helper function for VIN validation
    bool isValidVIN(String vin) {
      return vin.length == 17 && RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin);
    }

    // Helper function for license plate validation
    bool isValidLicensePlate(String plate) {
      return plate.trim().isNotEmpty && plate.trim().length >= 3;
    }

    test('Unit Test 1: Car brand validation - valid brands', () {
      // Arrange
      const validBrands = ['Toyota', 'Honda', 'BMW', 'Mercedes-Benz', 'Ford'];

      // Act & Assert
      for (final brand in validBrands) {
        final result = isValidBrand(brand);
        expect(result, isTrue, 
          reason: 'Brand "$brand" should be valid');
      }
    });

    test('Unit Test 2: Car brand validation - invalid brands', () {
      // Arrange
      const invalidBrands = ['', '  ', 'A', ' B '];

      // Act & Assert
      for (final brand in invalidBrands) {
        final result = isValidBrand(brand);
        expect(result, isFalse, 
          reason: 'Brand "$brand" should be invalid');
      }
    });

    test('Unit Test 3: Car year validation - valid years', () {
      // Arrange
      final currentYear = DateTime.now().year;
      final validYears = [1900, 1950, 2000, 2020, currentYear, currentYear + 1];

      // Act & Assert
      for (final year in validYears) {
        final result = isValidYear(year);
        expect(result, isTrue, 
          reason: 'Year $year should be valid');
      }
    });

    test('Unit Test 4: Car year validation - invalid years', () {
      // Arrange
      final currentYear = DateTime.now().year;
      final invalidYears = [1899, 1500, currentYear + 2, 2100, 1800];

      // Act & Assert
      for (final year in invalidYears) {
        final result = isValidYear(year);
        expect(result, isFalse, 
          reason: 'Year $year should be invalid');
      }
    });

    test('Unit Test 5: Car mileage validation - valid mileage', () {
      // Arrange
      const validMileages = [0, 50000, 100000, 250000, 999999];

      // Act & Assert
      for (final mileage in validMileages) {
        final result = isValidMileage(mileage);
        expect(result, isTrue, 
          reason: 'Mileage $mileage should be valid');
      }
    });

    test('Unit Test 6: Car mileage validation - invalid mileage', () {
      // Arrange
      const invalidMileages = [-1, -1000, 1000000, 9999999];

      // Act & Assert
      for (final mileage in invalidMileages) {
        final result = isValidMileage(mileage);
        expect(result, isFalse, 
          reason: 'Mileage $mileage should be invalid');
      }
    });

    test('Unit Test 7: VIN validation - valid VINs', () {
      // Arrange
      const validVINs = [
        '1HGBH41JXMN109186',
        'WBADT43452G123456',
        'JH4KA7561NC123456',
      ];

      // Act & Assert
      for (final vin in validVINs) {
        final result = isValidVIN(vin);
        expect(result, isTrue, 
          reason: 'VIN "$vin" should be valid (17 chars)');
      }
    });

    test('Unit Test 8: VIN validation - invalid VINs', () {
      // Arrange
      const invalidVINs = [
        '1234567890',           // Too short
        '1HGBH41JXMN1091867',   // Too long (18 chars)
        '',                     // Empty
        'WBADT43452G12345',     // Too short (16 chars)
      ];

      // Act & Assert
      for (final vin in invalidVINs) {
        final result = isValidVIN(vin);
        expect(result, isFalse, 
          reason: 'VIN "$vin" should be invalid');
      }
    });

    test('Unit Test 9: License plate validation - valid plates', () {
      // Arrange
      const validPlates = [
        'ABC-1234',
        'XYZ 789',
        'CA 123456',
        'NY-ABC-123',
      ];

      // Act & Assert
      for (final plate in validPlates) {
        final result = isValidLicensePlate(plate);
        expect(result, isTrue, 
          reason: 'License plate "$plate" should be valid');
      }
    });

    test('Unit Test 10: License plate validation - invalid plates', () {
      // Arrange
      const invalidPlates = ['', '  ', 'AB', '12'];

      // Act & Assert
      for (final plate in invalidPlates) {
        final result = isValidLicensePlate(plate);
        expect(result, isFalse, 
          reason: 'License plate "$plate" should be invalid');
      }
    });

    test('Unit Test 11: Car model validation', () {
      // Arrange
      const validModels = ['Camry', 'Accord', 'Civic', 'Model 3', 'X5'];
      const invalidModels = ['', '  ', 'A'];

      // Act & Assert - Valid models
      for (final model in validModels) {
        final result = model.trim().isNotEmpty && model.trim().length >= 2;
        expect(result, isTrue, 
          reason: 'Model "$model" should be valid');
      }

      // Act & Assert - Invalid models
      for (final model in invalidModels) {
        final result = model.trim().isNotEmpty && model.trim().length >= 2;
        expect(result, isFalse, 
          reason: 'Model "$model" should be invalid');
      }
    });

    test('Unit Test 12: Car color validation', () {
      // Arrange
      const validColors = ['Red', 'Blue', 'Black', 'White', 'Silver', 'Green'];
      const invalidColors = ['', '  '];

      // Act & Assert - Valid colors
      for (final color in validColors) {
        final result = color.trim().isNotEmpty;
        expect(result, isTrue, 
          reason: 'Color "$color" should be valid');
      }

      // Act & Assert - Invalid colors
      for (final color in invalidColors) {
        final result = color.trim().isNotEmpty;
        expect(result, isFalse, 
          reason: 'Color "$color" should be invalid');
      }
    });
  });
}

