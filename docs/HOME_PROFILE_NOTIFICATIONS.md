# Home, Profile & Notifications Screens

## Overview
Three core screens that provide dashboard functionality, user profile management, and notification handling.

---

## 1. Home Screen (Dashboard)

### Purpose
Main dashboard displaying user's vehicles, health scores, upcoming reminders, and quick actions.

### Technologies Used

#### Data Services
- **`CarService`**: Fetches user's vehicles from local SQLite database
- **`CarHealthService`**: Calculates health scores for each vehicle
- **`ReminderService`**: Fetches upcoming maintenance reminders
- **`MaintenanceService`**: Fetches latest maintenance records
- **`NotificationDatabaseService`**: Gets notification count for badge

#### Why These Technologies
- **Local SQLite**: Fast data access, works offline, no network dependency
- **Real-time calculations**: Health scores calculated on-demand for accuracy
- **Service pattern**: Separation of concerns, reusable business logic

### Backend Logic

#### Data Loading Flow
1. **On Screen Init**:
   - Load user's cars (max 5 for swipe carousel)
   - Calculate health score for each car
   - Load upcoming reminders (max 3)
   - Load latest maintenance records (max 3)
   - Load notification count

2. **Car Health Score Calculation**:
   - Uses `CarHealthService.calculateHealthScore()`
   - Factors:
     - Maintenance history (30 points): Compares actual vs expected maintenance frequency
     - Mileage vs age (25 points): Checks if mileage is reasonable for car age
     - Overdue services (25 points): Penalizes overdue reminders
     - Reported issues (20 points): Considers any logged problems
   - Returns score 0-100 with status (excellent/good/fair/poor)
   - Generates recommendations based on score

3. **Pull-to-Refresh**:
   - Refreshes all data sources in parallel using `Future.wait()`
   - Updates UI state after all data loaded

4. **App Lifecycle Handling**:
   - Listens to app state changes
   - Refreshes notification count when app resumes

### Data Sources
- **Cars**: `CarService.getAllCars()` → SQLite `cars` table
- **Health Scores**: Calculated on-demand from maintenance/reminder/mileage data
- **Reminders**: `ReminderService.getAllRemindersWithCarInfo()` → SQLite `reminders` table
- **Maintenance**: `MaintenanceService.getAllMaintenanceWithInfo()` → SQLite `maintenance` table
- **Notifications**: `NotificationDatabaseService.getAllNotifications()` → SQLite + SharedPreferences

### Key Features
- **Multi-car support**: Swipeable carousel (max 5 cars)
- **Real-time health scores**: Calculated per car on load
- **Quick actions**: Direct navigation to services (OCR, OBD, VIN lookup, etc.)
- **Upcoming reminders preview**: Shows next 3 due reminders
- **Latest maintenance preview**: Shows last 3 maintenance records

---

## 2. Profile Screen

### Purpose
Display and edit user profile information, view statistics, and manage account settings.

### Technologies Used

#### Data Services
- **`AuthProvider`**: Manages user authentication state and profile data
- **`AuthService`**: Handles Firebase profile updates
- **`CarService`**: Gets vehicle count
- **`ReminderService`**: Gets reminder count
- **`MaintenanceService`**: Gets maintenance record count

#### Why These Technologies
- **Provider pattern**: State management, reactive UI updates
- **Firebase Firestore**: Centralized user data, syncs across devices
- **Local services**: Fast count queries for statistics

### Backend Logic

#### Data Loading Flow
1. **On Screen Init**:
   - Load user data from `AuthProvider` (Firebase Auth + Firestore)
   - Load statistics (vehicle count, reminder count, maintenance count)
   - Populate form fields with current values

2. **Profile Data Structure**:
   - **Personal Info**: Full name, phone number
   - **Emergency Contact**: Name and phone (stored as combined string, parsed on save)
   - **Statistics**: Real-time counts from database

3. **Profile Update Flow**:
   - User edits fields in edit mode
   - On save:
     - Parse emergency contact (split "Name - Phone" format)
     - Prepare update map with changed fields
     - Call `AuthProvider.updateProfile(updates)`
     - Updates both Firestore collections:
       - `users/{uid}`: Full profile data
       - `authorized_users/{uid}`: Auth-related fields only
     - Refresh profile data after successful update

4. **Statistics Loading**:
   - Queries run in parallel:
     - `CarService.getCarsCount()` → SQLite COUNT query
     - `ReminderService.getRemindersCount()` → SQLite COUNT query
     - `MaintenanceService.getMaintenanceCount()` → SQLite COUNT query

### Data Storage

#### Firebase Firestore
- **Collection: `users/{uid}`**
  - `fullName`, `phoneNumber`
  - `emergencyContactName`, `emergencyContactPhone`
  - `profileImageUrl`, `preferences`, `stats`
  - `createdAt`, `updatedAt`

- **Collection: `authorized_users/{uid}`**
  - `fullName`, `phoneNumber`
  - `emergencyContactName`, `emergencyContactPhone`
  - `isActive`, `role`, `lastLoginAt`

#### Local Database
- Statistics calculated from SQLite tables (cars, reminders, maintenance)

### Key Features
- **Edit mode toggle**: Switch between view/edit states
- **Real-time statistics**: Live counts from database
- **Dual storage update**: Updates both Firestore collections for consistency
- **Emergency contact parsing**: Handles combined "Name - Phone" format
- **Validation**: Form validation before save

---

## 3. Notifications Screen

### Purpose
Display all app notifications (overdue reminders, upcoming reminders) with read/unread status.

### Technologies Used

#### Data Services
- **`NotificationDatabaseService`**: Manages notification data and read status
- **`LocalNotificationService`**: Handles local device notifications
- **`ReminderService`**: Source of reminder-based notifications

#### Why These Technologies
- **NotificationDatabaseService**: Centralized notification logic, converts reminders to notifications
- **SharedPreferences**: Lightweight storage for read/unread status
- **LocalNotificationService**: Device-level notification display

### Backend Logic

#### Notification Generation
1. **Overdue Reminders**:
   - Query reminders where `status = 'overdue'`
   - Convert each to `NotificationItem`:
     - Title: "Overdue: [Reminder Type]"
     - Message: Car name + reminder details
     - Priority: High
     - Type: Reminder
     - Timestamp: Reminder due date

2. **Upcoming Reminders**:
   - Query reminders where `status = 'upcoming'` and due within 7 days
   - Convert to `NotificationItem`:
     - Title: "Upcoming: [Reminder Type]"
     - Message: Car name + days until due
     - Priority: Medium
     - Type: Reminder
     - Timestamp: Reminder due date

3. **Combined List**:
   - Merge overdue + upcoming
   - Sort by timestamp (newest first)
   - Mark read status from SharedPreferences

#### Read/Unread Management
- **Storage**: `SharedPreferences` key `'read_notifications'` (StringList)
- **Mark as Read**: Add notification ID to list
- **Check Read Status**: Check if ID exists in list
- **Mark All Read**: Add all notification IDs to list
- **Delete**: Remove notification ID from list (also marks reminder as completed)

#### Notification Types
- **Maintenance**: Service reminders
- **Reminder**: General reminders
- **Alert**: Critical alerts
- **Info**: Informational messages
- **Warning**: Warnings
- **Success**: Success confirmations

### Data Flow

1. **Load Notifications**:
   ```
   NotificationDatabaseService.getAllNotifications()
   → getOverdueRemindersAsNotifications()
   → getUpcomingRemindersAsNotifications()
   → Combine & Sort
   → Check read status from SharedPreferences
   → Return List<NotificationItem>
   ```

2. **Mark as Read**:
   ```
   User taps notification
   → Update local state (immediate UI feedback)
   → NotificationDatabaseService.markNotificationAsRead(id)
   → Add ID to SharedPreferences 'read_notifications' list
   ```

3. **Delete Notification**:
   ```
   User deletes notification
   → NotificationDatabaseService.deleteNotification(id)
   → Mark reminder as completed (if reminder-based)
   → Remove from local list
   → Reload notifications
   ```

### Data Storage

#### SQLite Database
- **Source**: `reminders` table** (filtered by status)
- **Read Status**: `SharedPreferences` → `'read_notifications'` (StringList)

#### Notification Structure
```dart
NotificationItem {
  id: String (reminder ID or generated)
  title: String
  message: String
  type: NotificationType
  priority: NotificationPriority
  timestamp: DateTime
  isRead: bool
  reminderId: int? (if reminder-based)
}
```

### Key Features
- **Auto-refresh**: Pull-to-refresh support
- **Read status persistence**: Stored in SharedPreferences
- **Priority-based display**: Color-coded by priority
- **Time-based sorting**: Newest first
- **Bulk actions**: Mark all as read, clear all
- **Navigation**: Tap notification → Navigate to reminders screen
- **Real-time counts**: Unread count in header

---

## Common Patterns

### State Management
- **StatefulWidget**: Local state for each screen
- **Provider**: Global auth state (`AuthProvider`)
- **Service Layer**: Business logic separated from UI

### Error Handling
- Try-catch blocks around all async operations
- Graceful degradation (empty states, default values)
- User-friendly error messages via SnackBar

### Data Synchronization
- **Home Screen**: Real-time calculations, no sync needed
- **Profile Screen**: Firebase Firestore (cloud sync)
- **Notifications**: Local SQLite + SharedPreferences (no cloud sync)

### Performance Optimizations
- **Parallel loading**: `Future.wait()` for independent queries
- **Lazy loading**: Only load visible data (max 3-5 items)
- **Caching**: Provider caches user data
- **Efficient queries**: COUNT queries for statistics
