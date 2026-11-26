import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/splash/splash_screen.dart';

void main() {
  Future<void> pumpSplash(WidgetTester tester, {double textScale = 1.0}) {
    return tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  Future<void> run(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSplash(tester, textScale: textScale);
    expect(tester.takeException(), isNull); // first frame / layout

    await tester.pump(const Duration(milliseconds: 1100)); // mid-animation
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 1200)); // animation settled
    expect(tester.takeException(), isNull);

    // Dispose cleanly (cancels the slow-startup timer, disposes the controller).
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  }

  testWidgets('Splash renders without overflow at 320x568', (tester) async {
    await run(tester);
  });

  testWidgets('Splash renders without overflow at 320x568, text scale 1.3',
      (tester) async {
    await run(tester, textScale: 1.3);
  });
}
