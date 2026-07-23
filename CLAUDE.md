# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Siyanaty+ — a Flutter car maintenance and management app (package name `siyanaty_plus`). Offline-first: all data is written to a local SQLite database first, then synced to Firebase in the background when connectivity allows.

## Commands

```bash
flutter pub get                          # install dependencies (run after pulling or editing pubspec.yaml)
flutter run                              # run the app on a connected device/emulator
flutter analyze                          # static analysis (flutter_lints)

flutter test                             # all unit + widget tests
flutter test test/unit/                  # unit tests only
flutter test test/unit/car_service_test.dart   # a single test file
flutter test test/widget_test.dart       # widget tests
flutter test integration_test/           # integration tests (needs a device/emulator)

flutter build apk --release              # Android APK
flutter build appbundle --release        # Android App Bundle
flutter build ios --release              # iOS
```

Windows convenience script (runs pub get, unit tests, integration tests, writes logs to `test_logs/`):
```powershell
.\scripts\run_all_tests.ps1
```

Test suite is 67 tests total: unit tests cover auth/car/maintenance/reminder services (`test/unit/`), widget tests (`test/widget_test.dart`), integration tests cover full workflows (`test/integration_test/`).

## Architecture

Layered/clean architecture. Read multiple files together when working across a feature — the layers are intentionally separate and a single feature (e.g. "reminders") touches a model, an entity, a service, a database helper, a Firebase sync service, and a screen.

- **`lib/database/`** — local SQLite persistence. Not one monolithic helper: `database_helper.dart` (cars, maintenance, reminders, scans, obd_scans, expenses, trips, budgets), plus specialized helpers `mileage_database_helper.dart`, `ocr_database_helper.dart`, `voice_note_database_helper.dart`. Sensitive data goes through `services/security/secure_database.dart` (SQLCipher-encrypted).
- **`lib/domain/entities/`** — pure Dart business entities (no framework/serialization concerns): `app_user.dart`, `car.dart`, `maintenance_record.dart`.
- **`lib/models/`** — DTOs with JSON/DB (de)serialization, distinct from domain entities (e.g. `models/car.dart` vs `domain/entities/car.dart`). Includes backup-specific models (`backup_car.dart`, etc.) used only for Firebase backup/restore.
- **`lib/services/`** — business logic and integrations, grouped by concern:
  - `security/` — `authentication_manager.dart` (central auth/MFA/session orchestrator), `secure_storage_service.dart`, `secure_database.dart`, `local_unlock_service.dart` (PIN/biometric), `otp_service.dart`, `email_verification_service.dart`, `migration_service.dart`.
  - `obd/` — OBD-II protocol: `obd_service.dart`, `obd_models.dart`, `obd_parser.dart`.
  - `bluetooth/` — generic Bluetooth connectivity used by the OBD service.
  - Core business services at the top level: `car_service.dart`, `maintenance_service.dart`, `reminder_service.dart`, `mileage_service.dart` (+ `mileage_background_service.dart` via `workmanager`), `car_health_service.dart`, `expense_service.dart`, `voice_note_service.dart`, `license_service.dart`, `vin_decoder_service.dart`, `service_center_service.dart`, `connectivity_service.dart`, `global_navigation_service.dart`.
  - `ocr_service.dart` — on-device OCR via `google_ml_kit` (no network round-trip).
  - Firebase sync services mirror the local services one-to-one: `firebase_maintenance_service.dart`, `firebase_reminder_service.dart`, `firebase_obd_service.dart`, `firebase_backup_service.dart` (orchestrates full backup), `firebase_email_service.dart`.
  - `local_notification_service.dart` / `notification_database_service.dart` — local push notifications and their history.
- **`lib/shared/`** — cross-cutting: `constants/app_constants.dart`, `constants/app_theme.dart`, `services/` (Firebase init, auth wrapper, database access, location, notifications — used app-wide, distinct from the feature services in `lib/services/`), `utils/` (`app_logger.dart`, `responsive_utils.dart`, `custom_snackbar.dart`, `string_extensions.dart`).
- **`lib/presentation/`** — UI. `providers/` holds the two `ChangeNotifier`s wired at the app root (`auth_provider.dart`, `theme_provider.dart`) — state management is Provider only, no BLoC/Riverpod. `screens/` is organized by feature folder (`auth/`, `security/`, `services/`, `home/`, `profile/`, `settings/`, `obd/`, `health/`, `notifications/`, `actions/`, `info/`, `debug/`, `splash/`). `widgets/` holds cross-screen wrappers: `auth_wrapper.dart` (routes based on auth state), `bottom_nav_bar.dart`, `responsive_wrapper.dart`, `screen_with_nav_bar.dart`.

### App startup order (`lib/main.dart`)

Each step is wrapped in its own try/catch so a failure degrades gracefully rather than blocking launch: Firebase init (app still works offline-only if this fails) → local database init → local notification service init → schedule/check reminder notifications → mileage background service init/register → `runApp` with `MultiProvider` (`ThemeProvider`, `AuthProvider`).

### Authentication (see `docs/AUTHENTICATION.md` for full detail)

Multi-layer: Firebase Auth (email/password, Google Sign-In) → device-trust check → MFA via emailed OTP for unknown devices (OTPs stored in Firestore, 5-min expiry) → local PIN (SHA-256 + per-user salt, stored in `flutter_secure_storage`/Keystore/Keychain, 5 failed attempts locks out) or biometric (`local_auth`) for app unlock after 15 minutes idle. `AuthenticationManager` is the orchestrator; `AuthProvider` (in `presentation/providers/`) exposes auth state to the UI.

### Data flow

Offline-first: writes go to SQLite first, then sync to Firestore/Storage when online (`firebase_*_service.dart` files handle the sync side). Reads generally hit local SQLite directly; screens call services, which call database helpers, not the other way around. Health scores, statistics, and notification lists are computed on-demand from local queries rather than cached/stored.

## Coding style & conventions

Observed consistently across the codebase — match these when adding code:

- **Lints**: stock `flutter_lints` with no custom rules (`analysis_options.yaml` is unmodified); keep `flutter analyze` clean.
- **Services are singletons** via the `static final _instance` + `factory` constructor idiom (see `CarService` in `lib/services/car_service.dart`); there is no DI container. New services should follow the same pattern.
- **Errors are values, not exceptions**: service operations return result objects (`CarOperationResult.success(...)` / `.error(...)` with `isSuccess`/`message`/optional payload). Exceptions are caught inside the service and converted to error results; screens branch on the result rather than try/catch.
- **Logging** goes through `AppLogger` (`lib/shared/utils/app_logger.dart`) — `AppLogger.info/warning/error(...)`, never `print`.
- **Serialization is hand-written** — no `json_serializable`/`freezed`/codegen. Models expose `toMap()`/`fromMap()` for SQLite (snake_case column keys, `bool` stored as `0`/`1`, dates as ISO-8601 strings) and `toFirebaseMap()`/`fromFirebaseMap()` or `toJson()` for Firestore. Dart fields stay camelCase; the camelCase↔snake_case mapping lives only inside the model.
- **Models/entities are immutable**: all-`final` fields, named-parameter constructors with `required`, defaults applied in initializer lists (e.g. `createdAt = createdAt ?? DateTime.now()`), convenience getters for derived display values (`displayName`, `formattedMileage`). `fromMap` factories are defensive: `map['x'] ?? ''`, `?.toInt() ?? 0`.
- **Comments**: `///` doc comments on classes and public members in services/models; short `//` step comments marking phases inside longer methods ("// Validate input data", "// Check for duplicate VIN…").
- **Providers** are `ChangeNotifier`s with private `_field`s exposed through public getters and `notifyListeners()` after mutation; UI state fields include loading and error-message strings.
- **Theming**: all colors/gradients come from `AppTheme` static consts (`lib/shared/constants/app_theme.dart`, automotive-green palette, Orbitron display font). Don't hardcode `Color(...)` values in screens — add named constants to `AppTheme` instead.

## Key architectural decisions to preserve

- Multiple specialized SQLite helpers instead of one — keep new tables/queries in the helper matching their domain (or add a new specialized helper) rather than growing `database_helper.dart` further.
- `models/` (serialization) and `domain/entities/` (business concept) are kept separate on purpose — don't collapse a model into its entity or vice versa.
- Every local service that needs cloud backup has a matching `firebase_*_service.dart` — when adding a new local feature that should sync, follow this pairing rather than embedding Firestore calls in the local service.
- Firebase initialization failure must not crash the app — local storage is the fallback path; preserve the try/catch pattern in `main.dart` for any new startup step.

## Notes

- `PACKAGING_INSTRUCTIONS.md` and the integration test files reference real-looking test account credentials in plaintext — treat these as sensitive; don't propagate them into new docs or commits, and prefer moving them to environment variables if touching that code.
- Local documentation for individual features lives in `docs/` (`ARCHITECTURE.md`, `AUTHENTICATION.md`, `HOME_PROFILE_NOTIFICATIONS.md`); the root `README.md` links out to many more `docs/*.md` files that describe planned/expected documentation — not all of them exist yet, so check before assuming.