# Unit Tests

This directory contains unit tests for core services in the Siyanaty+ application.

## Test Files

### 1. auth_service_test.dart (8 tests)
Tests authentication-related validation logic:
- Email format validation
- Password strength validation  
- Phone number format validation
- Registration data validation
- Email normalization
- Password confirmation matching
- Empty field validation

### 2. car_service_test.dart (12 tests)
Tests car data validation:
- Brand name validation
- Year range validation (1900 to current+1)
- Mileage validation (0 to 999,999)
- VIN validation (17 characters)
- License plate validation
- Model and color validation

### 3. maintenance_service_test.dart (12 tests)
Tests maintenance record validation:
- Title validation
- Cost validation (0 to 1,000,000)
- Maintenance type enum validation
- Date validation (past, present, future)
- Optional field handling
- Mileage and service provider validation

### 4. reminder_service_test.dart (14 tests)
Tests reminder functionality validation:
- Title validation
- Priority levels (low, medium, high, urgent)
- Reminder types (maintenance, inspection, etc.)
- Date validation (past for overdue, future for upcoming)
- Mileage target validation
- Notification settings
- Advance notification days

**Total: 46 unit tests**

## Running Unit Tests

### Run All Unit Tests
```bash
flutter test test/unit/
```

### Run Specific Test File
```bash
flutter test test/unit/auth_service_test.dart
flutter test test/unit/car_service_test.dart
flutter test test/unit/maintenance_service_test.dart
flutter test test/unit/reminder_service_test.dart
```

### Run Single Test
```bash
flutter test test/unit/auth_service_test.dart --name "Valid email format"
```

### Run with Coverage
```bash
flutter test test/unit/ --coverage
```

## Test Results

All unit tests are currently **PASSING** ✅

```
AuthService Unit Tests: 8/8 passed
CarService Unit Tests: 12/12 passed  
MaintenanceService Unit Tests: 12/12 passed
ReminderService Unit Tests: 14/14 passed

Total: 46/46 passed
```

## Test Structure

Each test follows the **Arrange-Act-Assert** pattern:

```dart
test('Test description', () {
  // Arrange: Set up test data
  const input = 'test@example.com';
  
  // Act: Execute the function being tested
  final result = isValidEmail(input);
  
  // Assert: Verify the result
  expect(result, isTrue);
});
```

## Automated Execution

Use the PowerShell automation script from the project root:
```powershell
.\scripts\run_all_tests.ps1
```

## Log Files

Test results are saved to `test_logs/` in the project root:
- `unit_tests_<timestamp>.log` - Detailed test output

## For More Information

See the main test suite documentation:
- [TEST_SUITE_COMPREHENSIVE.md](../../TEST_SUITE_COMPREHENSIVE.md)
- [TESTING_QUICK_REFERENCE.md](../../TESTING_QUICK_REFERENCE.md)
