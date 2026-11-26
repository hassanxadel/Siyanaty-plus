import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/auth/forgot_password_screen.dart';

void main() {
  group('isValidEmailFormat', () {
    test('accepts valid, rejects invalid', () {
      expect(isValidEmailFormat('a@b.com'), isTrue);
      expect(isValidEmailFormat('  Hassan@Example.co  '), isTrue);
      expect(isValidEmailFormat('nope'), isFalse);
      expect(isValidEmailFormat('a@b'), isFalse);
      expect(isValidEmailFormat(''), isFalse);
    });
  });

  group('friendlyResetError', () {
    test('maps the real (enumeration-safe) errors', () {
      expect(friendlyResetError('invalid-email'), 'Enter a valid email address.');
      expect(friendlyResetError('network-request-failed'),
          'No internet connection. Check your network and try again.');
      expect(friendlyResetError('too-many-requests'),
          'Too many attempts. Please try again later.');
      expect(friendlyResetError('something-else'),
          "Couldn't send the reset link. Please try again.");
    });
  });

  Future<void> run(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: const ModernForgotPasswordScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900)); // entrance animation
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox()); // dispose cleanly
    expect(tester.takeException(), isNull);
  }

  testWidgets('Reset Password renders without overflow at 320x568',
      (tester) async {
    await run(tester);
  });

  testWidgets('Reset Password renders without overflow at 320x568, text 1.3',
      (tester) async {
    await run(tester, textScale: 1.3);
  });
}
