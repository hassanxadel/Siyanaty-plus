# Siyanaty+ - Smart Car Maintenance App

[![Flutter](https://img.shields.io/badge/Flutter-3.5.3+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5.3+-blue.svg)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-green.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

## 📋 Overview

**Siyanaty+** is a comprehensive Flutter-based car maintenance application that revolutionizes vehicle maintenance management through digital transformation. The app transitions vehicle care from reactive to proactive management using real-time diagnostics, smart reminders, and intelligent service integration.

### 🚀 Key Features

- **Multi-Vehicle Management** - Manage multiple cars with individual profiles
- **Real-Time OBD-II Diagnostics** - Live vehicle health monitoring and diagnostics
- **Smart Maintenance Reminders** - AI-powered scheduling and priority-based alerts
- **Service Center Locator** - Find nearby service centers with filtering capabilities
- **VIN Lookup & Scanner** - Vehicle information retrieval and barcode scanning
- **OCR Document Scanner** - Extract data from service reports and documents
- **Voice Notes** - Quick maintenance notes with speech recognition
- **Mileage Tracking** - Predictive maintenance based on usage patterns
- **Maintenance Records** - Comprehensive service history and cost tracking
- **Dark/Light Theme Support** - Modern UI with customizable themes
- **Offline Functionality** - Works without internet connection using local storage

---

## 🏗️ Architecture

### Clean Architecture Implementation

The app follows Clean Architecture principles with three main layers:

- **Domain Layer** (`lib/domain/`) - Business logic and entities
- **Presentation Layer** (`lib/presentation/`) - UI components and state management
- **Shared Layer** (`lib/shared/`) - Services, utilities, and constants

### Technology Stack

#### Frontend Technologies
- **Flutter 3.5.3+** - Cross-platform mobile development
- **Dart** - Primary programming language
- **Material Design 3** - Modern UI/UX framework
- **Provider Pattern** - State management architecture
- **Orbitron Font Family** - Futuristic typography system

#### Backend & Cloud Services
- **Firebase Authentication** - User authentication and authorization
- **Google Sign-In** - Social authentication integration
- **Cloud Firestore** - NoSQL cloud database
- **Firebase Storage** - File and document storage
- **SQLite (sqflite)** - Local database for offline functionality
- **Shared Preferences** - Application settings storage

#### Hardware Integration (Planned)
- **Bluetooth Communication** - OBD-II device connectivity
- **GPS & Location Services** - Service center location and navigation
- **Camera Integration** - Document and barcode scanning
- **Voice Recognition** - Speech-to-text functionality

---

## 📱 Screenshots & Features

### Main Dashboard
- **Home Screen** - Welcome interface with quick actions and vehicle overview
- **Quick Actions Grid** - 12 main features accessible from home
- **Vehicle Health Cards** - Real-time status indicators
- **Recent Activity Feed** - Latest maintenance activities

### Core Features
- **OBD Diagnostics** - Real-time vehicle data and health monitoring
- **Smart Reminders** - Priority-based maintenance scheduling
- **Service Centers** - Location-based service discovery
- **Multi-Car Management** - Individual vehicle profiles
- **Settings & Profile** - User customization and preferences

### Advanced Tools
- **VIN Lookup** - Vehicle information and maintenance recommendations
- **OCR Scanner** - Extract data from service reports
- **Barcode Scanner** - Part details and product information
- **Voice Notes** - Quick maintenance notes with speech recognition
- **Mileage Tracking** - Usage-based maintenance predictions

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.5.3 or higher
- Dart SDK 3.5.3 or higher
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hassanxadel/Siyanaty-plus.git
   cd Siyanaty-plus
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase (Optional)**
   - Add your `google-services.json` to `android/app/`
   - Configure Firebase project settings
   - Update `lib/firebase_options.dart` with your configuration

4. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

---

## 📊 Project Status

### Current Progress: 65% Complete

#### ✅ Completed Phases

**Phase 1: Foundation Development (95% Complete)**
- ✅ Authentication System with Firebase integration
- ✅ User Interface Framework with custom themes
- ✅ Clean Architecture implementation
- ✅ Provider pattern for state management

**Phase 2: Core Features Development (80% Complete)**
- ✅ Main application screens (25+ screens)
- ✅ Data models and local storage
- ✅ Navigation system with bottom navigation
- ✅ Theme switching (Dark/Light mode)

**Phase 3: Backend Integration (85% Complete)**
- ✅ Firebase Authentication configuration
- ✅ Cloud Firestore database setup
- ✅ Firebase Storage integration
- ✅ Security rules and access control

#### 🚧 In Progress

**Phase 4: Hardware Integration (10% Complete)**
- 🔄 OBD-II communication system
- 🔄 Location services integration
- 🔄 Camera and scanning features
- 🔄 Bluetooth device connectivity

#### 📋 Planned Features

**Phase 5: Data Integration & APIs**
- 📋 VIN lookup system with NHTSA API
- 📋 Service center database population
- 📋 Maintenance prediction algorithms
- 📋 Real-time data synchronization

**Phase 6: Advanced Features**
- 📋 Notification system (local & push)
- 📋 Voice commands and documentation
- 📋 Analytics and reporting
- 📋 Performance optimization

---

## 🛠️ Development

### Project Structure

```
lib/
├── domain/
│   └── entities/          # Business logic entities
├── presentation/
│   ├── providers/         # State management
│   ├── screens/           # UI screens (25+ screens)
│   └── widgets/          # Reusable UI components
├── shared/
│   ├── constants/        # App constants and themes
│   ├── services/         # Core services (Firebase, Database)
│   └── utils/           # Utility functions and helpers
└── main.dart            # App entry point
```

### Key Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.2                    # State management
  sqflite: ^2.3.3+1                    # Local database
  shared_preferences: ^2.3.2           # Settings storage
  firebase_core: ^2.15.0              # Firebase core
  firebase_auth: ^4.7.0               # Authentication
  cloud_firestore: ^4.8.0             # Cloud database
  firebase_storage: ^11.2.0           # File storage
  google_sign_in: ^6.1.5             # Google authentication
  image_picker: ^1.0.7                # Image selection
  file_picker: ^8.0.0+1              # File selection
  intl: ^0.18.1                       # Internationalization
```

### Code Quality

- **Clean Architecture** - Separation of concerns
- **Provider Pattern** - Reactive state management
- **Comprehensive Documentation** - Inline code documentation
- **Error Handling** - Graceful degradation and recovery
- **Performance Optimization** - Efficient memory and battery usage

---

## 🎯 Success Metrics

### Technical Performance
- **Application Startup Time**: < 2 seconds
- **Memory Usage**: < 100MB average
- **Battery Consumption**: < 5% per hour
- **Crash Rate**: < 0.1%

### User Experience
- **User Retention**: > 80% after 30 days
- **Feature Adoption**: > 60% for core features
- **User Satisfaction**: > 4.5/5 rating
- **Support Requests**: < 5% of users

### Business Metrics
- **Monthly Active Users**: Target 10,000+
- **Premium Feature Conversion**: > 15%
- **User Engagement**: > 20 minutes daily
- **App Store Rating**: Target > 4.5 stars

---

## 🔧 Configuration

### Environment Setup

1. **Flutter Environment**
   ```bash
   flutter doctor
   flutter config --enable-web
   ```

2. **Firebase Configuration**
   - Create Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download configuration files
   - Update `lib/firebase_options.dart`

3. **Development Tools**
   - Enable developer options on device
   - Configure USB debugging (Android)
   - Install Flutter extensions in IDE

### Build Configuration

#### Android (`android/app/build.gradle`)
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.example.siyanaty_plus"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleDisplayName</key>
<string>Siyanaty+</string>
<key>CFBundleIdentifier</key>
<string>com.example.siyanatyPlus</string>
```

---

## 🧪 Testing

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage

- **Unit Tests** - Service and utility testing
- **Widget Tests** - UI component functionality
- **Integration Tests** - End-to-end workflow validation
- **Performance Tests** - Load and stress testing

---

## 🚨 Troubleshooting

### Common Issues

1. **Firebase Connection Issues**
   ```bash
   # Check Firebase configuration
   flutter clean
   flutter pub get
   ```

2. **Build Errors**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter build apk
   ```

3. **Dependency Conflicts**
   ```bash
   # Update dependencies
   flutter pub upgrade
   flutter pub deps
   ```

### Debug Mode

```bash
# Enable debug logging
flutter run --debug

# Check device logs
flutter logs
```

---

## 🤝 Contributing

### Development Guidelines

1. **Code Style**
   - Follow Dart/Flutter conventions
   - Use meaningful variable names
   - Add comprehensive comments
   - Maintain consistent formatting

2. **Architecture**
   - Follow Clean Architecture principles
   - Use Provider pattern for state management
   - Implement proper error handling
   - Write unit tests for new features

3. **Git Workflow**
   ```bash
   # Create feature branch
   git checkout -b feature/new-feature
   
   # Commit changes
   git add .
   git commit -m "Add new feature"
   
   # Push and create PR
   git push origin feature/new-feature
   ```

### Pull Request Process

1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request
6. Address review feedback

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 📞 Contact & Support

### Project Information
- **Repository**: https://github.com/hassanxadel/Siyanaty-plus
- **Documentation**: See `/docs` folder for detailed documentation
- **Issues**: Use GitHub Issues for bug reports and feature requests

### Development Team
- **Lead Developer**: Hassan Adel
- **Project Status**: Active Development
- **Last Updated**: December 2024

### Getting Help

1. **Documentation** - Check this README and inline code comments
2. **Issues** - Search existing GitHub issues
3. **Discussions** - Use GitHub Discussions for questions
4. **Email** - Contact project maintainer for urgent issues

---

## 🗺️ Roadmap

### Short Term (Next 3 months)
- Complete OBD-II hardware integration
- Implement real-time location services
- Add comprehensive testing suite
- Optimize performance and battery usage

### Medium Term (3-6 months)
- Deploy to app stores (Google Play & App Store)
- Implement advanced analytics
- Add social features and community
- Integrate with automotive APIs

### Long Term (6+ months)
- Machine learning for predictive maintenance
- IoT device integration
- Enterprise features and partnerships
- Multi-language support

---

**Document Version**: 2.0 | **Last Updated**: December 2024 | **Project Status**: Active Development

## 🔑 API Keys & New Features Setup

1. Configure keys in `lib/shared/constants/app_constants.dart`:
   - `zpkApiKey`: set your RapidAPI key for VIN decoding
   - `googleMapsApiKey`: set your Google Maps API key

2. VIN Lookup Usage:
   - Open `VIN Lookup` screen, enter a 17-character VIN, tap "Lookup VIN"
   - The app fetches Make, Model, Year, Engine, Transmission, Body Style, Fuel Type
   - Tap "Save to My Cars" to add a minimal car record using `CarService`

3. Service Centers (backend available):
   - Get current coordinates with `LocationService.getCurrentPosition()`
   - Fetch nearby centers with `ServiceCenterService.findNearbyServiceCenters(latitude, longitude)`
   - Integrate results into a UI list as desired (e.g., map or list view)

4. Permissions (Android):
   - Location permission is requested by `geolocator` at runtime
   - Ensure Google Places API is enabled for your key in Google Cloud Console