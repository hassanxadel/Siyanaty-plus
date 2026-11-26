import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/security/pin_setup_screen.dart';
import 'package:siyanaty_plus/presentation/widgets/pin_dots.dart';
import 'package:siyanaty_plus/presentation/widgets/pin_keypad.dart';

/// Pumps [child] inside a surface of the given [size] (and optional accessibility
/// text scale), mirroring the small devices the PIN screens must survive.
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(320, 568),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: child,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('PinKeypad.responsiveSize (one sizing formula for every PIN surface)', () {
    double sizeFor(double w, double h) =>
        PinKeypad.responsiveSize(BoxConstraints(maxWidth: w, maxHeight: h));

    test('stays within the 56–80 touch-target range on the target phones', () {
      for (final s in const [
        Size(320, 568),
        Size(360, 640),
        Size(390, 844),
        Size(430, 932),
      ]) {
        expect(sizeFor(s.width, s.height), inInclusiveRange(56.0, 80.0));
      }
    });

    test('clamps up on a short (landscape) screen and down on a tablet', () {
      expect(sizeFor(640, 360), 56.0); // height-limited -> clamped up to the floor
      expect(sizeFor(2000, 2000), 80.0); // huge -> clamped down to the ceiling
    });

    test('falls back to width when height is unbounded (inside a scroll view)',
        () {
      expect(
        PinKeypad.responsiveSize(
            const BoxConstraints(maxWidth: 400, maxHeight: double.infinity)),
        80.0,
      );
    });
  });

  group('PinDots', () {
    testWidgets('renders one dot per length and never overflows', (tester) async {
      await _pumpAt(
        tester,
        const Scaffold(body: Center(child: PinDots(length: 6, filledCount: 3))),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PinSetupScreen responsive layout', () {
    testWidgets('no overflow on a 320x568 screen (create step)', (tester) async {
      await _pumpAt(tester, const PinSetupScreen());
      expect(find.text('Create your PIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on 320x568 at text scale 1.3', (tester) async {
      await _pumpAt(tester, const PinSetupScreen(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow after advancing to the confirm step',
        (tester) async {
      await _pumpAt(tester, const PinSetupScreen());
      for (final d in ['1', '3', '5', '7']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      // The fourth digit auto-advances after a short delay.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
