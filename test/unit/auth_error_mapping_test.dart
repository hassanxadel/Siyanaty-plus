import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/presentation/screens/auth/login_screen.dart';

void main() {
  group('friendlyAuthError', () {
    test('cancellation maps to empty (no error shown)', () {
      expect(friendlyAuthError('Sign-in cancelled'), '');
      expect(friendlyAuthError('The user canceled the sign in'), '');
    });

    test('wrong credentials collapse to one safe message', () {
      expect(friendlyAuthError('wrong-password'), 'Incorrect email or password.');
      expect(friendlyAuthError('user-not-found'), 'Incorrect email or password.');
      expect(friendlyAuthError('invalid-credential'),
          'Incorrect email or password.');
    });

    test('network and rate-limit are distinct', () {
      expect(friendlyAuthError('A network error occurred'),
          'No internet connection. Check your network and try again.');
      expect(friendlyAuthError('too-many-requests'),
          'Too many attempts. Please try again later.');
    });

    test('account-exists-with-different-credential is explained', () {
      expect(
        friendlyAuthError('account-exists-with-different-credential'),
        'This email is already registered with a different sign-in method.',
      );
    });

    test('null/empty never crashes and gives a safe default', () {
      expect(friendlyAuthError(null), 'Something went wrong. Please try again.');
      expect(friendlyAuthError(''), 'Something went wrong. Please try again.');
    });

    test('already-friendly messages pass through unchanged', () {
      const msg = 'Access denied. You are not authorized to use this app.';
      expect(friendlyAuthError(msg), msg);
    });
  });
}
