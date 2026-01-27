# Integration Tests

This directory contains integration tests for the Siyanaty+ application.

## Test Files

### 1. auth_workflow_test.dart
Tests the complete authentication workflows including:
- New user registration with unique credentials
- Existing user login (hassanadelh@outlook.com / 040800Masr)
- Invalid credential handling
- UI navigation and element verification

**5 integration test cases**

### 2. app_test.dart
Tests general application workflows including:
- App launch and initialization
- UI element rendering
- Navigation between screens
- User interactions (buttons, text input, scrolling)
- Icon and image rendering

**8 integration test cases**

## Running Integration Tests

### Prerequisites
- Connected Android device or running emulator
- USB debugging enabled (for physical devices)
- ADB installed and configured

### Run All Integration Tests
```bash
flutter test integration_test/
```

### Run Specific Test File
```bash
flutter test integration_test/auth_workflow_test.dart
flutter test integration_test/app_test.dart
```

### Run with Device
```bash
# List connected devices
flutter devices

# Run on specific device
flutter test integration_test/ -d <device-id>
```

## Test Credentials

### Existing User Login
- **Email**: hassanadelh@outlook.com
- **Password**: 040800Masr

### New User Registration
- Auto-generated with timestamp for uniqueness
- Format: testuser{timestamp}@test.com

## Automated Execution

Use the PowerShell automation script from the project root:
```powershell
.\scripts\run_all_tests.ps1
```

This will:
- Check for connected devices
- Run all unit tests
- Run all integration tests
- Generate comprehensive logs

## Troubleshooting

### No Devices Found
```
Error: No devices found
```
**Solution**: Connect a device or start an emulator

### ADB Not Found
```
Error: 'adb' is not recognized
```
**Solution**: Install Android SDK and add to PATH

### Test Timeout
If tests timeout, increase the timeout duration or check device performance.

## Log Files

Test results are saved to `test_logs/` in the project root:
- `integration_tests_<timestamp>.log` - Detailed test output
- `test_summary_<timestamp>.log` - Executive summary

## For More Information

See the main test suite documentation:
- [TEST_SUITE_COMPREHENSIVE.md](../../TEST_SUITE_COMPREHENSIVE.md)
- [TESTING_QUICK_REFERENCE.md](../../TESTING_QUICK_REFERENCE.md)
