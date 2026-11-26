import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/actions/all_actions_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(320, 568),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: const AllActionsScreen(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600)); // let the intro settle
}

void main() {
  testWidgets('first row renders with no overflow on a 320x568 screen',
      (tester) async {
    await _pump(tester);
    // Row 1, in order, is on screen: VIN Lookup · Car Health · Maintenance.
    expect(find.text('VIN Lookup'), findsOneWidget);
    expect(find.text('Car Health'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow on 320x568 at text scale 1.3', (tester) async {
    await _pump(tester, textScale: 1.3);
    // Header + first row survive large text with no RenderFlex overflow.
    expect(find.text('VIN Lookup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the restored page header title', (tester) async {
    await _pump(tester);
    expect(find.text('All Actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the last row renders when scrolled into view', (tester) async {
    await _pump(tester);
    // Row 3 is below the fold on a short screen; scroll it in, then verify it
    // lays out without overflow.
    await tester.dragUntilVisible(
      find.text('Service Reminders'),
      find.byType(GridView),
      const Offset(0, -120),
    );
    await tester.pump();
    expect(find.text('Service Reminders'), findsOneWidget);
    expect(find.text('OBD-II Diagnostics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
