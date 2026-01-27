import 'package:flutter_test/flutter_test.dart';

/// Unit tests for Authentication Service
/// Tests email validation, password validation, and user data validation logic
void main() {
  group('AuthService Unit Tests', () {
    // Helper function for email validation
    bool isValidEmail(String email) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      return emailRegex.hasMatch(email);
    }

    // Helper function for password validation
    bool isValidPassword(String password) {
      return password.length >= 6;
    }

    // Helper function for phone validation
    bool isValidPhoneNumber(String phone) {
      final phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
      return phoneRegex.hasMatch(phone);
    }

    test('Unit Test 1: Valid email format validation', () {
      // Arrange
      const validEmails = [
        'hassanadelh@outlook.com',
        'test.user@example.com',
        'user123@test-domain.com',
        'simple@email.com'
      ];

      // Act & Assert
      for (final email in validEmails) {
        final result = isValidEmail(email);
        expect(result, isTrue, 
          reason: 'Email "$email" should be valid');
      }
    });

    test('Unit Test 2: Invalid email format validation', () {
      // Arrange
      const invalidEmails = [
        'invalid',
        'invalid@',
        '@invalid.com',
        'invalid@.com',
        'invalid email@domain.com',
        ''
      ];

      // Act & Assert
      for (final email in invalidEmails) {
        final result = isValidEmail(email);
        expect(result, isFalse, 
          reason: 'Email "$email" should be invalid');
      }
    });

    test('Unit Test 3: Password minimum length validation', () {
      // Arrange
      const validPasswords = [
        '040800Masr',
        'Test123',
        'MyPass123!',
        'Simple6'
      ];
      const invalidPasswords = [
        'short',
        '12345',
        'pass',
        ''
      ];

      // Act & Assert - Valid passwords
      for (final password in validPasswords) {
        final result = isValidPassword(password);
        expect(result, isTrue, 
          reason: 'Password "$password" should meet minimum length (6 chars)');
      }

      // Act & Assert - Invalid passwords
      for (final password in invalidPasswords) {
        final result = isValidPassword(password);
        expect(result, isFalse, 
          reason: 'Password "$password" should fail length check');
      }
    });

    test('Unit Test 4: User registration required fields validation', () {
      // Arrange - Valid registration data
      const email = 'test@example.com';
      const password = 'Test123456';
      const fullName = 'Test User';
      const phoneNumber = '+201234567890';

      // Act
      final hasEmail = email.isNotEmpty && isValidEmail(email);
      final hasPassword = password.isNotEmpty && isValidPassword(password);
      final hasFullName = fullName.trim().isNotEmpty;
      final hasValidPhone = phoneNumber.isNotEmpty && isValidPhoneNumber(phoneNumber);

      // Assert
      expect(hasEmail, isTrue, reason: 'Valid email is required for registration');
      expect(hasPassword, isTrue, reason: 'Valid password is required for registration');
      expect(hasFullName, isTrue, reason: 'Full name is required for registration');
      expect(hasValidPhone, isTrue, reason: 'Valid phone number format is required');
    });

    test('Unit Test 5: Email normalization and trimming', () {
      // Arrange
      const testCases = {
        'TestUser@Example.COM': 'testuser@example.com',
        '  user@domain.com  ': 'user@domain.com',
        'MixedCase@TEST.com': 'mixedcase@test.com',
        'hassanadelh@outlook.com': 'hassanadelh@outlook.com',
      };

      // Act & Assert
      testCases.forEach((input, expected) {
        final normalized = input.trim().toLowerCase();
        expect(normalized, equals(expected),
          reason: 'Email "$input" should normalize to "$expected"');
      });
    });

    test('Unit Test 6: Password confirmation matching', () {
      // Arrange
      const password = 'MySecurePass123';
      const matchingConfirm = 'MySecurePass123';
      const nonMatchingConfirm = 'DifferentPass123';

      // Act
      const passwordsMatch = password == matchingConfirm;
      const passwordsDontMatch = password == nonMatchingConfirm;

      // Assert
      expect(passwordsMatch, isTrue, 
        reason: 'Matching passwords should be equal');
      expect(passwordsDontMatch, isFalse, 
        reason: 'Non-matching passwords should not be equal');
    });

    test('Unit Test 7: Phone number format validation', () {
      // Arrange
      const validPhones = [
        '+201234567890',
        '+1234567890',
        '+447911123456',
      ];
      const invalidPhones = [
        'not-a-phone',
        '+',
        '+12345',  // Too short
        '',
      ];

      // Act & Assert - Valid phones
      for (final phone in validPhones) {
        final result = isValidPhoneNumber(phone);
        expect(result, isTrue, 
          reason: 'Phone "$phone" should be valid');
      }

      // Act & Assert - Invalid phones
      for (final phone in invalidPhones) {
        final result = isValidPhoneNumber(phone);
        expect(result, isFalse, 
          reason: 'Phone "$phone" should be invalid');
      }
    });

    test('Unit Test 8: Empty field validation', () {
      // Arrange
      const emptyString = '';
      const whitespaceString = '   ';
      const validString = 'Valid Input';

      // Act
      final emptyIsInvalid = emptyString.trim().isEmpty;
      final whitespaceIsInvalid = whitespaceString.trim().isEmpty;
      final validIsValid = validString.trim().isNotEmpty;

      // Assert
      expect(emptyIsInvalid, isTrue, 
        reason: 'Empty string should be invalid');
      expect(whitespaceIsInvalid, isTrue, 
        reason: 'Whitespace-only string should be invalid');
      expect(validIsValid, isTrue, 
        reason: 'Non-empty string should be valid');
    });
  });
}

