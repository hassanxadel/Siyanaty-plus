# Siyanaty+ — Pre-Release Issues Checklist

Goal: **zero-bug store release on 2026-04-08** (Google Play + Apple App Store).
How to use: tell Claude which item IDs to fix (e.g. "fix C1 and C2"). When an item is fixed and verified, its box gets checked `[x]`.

Audit date: 2026-07-20 · Source: `flutter analyze` (538 issues), manual platform-config review, code inspection.

---

## 🔴 CRITICAL — store rejection or guaranteed crash

- [ ] **C1 — iOS: all permission usage descriptions missing** (`ios/Runner/Info.plist`)
  The app uses camera (OCR), microphone (voice notes), location (service centers), Bluetooth (OBD-II), photo library (image picker), and Face ID (unlock) — but `Info.plist` declares **none** of the required `NS...UsageDescription` keys. iOS hard-crashes the app the moment each feature is used, and App Store review rejects the binary. Required keys: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`.

- [ ] **C2 — Android: application ID is still `com.example.siyanaty`** (`android/app/build.gradle`)
  Google Play refuses any `com.example.*` package. Must be renamed (e.g. `com.<yourbrand>.siyanaty`) **before** first upload — it can never be changed afterwards. Affects `applicationId`, `namespace`, `MainActivity` package path, and `google-services.json` registration.

- [ ] **C3 — Android: release builds signed with debug keys** (`android/app/build.gradle:40`)
  `signingConfig = signingConfigs.debug` — Play Console will not accept the bundle. Needs an upload keystore + `key.properties` + proper `signingConfigs.release`.

- [ ] **C4 — iOS: Google Maps API key never registered** (`ios/Runner/AppDelegate.swift`)
  `GoogleMap` is used in `lib/presentation/screens/services/services_screen.dart`, but `AppDelegate` never calls `GMSServices.provideAPIKey(...)` — opening the service-centers map on iPhone crashes.

- [ ] **C5 — Google Maps API key hardcoded & committed** (`android/app/src/main/AndroidManifest.xml:39`)
  The key is in the repo and extractable from the APK. Restrict it in Google Cloud Console (Android app restriction + API restriction), and inject it via a placeholder/`local.properties` instead of hardcoding.

- [ ] **C6 — 16 KB page-size compliance for Play** (`android/app/build.gradle`, plugin versions)
  Since Nov 2025 Google Play requires native libraries aligned for 16 KB pages for apps targeting Android 15+ (this app targets SDK 35). The pinned NDK 25 and old plugin versions (`sqflite_sqlcipher`, `camera`, `flutter_sound`, `google_ml_kit`…) predate that requirement. Must rebuild with a compliant NDK/AGP and updated plugins, then verify with Play's pre-launch report.

## 🟠 HIGH — crashes, broken features, security

- [ ] **H1 — 21 × `use_build_context_synchronously`** (analyzer, production code)
  `BuildContext` used after `await` without a proper `mounted` guard — crashes when the user navigates away mid-operation. Files: `cars_screen.dart` (9), `home_screen.dart` (3), `license_screen.dart` (2), `maintenance_screen.dart` (2), `voice_notes_screen.dart` (2), `email_verification_screen.dart`, `notifications_screen.dart`, `mileage_track_screen.dart` (1 each).

- [ ] **H2 — 5 developer test files ship inside `lib/`**
  `lib/test_backup_system.dart`, `lib/test_maintenance_firebase_backup.dart`, `lib/test_maintenance_reminder_connection.dart`, `lib/test_notification_system.dart`, `lib/test_reminder_system.dart` — compiled into the release app. `lib/presentation/widgets/notification_test_widget.dart` imports one of them. Move to `test/` or delete (and remove/guard the widget).

- [ ] **H3 — Firebase debug screen reachable in production** (`lib/presentation/screens/settings/settings_screen.dart:571`)
  `FirebaseDebugScreen` opens from Settings with no `kDebugMode` guard — visible to users and App Store reviewers.

- [ ] **H4 — 11 × deprecated APIs in use** (analyzer)
  `flutter_blue_plus`: `.name`→`.platformName`, `.id`→`.remoteId`, `.isAvailable`→`.isSupported` (`obd_screen.dart`, `obd_service.dart`); `textScaleFactor`→`textScaler` (`responsive_wrapper.dart:29`, `responsive_utils.dart:156,165`). These break on the next package/Flutter upgrade.

- [ ] **H5 — 312 × `print()` in production code** (analyzer, `lib/`)
  Leaks internal state (user data, sync details, OBD data) to device logs and slows release builds. Hotspots: `obd_service.dart` (34), `firebase_obd_service.dart` (25), `expense_service.dart` (21), `vin_decoder_service.dart` (19), `services_screen.dart` (19), `database_helper.dart` (13). Replace with `AppLogger` (project convention).

- [ ] **H6 — Plaintext test credentials in repo** (`PACKAGING_INSTRUCTIONS.md`, `test/integration_test/*`)
  Real-looking account credentials committed in plaintext. Remove from docs, rotate the accounts, move to environment variables / `--dart-define`.

- [ ] **H7 — Heavy synchronous startup work before first frame** (`lib/main.dart:32-79`)
  Firebase init → DB init → notification init → **reminder scheduling + due-reminder checks** → workmanager registration all block `runApp()`. This is why the splash lingers. Keep Firebase/DB, defer reminder scheduling and mileage-service registration to after the first frame.

## 🟡 MEDIUM — UX correctness & polish

- [x] **M1 — Native launch screen was white** (Android + iOS) — **FIXED 2026-07-20**
  First screen at app open is now the app's dark green `#062117` on all three native layers: Android 12+ system splash (`values-v31/styles.xml`, `values-night-v31/styles.xml` — new files), Android 5–11 drawable (`drawable-v21/launch_background.xml`, `drawable/launch_background.xml`), and iOS (`LaunchScreen.storyboard` background color). Verify on a real device: icon now sits on dark green, no white flash.
  **Follow-up (same day): splash logo enlarged.** Android 12+ now uses a custom full-bleed splash icon (`drawable/splash_icon.xml`, `windowSplashScreenAnimatedIcon`, tunable via its `android:inset`); Android 5–11 draws the logo at 220dp; iOS `LaunchImage` assets were **1×1-px placeholders** (no logo showed at all) — replaced with real 108/216/432px artwork rendered at 200×200pt. Re-verify on device.

- [ ] **M2 — Flutter splash text invisible in dark mode** (`lib/presentation/screens/splash/splash_screen.dart`)
  Text/icon colors use `AppTheme.getThemeAwareBackground(context)` — a **background** color. In dark mode that renders dark-green text (`#062117`) on the green gradient. Use a fixed light color (e.g. `Colors.white` / `AppTheme.lightBackground`).

- [ ] **M3 — Animated splash screen flow is broken by design** (`splash_screen.dart` + `auth_wrapper.dart:24`)
  `SplashScreen` only appears while `authProvider.isLoading` is true (usually never on cold start), and its 3-second `onFinish` timer fires a callback nothing listens to. Decide the intended flow: either show it for a minimum duration on every cold start, or remove the dead timer/callback.

- [ ] **M4 — Splash gradient palette doesn't match app theme** (`splash_screen.dart:109-111`)
  Splash uses `#1B4332/#2D5A47/#40916C` — a different green family than `AppTheme` (`#062117/#467D47/#739958`). Visible mismatch when transitioning from the (now dark-green) native splash. Align with `AppTheme` colors.

- [ ] **M5 — 7 unimplemented TODO features in production screens**
  Add-expense dialog (`car_health_dashboard_screen.dart:851`), license management options (`license_screen.dart:644`), car/reminder backup status hardcoded `false` (`comprehensive_backup_service.dart:290-293`), cloud OCR fallback (`ocr_review_screen.dart:592`), OCR share button (`ocr_review_screen.dart:721`). Each is a button/flow a user can reach — implement or hide before release.

- [ ] **M6 — Play policy review for declared permissions** (`AndroidManifest.xml`)
  `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` require a Play Console declaration; `WRITE_EXTERNAL_STORAGE` should get `android:maxSdkVersion="28"`, `READ_EXTERNAL_STORAGE` `maxSdkVersion="32"`; `BLUETOOTH_ADVERTISE` looks unnecessary for OBD (scan/connect only) — each extra permission adds review friction.

- [ ] **M7 — `android:allowBackup` not set** (`AndroidManifest.xml`)
  Defaults to `true`: Android auto-backup may copy the (SQLCipher-encrypted) DB and shared prefs to Google Drive with undefined restore behavior. Set explicitly (`false`, or configure backup rules).

- [ ] **M8 — Stale domain in network security config** (`android/app/src/main/res/xml/network_security_config.xml`)
  Pins `zpk.systems` — a domain that appears nowhere else in the project. Verify origin and remove if it's a leftover.

## 🟢 LOW — code hygiene (do after the above)

- [ ] **L1 — 28 × `unused_element` + 2 × `unused_field`** — dead code (e.g. `_scannedData` in `barcode_scanner_screen.dart:17`); delete.
- [ ] **L2 — 14 × `constant_identifier_names`** — constants not in `lowerCamelCase`; rename for lint cleanliness.
- [ ] **L3 — 8 × `prefer_initializing_formals`** — constructor style cleanup.
- [ ] **L4 — `versionName "1.0"` hardcoded in `build.gradle`** — use `flutter.versionCode`/`flutter.versionName` so pubspec `version:` drives store versions.
- [ ] **L5 — Analyzer `avoid_print` noise in `test/`** (~150 infos) — optional: allow `print` in tests via `analysis_options.yaml` override so real issues stay visible.

---

# 🔐 SECURITY AUDIT — 2026-07-21

Threat model: an attacker who can (a) sign up for a normal account, (b) read device logs, or (c) obtain the physical device. Findings ordered by exploitability. **S1/S2 are remotely exploitable by any person who installs the app and registers.**

- [x] **S1 — CRITICAL: Any authenticated user can read/write ANY user's profile** (`firestore.rules:11,16`) — **FIXED 2026-07-21**
  `match /users/{userId} { allow read, write: if request.auth != null; }` — the condition only checks that the requester is *signed in*, never that they are the *owner*. Same for `authorized_users`. **Attack:** attacker registers a normal account, gets any victim's UID, and reads their full profile (name, email, phone, emergency contacts) or overwrites it. **Worse — this is an MFA bypass:** the trusted-device list lives in this doc (`_isMfaRequiredForDevice` reads `users/{userId}`), so an attacker can append their own device ID to a victim's trusted devices and skip OTP entirely. Fixed by scoping to `request.auth.uid == userId`. **Requires deployment — see S-DEPLOY.**

- [x] **S2 — CRITICAL: Seven world-writable top-level collections** (`firestore.rules:50–92`) — **FIXED 2026-07-21**
  `cars`, `maintenance_records`, `reminders`, `fuel_logs`, `service_centers`, `app_settings`, `obd_data` were all `allow read, write: if request.auth != null` — any registered user could read or destroy every user's data. Verified by grep that **no app code references these top-level paths** (all real data lives in owner-scoped `users/{uid}/…` subcollections), so they were dead rules granting live access. Removed. **Requires deployment — see S-DEPLOY.**

- [x] **S3 — HIGH: OTP/MFA codes written to device logs in plaintext** — **FIXED 2026-07-21**
  `authentication_manager.dart` printed a banner containing `🔐 CODE: $code`, and `otp_service.dart` logged `OTP generated: $otp` plus `Sending OTP $otp to $email`. Device logs are readable via `adb logcat`, by crash/analytics SDKs, and on older Android by other apps — turning the second factor into no factor. All plaintext code logging removed; the remaining logs state only that a code was sent.

- [x] **S4 — HIGH: MFA code stored in plaintext in Firestore** (`authentication_manager.dart:273`) — **FIXED 2026-07-21**
  The doc stored `'code': code` *next to* `codeHash`, defeating the hash entirely. Verified the plaintext field was unnecessary: the email path passes the code directly to `_sendEmailWithCode(email, code)`. Field removed; only the hash is persisted.

- [x] **S5 — HIGH: No brute-force protection on OTP verification** — **FIXED 2026-07-21**
  A 6-digit code has 1,000,000 combinations and was valid for 5 minutes with **unlimited** verification attempts and no lockout — automated guessing was viable. Added a server-side-visible attempt counter on the `mfa_codes` document: each failed verification increments it, and at 5 failures the code document is deleted, forcing a new code to be requested.

- [x] **S9 — MEDIUM: PIN hash compared with a non-constant-time operator** — **FIXED 2026-07-21**
  `storedHash == inputHash` short-circuits on first differing character. Low practical risk for a local PIN, but it is exactly the pattern auditors flag; replaced with a fixed-time comparison that XORs all bytes.

- [ ] **S6 — MEDIUM: PIN uses fast single-round SHA-256** (`secure_storage_service.dart:323`)
  Salting is done correctly (32-byte per-user salt from `Random.secure()`), but SHA-256 is designed to be *fast*: an attacker who extracts the hash+salt from a rooted/jailbroken device brute-forces a 4-digit PIN (10,000 candidates) essentially instantly. Use a deliberately slow KDF — PBKDF2 with ≥100k iterations, or Argon2id. **Not auto-fixed: changing the KDF invalidates every existing stored PIN, so it needs a migration path (re-hash on next successful unlock) that must be tested on a device.**

- [ ] **S7 — MEDIUM: MFA/device-trust is enforced entirely client-side**
  Nothing server-side prevents a modified client from skipping the OTP screen — trust state is just a Firestore field the client writes. S1's fix removes the cross-user attack, but a determined attacker on *their own* account still controls it. Proper fix: move OTP issue/verify into Cloud Functions so the code never reaches the client and trust is server-granted. Architectural — schedule after launch.

- [ ] **S8 — MEDIUM: Two independent OTP implementations coexist**
  `OtpService` (in-memory `_currentOtp`, used by `otp_verification_screen.dart`) and `AuthenticationManager`'s Firestore-backed MFA (used by `mfa_verification_screen.dart`) are separate systems with different expiry, storage, and verification logic. `OtpService` also exposes `currentOtpForTesting` — a getter returning the live code, compiled into release builds. Consolidate on the Firestore implementation and delete the other.

- [ ] **S-DEPLOY — ACTION REQUIRED: deploy the hardened Firestore rules**
  `firestore.rules` has been rewritten in the repo, but **rules only take effect when deployed** — the vulnerable rules are live until you run `firebase deploy --only firestore:rules`. Review the new file first, then deploy and verify the app can still read/write your own data (cars, maintenance, reminders, backups). Rules changes are instant and reversible from the Firebase console.

# 🧭 FUNCTIONAL & FLOW FINDINGS — 2026-07-21

- [x] **F4 — Signup sent a "verify your email" link immediately and dumped the user on the login screen** — **FIXED 2026-07-21**
  Two defects in one flow. (a) `AuthService.createUserWithEmailAndPassword` called Firebase's `sendEmailVerification()` at account creation (two places: normal + PigeonUserDetails recovery path), so an email arrived long before the user reached any verification step — leftover from the removed email-verification feature; the success snackbar and result message still told users to "check your email to verify your account". (b) After signup the screen routed to `/`, which showed the **login screen**, forcing a brand-new user to re-enter credentials they had just typed — even though Firebase already signs the user in during account creation. Fixed by removing both `sendEmailVerification()` calls, correcting the messages, and routing signup **directly to the OTP screen** (Option 1). The OTP screen requests its code in `initState`, so the email is now sent exactly when the user is looking at the code fields. After OTP succeeds the device is trusted and `SecurityWrapper` continues to PIN setup.
  New flow: **Sign up → OTP (code sent on screen open) → Set Up PIN → app.**

- [x] **F5 — Login screen flashed for several seconds between OTP success and PIN setup** — **FIXED 2026-07-21**
  Diagnosed from the device log: `TimeoutException: Security initialization timed out after 10 seconds` at `main.dart:411`. `_initializeSecurity`'s catch block set `_needsLogin = true` **unconditionally**, so any slow startup rendered the sign-in screen at a user who was already authenticated. The log then showed the real initialization completing normally (`isAuthenticated: true` → `Device trusted status: true` → `showing PIN setup screen`) — because `Future.any` does not cancel the losing future, the initialization was still running the whole time; only the *fallback* was wrong. Fixed by checking `FirebaseAuth.instance.currentUser` on timeout: if a user is signed in, the loading screen stays up until the in-flight initialization finishes; the login fallback now only applies when there is genuinely no Firebase user. Timeout also raised 10s → 25s, since the device-trust check is a Firestore round-trip that is slow on emulators and weak connections.

- [ ] **F1 — Duplicate OTP emails when signing in on a new device**
  Both the login screen (`AuthResult.mfaRequired` → pushes MFA screen) and the new `SecurityWrapper` gate can trigger a code for the same sign-in, sending two emails seconds apart; only the newer code verifies, so the first one a user tries fails. Fix by making `SecurityWrapper` the single owner of the MFA gate and removing the login screen's push.

- [ ] **F2 — `email_verification_screen.dart` is now dead code**
  Unreachable since the email-verification step was removed. Delete the screen and its import/branch in `main.dart`, or the next reader will assume it is live.

- [ ] **F3 — `_justCompletedMFA` / `_onEmailVerificationComplete` are now vestigial** (`main.dart`)
  Left over from the removed email-verification step; they still set state that nothing consumes. Clean up with F2.

# 🎨 DESIGN CONSISTENCY FINDINGS — 2026-07-21

- [ ] **D1 — Glow treatment applied to only 3 of ~30 screens**
  Home, the two PIN screens, and the OTP screen now use the glow/pill design language; Cars, Maintenance, Reminders, Services, Settings, Profile, OBD, Health, and OCR screens still use the older flat cards and white-glass buttons. The app currently looks like two different products depending on the tab. Roll the same treatment (dark gradient + `secondaryGreen` rim glow + 20–24px radii + `lightBackground` Orbitron labels) across the remaining screens.

- [ ] **D2 — Legacy duplicate color constants in `AppTheme`**
  `accentGreen`/`lightGreen`/`darkForest`/`mintGreen`/`paleGreen`/`oliveAccent`/`darkGray` are aliases of the five real palette colors, kept "for smooth transition". New code can accidentally pick a legacy name and drift. Mark them `@Deprecated` and migrate call sites.

- [ ] **D3 — `_buildCircularActionButton`, `_buildCarIndicators`, `_buildLatestRepairs` and 6 navigation helpers are unused in `home_screen.dart`**
  Dead UI code (28 `unused_element` analyzer hits app-wide) that makes the largest screen harder to change safely. Delete with L1.

# 🙋 HASSAN'S ISSUES — 2026-07-22

Screen-by-screen UI/UX list raised by Hassan covering 12 screens. All items below were fixed on 2026-07-22.

**Shared groundwork.** Most "add the shadow effect" items had the same root cause: containers across the app used a single flat `BoxShadow(black @ 0.1, blur 10)` with no rim and no glow, so they read as flat panels next to the already-restyled Home/PIN/OTP screens. Rather than hand-editing each one, four reusable helpers were added to `AppTheme` (`lib/shared/constants/app_theme.dart`) and applied across the screens below — this is also a partial fix for **D1**:
- `glowShadow({accent, elevated})` — drop shadow + coloured glow
- `glowCardDecoration({radius, accent, elevated, gradient})` — dark green gradient panel with glowing rim
- `glowButtonDecoration({accent, filled, radius})` — pill button surface
- `glowFieldDecoration({accent, radius})` — input-field surface

Also added: `AppTheme.costHighlight` (amber `#FFC53D`) for monetary values, and two optional parameters on `AppDialog` (`cancelAccent`, `barrierDismissible`) so it could replace the remaining stock `AlertDialog`s.

- [x] **HA1 — Home screen: profile & notification buttons don't pop** (`home_screen.dart:420`) — **FIXED 2026-07-22**
  Root cause was not a missing shadow — `_buildCircularIcon` already had two shadows, but drew the icon itself at `.withOpacity(0.3)`, which is why the buttons looked washed out. Icon restored to full opacity, plus a `secondaryGreen` rim, a stronger drop shadow and a green glow. The unread badge also got a ring so it reads against the header.

- [x] **HA1b — Follow-up: circular buttons had a square shadow with sharp edges** — **FIXED 2026-07-22**
  Reported by Hassan after HA1: the glow around the two circular buttons rendered as a **hard-edged square halo** instead of a soft circular one. Cause is a Flutter subtlety: **`Ink` does not paint its own decoration — it paints into the parent `Material`'s ink layer, and that layer is clipped to the Material's bounds.** With a 46×46 button and `blurRadius: 20`, everything past the box edge was cut off, leaving a visible square.
  Fixed by inverting the widget order everywhere this pattern was used: the decoration (gradient + border + shadows) now lives on an **outer `Container`**, which paints unclipped, and `Material` sits *inside* it with `clipBehavior: Clip.antiAlias` handling only the ripple; padding moved from `Ink` to a `Padding` inside the `InkWell`.
  The same latent bug existed in **6 other buttons** added during this pass and was fixed in all of them (it was simply less obvious on rounded rectangles than on circles): notifications header actions, profile image-source sheet actions, settings Change PIN / Sign Out, voice-note form Cancel/Save, the cars "View All Reminders" pill, and the maintenance "View Details" pill. Negative `spreadRadius` values were also added so the glow sits tight to each shape rather than ballooning.
  **Rule for future work:** never put `boxShadow` on an `Ink`. Decoration + shadow go on a `Container`; `Material`/`InkWell` go inside it.

- [x] **HA2 — All Actions screen: title not centred** (`all_actions_screen.dart:96`) — **FIXED 2026-07-22**
  The title sat in a `Row` after the back button, so its `textAlign: TextAlign.center` did nothing (a `Text` only sizes to its own content). Wrapped in `Expanded` with a trailing `SizedBox(width: 48)` mirroring the leading `IconButton`, so it is now optically centred on the screen. Same fix pattern applied to HA9 and HA4.1.

- [x] **HA3 — Cars screen: service reminder pop-up card** (`cars_screen.dart:792`) — **FIXED 2026-07-22**
  Rebuilt in the app's "backlit HUD" language: darker green (`backgroundGreen → darkAccentGreen`, replacing the lighter one-off `#1A362A/#2E4032`), `secondaryGreen` rim, layered drop shadow + glow, hairline divider under the header, glowing icon chip, styled close button, and a proper empty state. The "View All Reminders" button became a green-accent pill with a glow; each reminder row now has a status-tinted rim and its own shadow.

- [x] **HA4 — Voice Notes screen (5 sub-issues)** (`voice_notes_screen.dart`) — **FIXED 2026-07-22**
  1. Page title "Voice Notes" centred (same `Expanded` fix as HA2).
  2. Shadows added to all 5 containers and to the record / save / discard buttons via `AppTheme.glowShadow()`; the record button also gained a rim that turns red while recording.
  3. "Recording Stopped" pop-up replaced with `AppDialog` — same modern card as the confirm-sign-out dialog. "Discard" is tinted destructive-red, "Save" is the filled green action. Needed two new `AppDialog` parameters (`cancelAccent`, `barrierDismissible: false`) since the recording must not be dismissable by tapping outside.
  4. Edit/Delete popup menu restyled: dark panel, green rim, rounded 18px, coloured icons and Orbitron labels; the trigger dots became a raised chip.
  5. Save/Edit voice-note form rebuilt as a single shared `_showVoiceNoteForm` helper (previously two near-identical 100-line `AlertDialog`s): icon chip, title + subtitle, labelled fields with shadows and prefix icons, and a **centred** pair of equal-width pill buttons.

- [x] **HA5 — Maintenance screen (3 sub-issues)** (`maintenance_screen.dart`) — **FIXED 2026-07-22**
  1. Add + edit maintenance forms now match the cars form: every text field is wrapped in a shadowed `DecoratedBox`, and both save buttons got a `secondaryGreen` rim, glow shadow, 20px radius and taller tap target.
  2. "View Details" button rebuilt to match the Home screen's "View All" pill — dark vertical gradient, green rim, glow + drop shadow, and a trailing chevron.
  3. Maintenance cost in the outer card is now amber (`AppTheme.costHighlight`) instead of green, with a matching tinted rim and glow, so money reads differently from the green used for status/health.

- [x] **HA6 — OBD screen (2 sub-issues)** (`services/obd_screen.dart`) — **FIXED 2026-07-22**
  1. The Bluetooth-enable pop-up was a completely unstyled stock `AlertDialog` (default white, no theming at all); replaced with `AppDialog`, giving it the app's card design plus properly styled Cancel/Enable pill buttons with shadows.
  2. Shadows and brighter rims added to the connection-status, metric and info containers; the Scan/Connect button got a glow that turns red when connected.
  *Note:* fixes were applied to `lib/presentation/screens/services/obd_screen.dart` — the file actually reachable from Home and All Actions. `lib/presentation/screens/obd/obd_screen.dart` is a second, unreferenced copy and is a candidate for deletion (see L1).

- [x] **HA7 — Reminders screen: add/edit form** (`reminders_screen.dart`) — **FIXED 2026-07-22**
  Both the add and edit forms now match the cars form: all text fields wrapped in shadowed `DecoratedBox`es, and the Save/Update buttons given a `secondaryGreen` rim, glow shadow and 20px radius.

- [x] **HA8 — Licenses screen: containers & buttons** (`license_screen.dart`) — **FIXED 2026-07-22**
  Car selector, license cards and info panels switched to `AppTheme.glowShadow()` with brighter rims; "Add/Update Image" and "View" buttons got glows, rims and 20px radii.

- [x] **HA9 — Notifications screen (2 sub-issues)** (`notifications_screen.dart`) — **FIXED 2026-07-22**
  1. Page title "Notifications" centred (same fix as HA2).
  2. "Mark all as read" and "Clear all" became raised chips with rims and shadows instead of bare icons. Notification cards now use `glowCardDecoration`, with **unread** cards rendered `elevated` and rimmed in their priority colour so the read/unread split is visible at a glance; the leading type icon got a tinted rim and glow.

- [x] **HA10 — Profile screen (2 sub-issues)** (`profile_screen.dart`) — **FIXED 2026-07-22**
  1. All four cards switched to `glowCardDecoration`; editable fields gained shadows (on a wrapper, since `TextField` paints its own fill); Edit/Save buttons became glowing pills.
  2. **New feature — profile picture.** Added `lib/services/profile_image_service.dart` (singleton, result objects, `AppLogger` — matching project conventions) and `lib/presentation/widgets/profile_avatar.dart`. The image is picked via camera or gallery, downscaled to 600px @ 85% quality, copied into the app's private documents directory, and its path stored in `SharedPreferences` **keyed by Firebase UID** so two accounts on one device never see each other's picture. Nothing is uploaded, so it works offline like the rest of the app. A tap on the avatar opens a bottom sheet with Take photo / Choose from gallery / Remove. Falls back to the user's initials when no picture is set, and to initials again if the file has gone missing.
  The avatar also appears in the **Home screen greeting card, to the left of the name**, at 48px so it stays a small accent. The service exposes a `ValueListenable`, so changing the photo on the profile screen updates the home greeting immediately without either screen knowing about the other.

- [x] **HA11 — Settings screen (2 sub-issues)** (`settings_screen.dart`) — **FIXED 2026-07-22**
  1. All section containers switched to `glowCardDecoration`; "Change PIN" and "Sign Out" rebuilt as glowing pills (Sign Out tinted red).
  2. **Sign-out did not redirect — fixed.** `_signOut` awaited `authProvider.signOut()` and then only showed a snackbar; it never navigated. Because Settings is *pushed on top of* the auth wrapper (`main.dart` has no named routes — `home:` is `SecurityWrapper > AuthWrapper`), signing out rebuilt the wrapper underneath while the pushed route stayed on screen — hence "logged out but still on Settings". Now, after a confirmed sign-out, `navigator.popUntil((route) => route.isFirst)` unwinds to the wrapper, which has no user and renders the sign-in screen. The confirmation also moved from a stock `AlertDialog` to `AppDialog`, and the provider/navigator are captured **before** the `await` so no `BuildContext` crosses an async gap.

- [x] **HA12 — Cloud backup screen: containers & buttons** (`detailed_backup_screen.dart`) — **FIXED 2026-07-22**
  Backup cards and the summary panel switched to `AppTheme.glowShadow()` with rims (the summary panel's near-invisible 10%/5% green wash was replaced with the standard dark green gradient); Backup/Restore buttons got rims, glows and 20px radii, with the Restore button keeping its blue accent.

- [x] **HA13 — App-wide: unify every pop-up card to the new design** — **FIXED 2026-07-22**
  Requested after seeing the new Edit Voice Note card: make **every** pop-up in the app look exactly like it. A deep sweep found **61 pop-up sites across 25 files** — a mix of stock white `AlertDialog`s, hand-rolled `Dialog`s with three different green gradients, and bottom sheets.
  Rather than restyle 61 dialogs by hand, `lib/presentation/widgets/app_dialog.dart` was expanded into a small kit that *is* the design, with three entry points covering every case found:
  - `AppDialog.show(...)` — two-action confirmation (returns `true`/`false`/`null`)
  - `AppDialog.message(...)` — single-action notice, with `isError` (red) / `isWarning` (amber) variants
  - `AppDialog.custom(...)` — the same shell around arbitrary content (forms, lists, progress, CSV dumps)
  plus three exported building blocks: `AppDialogPanel` (the card itself — gradient, glowing rim, icon chip, title, message, scrollable content, centred pill actions), `AppDialogAction` (pill button) and `AppDialogField` (matching input).
  **Converted — every one now renders the identical card:** voice notes (form, delete, export, error), maintenance (delete, details card), cars (delete car, car details card), reminders (delete, details card, car/priority sheets), mileage (automated-tracking info, delete entry, CSV export, error, entry details card), OBD (device picker, no-devices, delete scan in both OBD files), OCR history / review / scanner (delete + error + info), VIN lookup (vehicle info, already-exists, saved), services (remove from favourites), help (getting started, reset account), licenses (permissions required), settings (verify email), unlock (account locked), MFA (sign out), Firebase debug (delete user), connectivity (no internet), home (PIN prompt, car details), and both backup widgets (backup confirm, restore confirm, 2× partial-result).
  **Duplication removed along the way:** the voice-note form, the MFA sign-out dialog and the two backup partial-result dialogs were each hand-built copies of this design; all four now call the shared kit. `flutter analyze` issue count **dropped 548 → 545** as a result.
  **Verified:** `grep "AlertDialog("` over `lib/` returns **zero matches** — there is no longer a single stock Material dialog in the app.
  **Rule for future work:** never use `AlertDialog` or a bare `Dialog`. Use `AppDialog.show` / `.message` / `.custom`, or compose `AppDialogPanel` directly.

## Round 2 — 2026-07-22

- [x] **HA14 — Reminders screen: "Mark as Completed" / "Completed" button on the reminder card** — **FIXED 2026-07-22**
  The primary action on each card was a stock `ElevatedButton` with flat `primaryGreen` fill and no shadow — it read as a default Material button dropped into a themed card. Rebuilt as a glowing pill (`AppTheme.glowButtonDecoration`) with a check icon, `secondaryGreen` label and Orbitron type. The **"Completed"** state was a nearly invisible `Colors.green @ 0.1` chip; it now uses the same pill shape and rim with a filled check icon, so completed and actionable cards read as the same component in two states.

- [x] **HA15 — Notifications screen: read/delete buttons in the card's three-dot menu** — **FIXED 2026-07-22**
  The per-notification menu was a stock white Material popup whose item colours depended on `Theme.of(context).brightness` and fell back to `null` (default black) in dark mode. Restyled to match the voice-notes menu: dark `backgroundGreen` panel, `secondaryGreen` rim, 18px radius, elevation 14, with `secondaryGreen` "Mark as read" and red "Delete" entries in Orbitron. The trailing dots became a raised chip with a rim and shadow, matching the voice-note cards.

- [x] **HA16 — Cars screen: car details pop-up now matches the Service Reminders card** — **FIXED 2026-07-22**
  Restructured `CarDetailsDialog` to the same anatomy as the Service Reminders card from HA3: glowing thumbnail chip (car photo, or the car glyph, in a `secondaryGreen`-rimmed rounded chip), title + subtitle stack (`Brand Model` over `Year · Colour`), raised close button, and a **hairline gradient divider** under the header. The details panel picked up the same `backgroundGreen @ 0.55` fill, green rim and drop shadow; its rows moved to the `lightBackground` palette with Orbitron. The Edit/Delete buttons — previously solid blue and solid red blocks — became the same pill as "View All Reminders", in `secondaryGreen` and destructive red.

- [x] **HA17 — Settings screen: remove test notification button + show profile image** — **FIXED 2026-07-22**
  1. Removed the "Send Test Notification" button, its `_sendTestNotification()` handler, and the "Enable notifications to send a test" hint. Also deleted the now-orphaned `LocalNotificationService.sendTestNotification()` (30 lines) and the file's now-unused import — leaving the method behind would have been exactly the dead code L1 tracks. **Note:** this removes the only in-app way to fire a test notification; if you want that back for QA, it should return behind a `kDebugMode` guard rather than in the shipping UI.
  2. The Profile & Account section showed a hardcoded person icon. It now uses the shared `ProfileAvatar`, so the user's photo appears here too — and because the widget listens to `ProfileImageService`, changing the picture on the Profile screen updates the Settings section and the Home greeting card at the same time. Tapping it opens the profile editor.

- [x] **HA18 — Cloud backup screen: centre the "Detailed Backup Management" title** — **FIXED 2026-07-22**
  The title was `Expanded` but explicitly `textAlign: TextAlign.left` with no trailing spacer, so it sat hard against the back button. Now centred with a `SizedBox(width: 48)` mirroring the `IconButton` (same fix as HA2/HA9), and reduced 26→20px so the long title fits on one line on narrow phones. The subtitle underneath had `textAlign: TextAlign.center` that did nothing — the parent `Column` uses `crossAxisAlignment.start`, so the `Padding` was hugging its text; wrapped it in a full-width `SizedBox` so the centring actually applies.

- [x] **HA19 — VIN Lookup screen: centre the "VIN Lookup" page title** — **FIXED 2026-07-22**
  Same cause as HA2/HA9/HA18: the title sat in a `Row` after the back button with `textAlign: TextAlign.center` set, which does nothing because a `Text` only sizes to its own content. Wrapped in `Expanded` with a trailing `SizedBox(width: 48)` mirroring the leading `IconButton`, plus the same soft text shadow the other headers use.

- [x] **HA20 — Reminders screen: View Details pop-up now matches the car details card** — **FIXED 2026-07-22**
  Rebuilt `ReminderDetailsDialog` to the HA16 anatomy: glowing 52px icon chip (`secondaryGreen` tint + rim + glow) holding the reminder-type glyph, title over a `Type · Priority` subtitle, raised close button, hairline gradient divider, and the `backgroundGreen @ 0.55` details panel with a green rim and drop shadow. Detail rows moved to the `lightBackground` palette in Orbitron with rimmed icon chips.
  All five action buttons were solid colour blocks; they now use the **faded pill** treatment (`AppTheme.glowButtonDecoration`) — tinted fill, glowing rim, accent-coloured label — exactly like Delete on the car details card. Colours moved off one-off hex values onto the palette: Complete → `secondaryGreen`, Revert → `AppDialog.warning`, Edit → new `AppTheme.infoBlue`, Delete → `AppDialog.destructive`, Close → neutral `lightBackground`.

- [x] **HA21 — Maintenance screen: View Details pop-up now matches the car details card** — **FIXED 2026-07-22**
  Same treatment as HA20 applied to `MaintenanceDetailsDialog`: glowing icon chip, title over a `Type · Date` subtitle, raised close button, hairline divider, rimmed details panel, and palette-aligned detail rows. Edit/Delete became faded pills (`infoBlue` / `destructive`). The **Cost** row also switched from `primaryGreen` to `AppTheme.costHighlight`, so it matches the amber cost chip on the maintenance list card from HA5.3.

- [x] **HA22 — Settings screen: Cloud Backup card redesigned as the screen's hero feature** — **FIXED 2026-07-22**
  The card was visually the *weakest* element on the screen despite being its main feature — 12px radius and a single flat `darkAccentGreen @ 0.3` shadow, while the sections around it had already moved to `glowCardDecoration`. It now uses `glowCardDecoration(radius: 20, elevated: true)`, deliberately a larger radius and stronger glow than the surrounding sections (radius 16, unelevated) so it reads as the primary card rather than one of a stack.
  Restructured to the pop-up card anatomy: glowing `cloud_sync` icon chip, "Cloud Backup" title over a "Cars, reminders & maintenance" subtitle, a "View All" pill, and a hairline divider. Backup All / Restore All were solid green and solid blue blocks; both are now faded pills (`secondaryGreen` / `infoBlue`) via a shared `_buildCardAction`, which also renders a dimmed inert state while a backup runs and shows the spinner in the accent colour. The signed-out notice became an amber rimmed panel with an icon and a glow, and the status rows now use the palette with green-tinted values.

**New palette constant:** `AppTheme.infoBlue` (`#64B5F6`) for neutral/informational actions (Edit, Restore) — light enough to stay legible as a tinted pill on the dark green panels, replacing the several one-off `Color(0xFF2196F3)` / `Colors.blue.shade600` values.

## Round 4 — 2026-07-22 (IN PROGRESS)

Large batch covering backup, car health, service centres, all About & Support pages, account deletion and mileage. **Sequenced over several passes** — only the items checked below are done.

**Decisions taken (confirmed by Hassan):** support email is **siyanatyplus@gmail.com** (the list said `gmal.com`, which is not a real domain); the Contact Us form will **store messages in Firestore only**, with no email delivery.

- [x] **HA23 — Detailed Backup: per-card backup/restore scope — VERIFIED ALREADY CORRECT, no change needed** — **2026-07-22**
  Hassan asked to make sure each card's button only handles its own data. **It already does.** Every per-card handler in `detailed_backup_screen.dart` calls its own scoped service: Cars → `FirebaseBackupService.backupAllCarsToFirebase()` / `restoreCarsFromFirebase()`; Reminders → `FirebaseReminderService.backupAllRemindersToFirebase()` / `restoreRemindersFromFirebase()`; Maintenance → `FirebaseMaintenanceService.backupMaintenanceToFirestore()` / `restoreMaintenanceFromFirestore()`; Mileage → `MileageService.syncToFirebase()` / `syncFromFirebase()`; Licenses → `LicenseService.backupLicenseImagesToFirebase()` / `restoreLicenseImagesFromFirebase()`; OCR → `OcrService.backupScansToFirebase()` / `restoreScansFromFirebase()`. Only **Backup All / Restore All** call `ComprehensiveBackupService.backupAllDataToFirebase()`.
  **Correction on the record:** this was initially reported to Hassan as a confirmed bug. That was wrong — it was inferred from `ComprehensiveBackupService` exposing only all-or-nothing methods, without checking the call sites. No defect existed and no behaviour was changed.

- [x] **HA24 — New `CloudDataService`: per-category cloud delete** (`lib/services/cloud_data_service.dart`) — **2026-07-22**
  The app had **no way to delete cloud data at all**. Added a singleton service (project conventions: result objects, `AppLogger`, no throwing) with a `CloudDataCategory` enum mapping each data type to its Firestore sub-collection under `users/{uid}` — `cars`, `reminders`, `maintenance`, `mileage_entries`, `license_images`, `obd_scans`, `scans`, `expenses`.
  Exposes `backupCategory`, `restoreCategory`, `countInCloud`, `deleteCategoryFromCloud` and `deleteAllCloudData`. Deletion **only removes the cloud copy — local records are deliberately untouched.** `_deleteCollection` pages in batches of 400 because Firestore caps a write batch at 500 ops, so a large collection can't silently fail to fully delete. `deleteAllCloudData` isolates per-collection failures so one bad collection can't abort the rest, and reports which ones failed.

- [x] **HA25 — Settings: "Delete All Cloud Data" action** — **2026-07-22**
  New "Cloud Data" section in Settings with a red destructive pill. Uses `AppDialog` with `barrierDismissible: false` and explicit copy stating cloud data is removed while **device data is kept**, since this is irreversible. The button dims and shows "Deleting..." while the wipe runs; `_buildSettingsActionButton` now accepts a nullable callback to support that inert state.

- [x] **HA37 — Mileage entry pop-up + Detailed Backup buttons brought onto the shared design** — **FIXED 2026-07-22**
  `MileageEntryDetailsDialog` was the last detail card still on the old look. Rebuilt to the HA16/HA20/HA21 anatomy: glowing 52px `speed` icon chip, title over a `Mileage Entry · date` subtitle (replacing the boxed green chip), raised close button, hairline gradient divider, and the rimmed `backgroundGreen @ 0.55` details panel. Detail rows moved to the `lightBackground` palette in Orbitron with rimmed icon chips; **Cost** switched to `AppTheme.costHighlight` (amber) and **Date** to `AppTheme.infoBlue`, matching the other cards.
  Its Edit / Delete / Close buttons were solid blue, solid red and solid grey blocks — all three are now faded pills via `AppTheme.glowButtonDecoration` (`infoBlue` / `destructive` / neutral `lightBackground`).
  **Detailed Backup Management**: all four buttons (per-card Backup/Restore and the comprehensive Backup All/Restore All) were solid green and solid blue gradient blocks. Replaced with a single shared `_buildFadedAction` helper — tinted fill, glowing rim, accent-coloured label — which also renders a dimmed inert state while an operation is in flight, so the four buttons can no longer drift apart.

## Round 5 — 2026-07-22

- [x] **HA38 — Detailed Backup: loading effect showed on ALL buttons; make Backup yellow** — **FIXED 2026-07-22**
  1. Root cause: a single `bool _isLoading` was passed to all 7 data cards *and* the comprehensive card, so clicking any button dimmed/disabled every button on the screen. Added a `String? _loadingKey` that identifies the exact button running (`'cars.backup'`, `'all.restore'`, …) via a new `_runOp(key, action)` wrapper. Each button now shows the busy spinner+dim **only when its own key is active**; while an op runs the others are disabled but keep their normal appearance. The 16 existing handlers were left untouched (safest on a data screen) — the wrapper layers on top and the old `_isLoading` is still read as a concurrency guard, so no dead-field warning.
  2. The **Backup** buttons (per-card and "Backup All") are now amber — icon + text `AppTheme.costHighlight` — so backup stands out from the blue Restore. `_buildFadedAction` gained a `busy` flag that shows a spinner in the accent colour.

- [x] **HA39 — Car Health: removed the Quick Actions section** — **FIXED 2026-07-22**
  The "Quick Actions" block held two placeholder buttons ("Add Expense" and "View Reports") that both only fired a "coming soon" snackbar. Removed the section and its now-dead helpers (`_buildQuickActions`, `_buildActionButton`, `_showAddExpenseDialog`, `_showComingSoon`) plus the now-unused `custom_snackbar` import — leaving them would be exactly the dead code L1 tracks.

- [x] **HA40 — Service Centers: nav bar, map popup, list buttons restyled** — **FIXED 2026-07-22**
  - **Nav bar** (Maps / Favorites / Centers): rebuilt the `TabBar` as a glowing segmented control — dark green gradient track with a `secondaryGreen` rim and glow, the selected tab a glowing green pill, larger icons and Orbitron labels.
  - **Marker-tap popup card** (item 3.2): its Favorites / Navigate / Call buttons were solid green/red/blue blocks; all three are now faded pills via a shared `_centerActionPill` (tinted fill, glowing rim, accent label, 20px rounded edges — satisfying "make the Navigate edges more rounded"). Favorites turns red when active, Navigate is blue.
  - **Favorites view** and **Centers list view**: Navigate/Call buttons converted to the same faded pill; the card containers upgraded from the flat `black @ 0.1` shadow to `AppTheme.glowShadow()` with a `secondaryGreen` rim.
  - **"Find Nearby Centers"** button converted to a faded green pill.
  - *Note:* `_buildServiceCenterCard` (a legacy mock card fed by hardcoded `_getServiceCenters()`) has **no caller** — left untouched as dead code rather than restyled; it's a deletion candidate.

- [x] **HA41 — Service Centers: detail popup now opens as a centered card, not a bottom sheet** — **FIXED 2026-07-22**
  `_showServiceCenterBottomSheet` (reached from both the map marker tap and the Favorites/Centers cards) was a `showModalBottomSheet` — a white-topped panel sliding up from the bottom with a grey grab handle. Converted it to a centered `showDialog` using the shared panel styling (dark green gradient, `secondaryGreen` rim, elevated glow, 24px radius, `maxWidth: 420`, scrollable content). The header wrench became a glowing icon chip and the close X a raised button, matching the other detail cards. The Favorites / Navigate / Call faded pills from HA40 are unchanged. One method fixes both entry points.

- [x] **HA42 — In-app navigation (Home button / back) sometimes jumped to the PIN screen — FIXED** — **2026-07-22**
  **Root cause** in `main.dart` `_SecurityWrapperState.didChangeAppLifecycleState`: the `AppLifecycleState.paused` branch set `_needsLocalUnlock = true` **unconditionally** whenever authenticated, and `_checkUnlockRequirement` on resume only ever *set* the flag, never cleared it. On modern Android many things fire a `paused`/`inactive` blip that is not a real backgrounding — the **predictive-back gesture**, permission dialogs, the soft keyboard, and launching system UI the app uses heavily (image picker, `url_launcher` to Maps, the phone dialer). Any such blip flipped the entire app (SecurityWrapper is the root) to `UnlockScreen`, so pressing back to go Home — or tapping the Home nav item right after one of these — landed on the PIN screen. Compounded by the lock window being tied to `lastUnlockTime`, which is only refreshed on unlock.
  **Fix:** the `paused` handler no longer locks — it just records `_backgroundedAt = DateTime.now()`. The lock decision moved entirely to resume (`_checkUnlockRequirement`): it ignores a resume with no recorded pause, ignores transient blips shorter than `_minBackgroundBeforeLock` (2s) — which covers the back gesture / permission dialogs — and only then consults `shouldLockApp()` (the existing 5-minute idle gate). Net effect: pure in-app navigation and quick returns never lock; a genuine background absence past the idle timeout still does. Verified: `flutter analyze` 0 errors, 54/54 tests pass. **Not yet verified on a device** — worth confirming the back gesture and a real >5-min background both behave.

- [x] **HA43 — Mileage auto-update: correctness rewrite (daily/weekly/monthly never double-count or miss)** — **FIXED 2026-07-22**
  **Audit result — the original `MileageBackgroundService.updateAllCarMileage` was broken three ways, all from one root cause: nothing recorded when each recurring entry last contributed mileage.**
  - *Daily*: blindly added one day's mileage per task run (the code comment literally said "we need to check if we've already counted today" but didn't). WorkManager's 24h period isn't exact — a double run (reboot/OS retry) **double-counted**, and since `updateCarMileage` *adds* to the odometer that inflation is permanent; a phone off for 2 days added only one day → **missed**.
  - *Weekly*: only credited if the task happened to run on the exact `weekday` of creation — WorkManager drift makes that unlikely, so weeks were silently **skipped**.
  - *Monthly*: required the run to land on the exact day-of-month (day-31 entries never fire in short months) and de-duped on `entry.updatedAt.month`, a field this flow never updates.
  **Fix — period-based catch-up with a persisted anchor:**
  - New `last_applied_at` column on `mileage_entries` (DB **v15 → v16** migration; existing recurring rows anchored at upgrade time so there's no retroactive surge). Added to the `MileageEntry` model (map/Firestore/copyWith) and a lightweight `MileageDatabaseHelper.markApplied`.
  - Each run now credits `(whole elapsed periods since the anchor) × mileage` and advances the anchor by exactly that many periods (not to `now`, so the partial-period remainder carries forward without drift). This is **idempotent** (a second run the same day credits 0) and **catch-up safe** (phone off 3 days → 3 days credited on the next run). Month math clamps day-of-month (Jan 31 + 1 month → Feb 28) and counts completed anniversaries.
  Verified: `flutter analyze` 0 errors, 54/54 tests pass; month/day edge cases traced by hand. **Not yet verified on a device** — worth confirming a real multi-day catch-up.
  **Still outstanding (HA36 remainder):** the *10-day calibration prompt* (ask the user whether the computed mileage is right and adjust the per-entry rate up/down) — a separate feature needing UI + a stored calibration factor; not started.

- [x] **HA44 — Help & Support screen (item 1 a–e)** — **FIXED 2026-07-22**
  a) The three section cards (Quick Actions, FAQ, Still Need Help) moved from the flat `black @ 0.1` shadow to `AppTheme.glowShadow()` with a `secondaryGreen` rim.
  b) The **Email** button now opens the phone's mail app via a `mailto:` URI pre-filled to **siyanatyplus@gmail.com** with a subject line; a snackbar fallback shows the address if no mail app is installed. New shared constant `AppConstants.supportEmail` (the issue's "gmal.com" is a typo — confirmed with Hassan as gmail.com).
  c) **Chat** button removed (no chat backend existed — its handler was an empty `// Open chat` stub).
  d) **Export Data** now shows an `AppDialog` explaining what export does and asking to confirm/cancel (like Reset Account Data) before proceeding.
  e) "Help & Support" title centred (`Expanded` + trailing spacer, same fix as the other headers).

- [x] **HA45 — Help & Support: Export Data now produces a real, shareable file** — **FIXED 2026-07-22**
  New `DataExportService` (`lib/services/data_export_service.dart`) dumps every user table in the local SQLite DB generically (via `sqlite_master`, so new tables are captured automatically) into an indented JSON file in temp storage, with a BLOB-safe encoder. The Help screen's Export action, after the confirm dialog, builds the file and hands it to the OS share sheet via `share_plus` — from there the user saves it to Files/Drive or sends it through any app. Error path shows a snackbar.

- [x] **HA30 — About Siyanaty+: restyled, real content, centred title** — **FIXED 2026-07-22**
  Title centred; app name corrected to **Siyanaty+**. Section cards moved to `AppTheme.glowShadow()` + `secondaryGreen` rim. Rewrote the placeholder copy into a real About page — Mission, "What You Can Do", a "Your Data, Your Control" privacy section, Get in Touch, and Legal — replacing the fake `support@siyanaplus.com` / `www.siyanaplus.com` with `AppConstants.supportEmail` (siyanatyplus@gmail.com) and updating © 2024 → 2026.

### Still outstanding from earlier batch (not yet started)
- [ ] **HA31** — Privacy Policy: restyle, real policy content, centre title
- [ ] **HA32** — Terms of Service: restyle, real terms content, centre title
- [ ] **HA33** — New Contact Us screen (form → Firestore) reached from the "Contact Support" button
- [ ] **HA34** — Rate our App: correct per-platform store behaviour (needs `url_launcher` store links or the `in_app_review` package — not in pubspec)
- [ ] **HA35** — Account deletion: new screen wiping cloud + local data + Firebase Auth credentials, with a confirmation the user is erasing everything (irreversible — build and test on a throwaway account)
- [ ] **HA36 (remainder)** — Mileage 10-day calibration prompt (the correctness rewrite is done — HA43)

> Reconciliation of the earlier (round-4) outstanding list: **HA26** superseded by HA37/HA38 (Detailed Backup restyle + per-button loading); **HA28** superseded by HA40/HA41 (Service Centers restyle + centered popup); **HA29** done as **HA44**; **HA36** correctness done as **HA43** (only the calibration prompt remains, listed above). Still genuinely open: **HA27** (car-health algorithm) and **HA30–HA35** above.

**Verification:** `flutter analyze` reports **0 errors and 0 new warnings** across the project after these changes (the 2 remaining warnings are the pre-existing L1/H2 items). Full unit + widget suite re-run — see T1.
**Not yet verified on a device** — these are visual changes; a manual pass on a phone is still worth doing, especially the profile-picture camera/gallery flow, which needs the C1 iOS permission strings before it will work on iPhone.

## 🧪 TESTING — status & required runs

- [x] **T1 — Unit + widget test suite: PASSED** — re-verified 2026-07-22 after the Hassan's Issues UI work: `flutter test test/unit/ test/widget_test.dart` → **54/54 passed** (4s), and `flutter analyze` reports 0 errors. Previously verified 2026-07-20 via full `flutter test` (67/67, 2m50s). Note: `test/integration_test/` ran on host with `MissingPluginException` warnings (shared_preferences) — harmless here, but the real integration run on a device (T3) is still required.
- [ ] **T2 — Dependencies significantly outdated** (`flutter pub outdated`, 2026-07-20)
  Firebase stack is **two majors behind**: `firebase_core` 2.32→4.x, `firebase_auth` 4.16→6.x, `cloud_firestore` 4.17→6.x, `firebase_storage` 11→13. Also behind: `flutter_blue_plus` 1.36→2.3 (fixes the H4 deprecations), `flutter_local_notifications` 17→22, `camera` 0.10→0.12, `google_ml_kit` 0.18→0.22, `geolocator` 12→14, `share_plus` 7→13, `local_auth` 2→3, `flutter_secure_storage` 9→10, `permission_handler` 11→12. Plan a staged upgrade (Firebase first, then plugins), re-running the full test suite after each stage — this is also a prerequisite for C6 (16 KB alignment).
- [ ] **T3 — Integration tests on a real Android phone** (`flutter test integration_test/`) — required before release.
- [ ] **T4 — Full manual pass on a real iPhone** — currently the app has never been verified on iOS (C1/C4 make it certain it crashes there today).
- [ ] **T5 — Release-mode smoke test** (`flutter build apk --release`, install, cold start offline + online) — verifies ProGuard/shrinker (`minifyEnabled true`) doesn't strip Firebase/SQLCipher classes.
