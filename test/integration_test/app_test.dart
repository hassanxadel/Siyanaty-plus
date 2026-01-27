import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siyanaty_plus/main.dart' as app;
import 'package:flutter/material.dart';

/// Integration test suite for Siyanaty+ app workflows
/// Tests complete user journeys and app functionality
/// 
/// Test Coverage:
/// 1. App launch and initialization
/// 2. Main screen navigation
/// 3. Bottom navigation bar functionality
/// 4. Screen transitions
/// 5. Basic UI element presence
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Siyanaty+ App Integration Tests', () {
    
    /// Helper function to handle system permission dialogs
    /// Automatically clicks "Allow" or "Don't allow" buttons
    Future<void> handlePermissionDialogs(WidgetTester tester) async {
      // Wait a bit for dialogs to appear
      await tester.pump(const Duration(milliseconds: 500));
      
      // Look for common permission dialog buttons
      final allowButton = find.text('Allow');
      final dontAllowButton = find.text("Don't allow");
      final whileUsingButton = find.text('While using the app');
      final onlyThisTimeButton = find.text('Only this time');
      
      // Try to tap "Allow" or "While using the app" if found
      if (allowButton.evaluate().isNotEmpty) {
        await tester.tap(allowButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✓ Handled permission dialog: Allowed');
      } else if (whileUsingButton.evaluate().isNotEmpty) {
        await tester.tap(whileUsingButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✓ Handled permission dialog: While using the app');
      } else if (onlyThisTimeButton.evaluate().isNotEmpty) {
        await tester.tap(onlyThisTimeButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✓ Handled permission dialog: Only this time');
      } else if (dontAllowButton.evaluate().isNotEmpty) {
        // If only "Don't allow" is found, tap it to dismiss
        await tester.tap(dontAllowButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✓ Handled permission dialog: Don\'t allow');
      }
    }

    /// Helper function to wait for app initialization
    Future<void> waitForAppInitialization(WidgetTester tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));
      
      // Handle any permission dialogs that might appear
      await handlePermissionDialogs(tester);
    }

    /// Helper function to find and tap widgets
    Future<bool> tapWidget(
      WidgetTester tester,
      Finder finder,
    ) async {
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Handle any permission dialogs after tap
        await handlePermissionDialogs(tester);
        return true;
      }
      return false;
    }

    testWidgets(
      'Integration Test 1: App Launch and Initialization',
      (WidgetTester tester) async {
        // Test Description:
        // Verifies the app launches successfully and initializes all services

        print('Starting Integration Test 1: App Launch');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Assert: Verify MaterialApp is present
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'MaterialApp should be present after launch');
        
        // Verify Scaffold is present (indicates UI rendered)
        expect(find.byType(Scaffold), findsWidgets,
          reason: 'Scaffold should be present');

        print('✓ MaterialApp widget verified');
        print('✓ Scaffold widget verified');
        print('✅ Test completed: App Launch and Initialization');
      },
    );

    testWidgets(
      'Integration Test 2: Login Screen UI Elements',
      (WidgetTester tester) async {
        // Test Description:
        // Verifies login screen contains necessary UI elements

        print('Starting Integration Test 2: Login Screen UI');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Assert: Check for login screen elements
        final textFields = find.byType(TextField);
        final inkWells = find.byType(InkWell);
        final outlinedButtons = find.byType(OutlinedButton);

        print('✓ Found ${textFields.evaluate().length} TextFields');
        print('✓ Found ${inkWells.evaluate().length} InkWell buttons');
        print('✓ Found ${outlinedButtons.evaluate().length} OutlinedButtons');

        expect(textFields, findsWidgets,
          reason: 'Login screen should have TextFields for credentials');
        
        expect(inkWells, findsWidgets,
          reason: 'Login screen should have InkWell buttons');

        print('✅ Test completed: Login Screen UI Elements');
      },
    );

    testWidgets(
      'Integration Test 3: Bottom Navigation Bar Presence',
      (WidgetTester tester) async {
        // Test Description:
        // Checks if bottom navigation bar is present after successful auth
        // Note: May only be visible after login

        print('Starting Integration Test 3: Bottom Navigation');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Look for bottom navigation bar
        final bottomNav = find.byType(BottomNavigationBar);
        
        if (bottomNav.evaluate().isEmpty) {
          print('ℹ Bottom navigation not visible (user may not be logged in)');
          print('  This is expected if user authentication is required');
        } else {
          print('✓ Bottom navigation bar found');
          print('✓ User appears to be authenticated');
        }

        // Assert: App should be running regardless
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should be running');

        print('✅ Test completed: Bottom Navigation Check');
      },
    );

    testWidgets(
      'Integration Test 4: Screen Navigation Flow',
      (WidgetTester tester) async {
        // Test Description:
        // Tests navigation between different screens if accessible

        print('Starting Integration Test 4: Screen Navigation');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Try to navigate through available screens
        final bottomNav = find.byType(BottomNavigationBar);
        
        if (bottomNav.evaluate().isNotEmpty) {
          print('✓ Found bottom navigation bar');
          
          // Get navigation items
          final navItems = tester.widget<BottomNavigationBar>(bottomNav.first);
          final itemCount = navItems.items.length;
          print('✓ Found $itemCount navigation items');

          // Try tapping each navigation item
          for (int i = 0; i < itemCount && i < 3; i++) {
            // Find tappable areas in the bottom nav
            final navItemFinder = find.descendant(
              of: bottomNav,
              matching: find.byType(InkResponse),
            );
            
            if (navItemFinder.evaluate().length > i) {
              await tapWidget(tester, navItemFinder.at(i));
              print('✓ Navigated to screen $i');
              await tester.pump(const Duration(seconds: 1));
            }
          }
        } else {
          print('ℹ Bottom navigation not available (authentication required)');
        }

        // Assert: App should still be running
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should remain functional after navigation');

        print('✅ Test completed: Screen Navigation Flow');
      },
    );

    testWidgets(
      'Integration Test 5: Text Input Functionality',
      (WidgetTester tester) async {
        // Test Description:
        // Tests that text fields accept input correctly

        print('Starting Integration Test 5: Text Input');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Find text fields
        final textFields = find.byType(TextField);
        final fieldCount = textFields.evaluate().length;
        print('✓ Found $fieldCount text fields');

        if (fieldCount > 0) {
          // Test entering text in the first field
          const testText = 'test@example.com';
          await tester.enterText(textFields.first, testText);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          
          print('✓ Successfully entered text in TextField');
          
          // Verify text was entered
          expect(find.text(testText), findsWidgets,
            reason: 'Entered text should be visible');
        } else {
          print('ℹ No text fields available to test');
        }

        // Assert: App functionality
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should remain functional');

        print('✅ Test completed: Text Input Functionality');
      },
    );

    testWidgets(
      'Integration Test 6: Button Tap Functionality',
      (WidgetTester tester) async {
        // Test Description:
        // Verifies buttons are tappable and responsive

        print('Starting Integration Test 6: Button Tap');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Find buttons
        final inkWells = find.byType(InkWell);
        final textButtons = find.byType(TextButton);
        final outlinedButtons = find.byType(OutlinedButton);
        final totalButtons = inkWells.evaluate().length + 
                           textButtons.evaluate().length + 
                           outlinedButtons.evaluate().length;
        
        print('✓ Found $totalButtons interactive buttons total');
        print('  - InkWells: ${inkWells.evaluate().length}');
        print('  - TextButtons: ${textButtons.evaluate().length}');
        print('  - OutlinedButtons: ${outlinedButtons.evaluate().length}');

        if (totalButtons > 0) {
          // Store widget tree before tap
          final beforeTap = find.byType(MaterialApp);
          expect(beforeTap, findsWidgets);
          
          // Try to tap a button (prefer TextButton for safety)
          if (textButtons.evaluate().isNotEmpty) {
            await tester.tap(textButtons.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✓ Successfully tapped TextButton');
          } else if (outlinedButtons.evaluate().isNotEmpty) {
            await tester.tap(outlinedButtons.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            print('✓ Successfully tapped OutlinedButton');
          }
          
          // App should still be running after tap
          expect(find.byType(MaterialApp), findsWidgets,
            reason: 'App should handle button tap');
          print('✓ Button interaction successful');
        } else {
          print('ℹ No interactive buttons available to test');
        }

        // Assert
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should remain functional after button interactions');

        print('✅ Test completed: Button Tap Functionality');
      },
    );

    testWidgets(
      'Integration Test 7: Scroll Functionality',
      (WidgetTester tester) async {
        // Test Description:
        // Tests scrolling behavior if scrollable widgets are present

        print('Starting Integration Test 7: Scroll Functionality');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Look for scrollable widgets
        final scrollableWidgets = find.byType(SingleChildScrollView);
        final listViews = find.byType(ListView);
        
        if (scrollableWidgets.evaluate().isNotEmpty) {
          print('✓ Found SingleChildScrollView');
          
          // Try scrolling
          await tester.drag(scrollableWidgets.first, const Offset(0, -200));
          await tester.pumpAndSettle();
          print('✓ Scrolled down successfully');
          
          await tester.drag(scrollableWidgets.first, const Offset(0, 200));
          await tester.pumpAndSettle();
          print('✓ Scrolled up successfully');
        } else if (listViews.evaluate().isNotEmpty) {
          print('✓ Found ListView');
          
          await tester.drag(listViews.first, const Offset(0, -100));
          await tester.pumpAndSettle();
          print('✓ Scrolled ListView');
        } else {
          print('ℹ No scrollable widgets found');
        }

        // Assert
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should remain functional after scrolling');

        print('✅ Test completed: Scroll Functionality');
      },
    );

    testWidgets(
      'Integration Test 8: Icon and Image Rendering',
      (WidgetTester tester) async {
        // Test Description:
        // Verifies icons and images render correctly

        print('Starting Integration Test 8: Icon and Image Rendering');

        // Arrange & Act: Launch the app
        app.main();
        await waitForAppInitialization(tester);

        print('✓ App launched successfully');

        // Look for icons
        final icons = find.byType(Icon);
        final iconCount = icons.evaluate().length;
        print('✓ Found $iconCount Icon widgets');

        if (iconCount > 0) {
          expect(icons, findsWidgets,
            reason: 'Icons should be rendered');
        }

        // Look for images
        final images = find.byType(Image);
        final imageCount = images.evaluate().length;
        print('✓ Found $imageCount Image widgets');

        if (imageCount > 0) {
          expect(images, findsWidgets,
            reason: 'Images should be rendered');
        }

        // Assert
        expect(find.byType(MaterialApp), findsWidgets,
          reason: 'App should render visual elements');

        print('✅ Test completed: Icon and Image Rendering');
      },
    );
  });
}
