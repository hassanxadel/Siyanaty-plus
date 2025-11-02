# Gradient Styling Guide

## Standard Gradient Pattern for Cards

Replace all card `BoxDecoration` with this pattern:

```dart
decoration: BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.darkAccentGreen,
      AppTheme.backgroundGreen,
    ],
  ),
  borderRadius: BorderRadius.circular(20), // Adjust radius as needed
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ],
),
```

## Standard Gradient Pattern for Buttons

Replace all button containers with this pattern:

```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.backgroundGreen,
        AppTheme.primaryGreen,
        AppTheme.darkAccentGreen,
      ],
    ),
    borderRadius: BorderRadius.circular(15), // Adjust radius as needed
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryGreen.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ElevatedButton(
    // ... button content
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      // ... other styles
    ),
  ),
)
```

## Standard Curved Header Pattern

Add this to screens that need the curved header:

```dart
Widget _buildHeader(BuildContext context) {
  return Container(
    height: 200,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.backgroundGreen,
          AppTheme.darkAccentGreen,
          AppTheme.primaryGreen,
        ],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Screen Title',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Screen subtitle/description',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

## Screens to Update

1. ✅ Mileage Track Screen (Already done)
2. ⏳ Home Screen
3. ⏳ Reminders Screen
4. ⏳ Maintenance Screen
5. ⏳ Settings Screen
6. ⏳ OBD Screen
7. ⏳ Services Screen
8. ⏳ VIN Lookup Screen
9. ⏳ Cars Screen
10. ⏳ Profile Screen
11. ⏳ Barcode Scanner Screen
12. ⏳ Notifications Screen
13. ⏳ Backup Management Screen
14. ⏳ About & Support Screens (add curved header)

## Common Patterns to Replace

### Old Pattern 1 (Solid Color):
```dart
decoration: BoxDecoration(
  color: AppTheme.getThemeAwareBackground(context).withOpacity(0.15),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: AppTheme.getThemeAwareBackground(context).withOpacity(0.2),
    width: 1,
  ),
),
```

### Old Pattern 2 (Primary Green):
```dart
decoration: BoxDecoration(
  color: AppTheme.primaryGreen.withOpacity(0.3),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.white.withOpacity(0.2),
    width: 1,
  ),
),
```

### Old Pattern 3 (White/Light):
```dart
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(15),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ],
),
```

All of these should be replaced with the standard gradient pattern shown at the top.

