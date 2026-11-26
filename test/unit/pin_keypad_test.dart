import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/widgets/pin_keypad.dart';
import 'package:siyanaty_plus/presentation/widgets/license_pin_sheet.dart';

void main() {
  Widget harness(Widget child, {double width = 320}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  group('PinKeypad (the one shared keypad)', () {
    testWidgets('renders 0-9 + backspace and fires the matching callbacks',
        (tester) async {
      String? digit;
      var backspaces = 0;
      await tester.pumpWidget(harness(
        PinKeypad(
          keySize: 60,
          onDigit: (d) => digit = d,
          onBackspace: () => backspaces++,
        ),
      ));

      for (final k in ['0', '1', '5', '9']) {
        expect(find.text(k), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

      await tester.tap(find.text('7'));
      expect(digit, '7');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(backspaces, 1);
    });

    testWidgets('shows the biometric key only when onBiometric is provided',
        (tester) async {
      await tester.pumpWidget(harness(
        PinKeypad(keySize: 60, onDigit: (_) {}, onBackspace: () {}),
      ));
      expect(find.byIcon(Icons.fingerprint), findsNothing);

      var bio = 0;
      await tester.pumpWidget(harness(
        PinKeypad(
          keySize: 60,
          onDigit: (_) {},
          onBackspace: () {},
          onBiometric: () => bio++,
        ),
      ));
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fingerprint));
      expect(bio, 1);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      var digit = '';
      await tester.pumpWidget(harness(
        PinKeypad(
          keySize: 60,
          enabled: false,
          onDigit: (d) => digit = d,
          onBackspace: () {},
        ),
      ));
      await tester.tap(find.text('4'));
      expect(digit, '');
    });

    testWidgets('does not overflow at a small key size on a 320px width',
        (tester) async {
      await tester.pumpWidget(harness(
        PinKeypad(keySize: 54, onDigit: (_) {}, onBackspace: () {}),
        width: 320,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('License PIN gate', () {
    // Stub flutter_secure_storage so the sheet's init (PIN length / lockout
    // lookups) resolves to "no PIN set" instead of throwing in tests.
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    testWidgets('Cancel closes the sheet and never returns success',
        (tester) async {
      LicensePinResult? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showLicensePinSheet(context,
                      carLabel: 'Toyota Corolla 2018');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The gate is on screen, scoped to the car.
      expect(find.text('Enter PIN to view license'), findsOneWidget);
      expect(find.text('Toyota Corolla 2018'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, LicensePinResult.cancelled);
      expect(result, isNot(LicensePinResult.success));
    });
  });
}
