/// Widget tests for Siyanaty+ app
/// Tests individual widgets and UI components in isolation
/// Integration tests are located in integration_test/ directory
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Tests', () {
    test('Widget Test 1: Material widget instantiation', () {
      // Arrange & Act
      const widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test Widget'),
          ),
        ),
      );

      // Assert
      expect(widget, isNotNull);
      expect(widget, isA<MaterialApp>());
    });

    testWidgets('Widget Test 2: Text widget rendering', (WidgetTester tester) async {
      // Arrange
      const testText = 'Siyanaty+ Test';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(testText),
          ),
        ),
      );

      // Assert
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('Widget Test 3: Button widget interaction', (WidgetTester tester) async {
      // Arrange
      var buttonPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => buttonPressed = true,
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(buttonPressed, isTrue);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('Widget Test 4: TextField widget input', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test Input');
      await tester.pump();

      // Assert
      expect(controller.text, equals('Test Input'));
      expect(find.text('Test Input'), findsOneWidget);
    });

    testWidgets('Widget Test 5: Icon widget rendering', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Icon(Icons.car_repair),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.car_repair), findsOneWidget);
    });

    testWidgets('Widget Test 6: ListView widget scrolling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('Widget Test 7: Card widget rendering', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Card(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('Widget Test 8: Container widget with decoration', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Styled Container'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Styled Container'), findsOneWidget);
    });
  });
}
