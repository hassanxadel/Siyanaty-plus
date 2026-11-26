import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/widgets/gradient_button.dart';

void _noop() {}

void main() {
  Widget harness(Widget child, {double textScale = 1.0, double width = 320}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('GradientButton does not overflow with a long label at text scale 1.3',
      (tester) async {
    await tester.pumpWidget(harness(
      const GradientButton(
        label: 'Save all of my very long profile changes right now please',
        onPressed: _noop,
      ),
      width: 240,
      textScale: 1.3,
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GradientButton fires onPressed when enabled', (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(
      GradientButton(label: 'Edit Profile', onPressed: () => tapped = true),
    ));
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('GradientButton shows a spinner and ignores taps while loading',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(
      GradientButton(label: 'Saving', isLoading: true, onPressed: () => tapped = true),
    ));
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('GradientButton is disabled (no exception) when onPressed is null',
      (tester) async {
    await tester.pumpWidget(
      harness(const GradientButton(label: 'Disabled', onPressed: null)),
    );
    expect(tester.takeException(), isNull);
    // A null handler must not invoke anything on tap.
    await tester.tap(find.byType(GradientButton));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
