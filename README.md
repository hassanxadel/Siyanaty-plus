# Siyanaty+ Car Maintenance Application

A comprehensive Flutter-based car maintenance and management application with smart features for tracking vehicle health, maintenance schedules, and reminders.

## Features

- **User Authentication**: Secure login with Firebase Auth, MFA, and PIN protection
- **Car Management**: Add and manage multiple vehicles with images
- **Maintenance Tracking**: Track all maintenance activities with costs and dates
- **Smart Reminders**: Set reminders based on date or mileage with notifications
- **OCR Integration**: Scan documents for easy data entry
- **OBD-II Integration**: Connect to your car via Bluetooth for real-time diagnostics
- **Car Health Score**: Comprehensive health monitoring based on maintenance history
- **Mileage Tracking**: Track fuel consumption and calculate efficiency
- **Cloud Backup**: Sync data with Firebase across devices

## Quick Start

### Prerequisites

- Flutter SDK (version 3.5.3 or later)
- Dart SDK (included with Flutter)
- Android SDK (for Android development)
- Firebase account (for cloud features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/siyanaty-plus.git
   cd siyanaty-plus
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories

4. **Run the app**
   ```bash
   flutter run
   ```

## Documentation

All documentation is organized in the `docs/` folder:

| Document | Description |
|----------|-------------|
| [APP_ARCHITECTURE.md](docs/APP_ARCHITECTURE.md) | Application structure, patterns, and data flow |
| [DATABASE.md](docs/DATABASE.md) | Complete SQLite database schema and ERD |
| [SERVICES.md](docs/SERVICES.md) | All services (Car, Maintenance, Mileage, etc.) |
| [SECURITY_AUTHENTICATION.md](docs/SECURITY_AUTHENTICATION.md) | Authentication, MFA, PIN, and security features |
| [EMAIL_VERIFICATION.md](docs/EMAIL_VERIFICATION.md) | Email verification and Firebase email setup |
| [CLOUD_SYNC.md](docs/CLOUD_SYNC.md) | Cloud backup and restore functionality |
| [OBD_INTEGRATION.md](docs/OBD_INTEGRATION.md) | OBD-II Bluetooth diagnostics |
| [CAR_HEALTH.md](docs/CAR_HEALTH.md) | Car health score algorithm |
| [NAVIGATION.md](docs/NAVIGATION.md) | Global navigation system |
| [RESPONSIVE_DESIGN.md](docs/RESPONSIVE_DESIGN.md) | Responsive design utilities |
| [TESTING.md](docs/TESTING.md) | Test suite documentation |

### Feature Documentation

| Document | Description |
|----------|-------------|
| [VIN_LOOKUP.md](docs/VIN_LOOKUP.md) | VIN decoder API integration |
| [VOICE_NOTES.md](docs/VOICE_NOTES.md) | Voice recording feature |
| [SERVICE_CENTERS.md](docs/SERVICE_CENTERS.md) | Google Maps service center finder |
| [PIN_CODE.md](docs/PIN_CODE.md) | PIN security and biometric auth |
| [MFA.md](docs/MFA.md) | Multi-factor authentication (Email OTP) |
| [REMINDERS.md](docs/REMINDERS.md) | Maintenance reminders system |
| [MAINTENANCE.md](docs/MAINTENANCE.md) | Maintenance records tracking |
| [OCR_SCANNER.md](docs/OCR_SCANNER.md) | Document scanning with ML Kit |
| [MY_CARS.md](docs/MY_CARS.md) | Car management feature |
| [MILEAGE_TRACKER.md](docs/MILEAGE_TRACKER.md) | Fuel and mileage tracking |
| [NOTIFICATIONS.md](docs/NOTIFICATIONS.md) | Local push notifications |
| [PROFILE.md](docs/PROFILE.md) | User profile management |

## Testing

The project includes 67 automated tests.

### Quick Test Execution

```powershell
# Windows PowerShell
.\scripts\run_all_tests.ps1
```

```bash
# Manual testing
flutter test                    # Run all tests
flutter test test/unit/         # Unit tests only
flutter test integration_test/  # Integration tests only
```

### Test Coverage

- **Unit Tests**: 46 tests (auth, car, maintenance, reminder services)
- **Widget Tests**: 8 tests (UI components)
- **Integration Tests**: 13 tests (complete workflows)

See [docs/TESTING.md](docs/TESTING.md) for detailed testing documentation.

## Project Structure

```
lib/
├── database/           # SQLite database helpers
├── models/             # Data models
├── presentation/       # UI layer
│   ├── screens/       # App screens
│   ├── widgets/       # Reusable widgets
│   └── providers/     # State management
├── services/          # Business logic layer
│   ├── security/      # Auth, MFA, PIN services
│   ├── obd/           # OBD-II services
│   └── bluetooth/     # Bluetooth connectivity
├── shared/            # Shared utilities
└── main.dart          # Entry point

docs/                   # Documentation
scripts/               # Automation scripts
test/                  # Test files
```

## Key Features

### Security
- Firebase Authentication
- Multi-Factor Authentication (Email OTP)
- PIN/Biometric local authentication
- Encrypted local database (SQLCipher)
- Device trust management

### Car Management
- Multiple vehicle support
- VIN decoding
- License plate storage
- Car images

### Maintenance
- Service record tracking
- Cost tracking
- Service provider info
- Invoice storage

### Reminders
- Date-based reminders
- Mileage-based reminders
- Push notifications
- Priority levels

### OBD-II Diagnostics
- Real-time vehicle data
- RPM, Speed, Temperature
- Fuel level, Battery voltage
- Diagnostic trouble codes

### Mileage Tracking
- Fuel consumption logging
- Cost tracking
- Efficiency calculations
- Statistics and charts

## Building for Production

### Android

```bash
flutter build apk --release        # Build APK
flutter build appbundle --release  # Build App Bundle
```

### iOS

```bash
flutter build ios --release
```

## Supported Platforms

- Android (API 21+)
- iOS (iOS 12.0+)
- Web (limited features)

## Dependencies

Key dependencies include:
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase services
- `sqflite_sqlcipher` - Encrypted local database
- `flutter_secure_storage` - Secure key-value storage
- `flutter_bluetooth_serial` - OBD-II Bluetooth communication
- `google_ml_kit_text_recognition` - OCR
- `provider` - State management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License.

---

**Built with Flutter**
