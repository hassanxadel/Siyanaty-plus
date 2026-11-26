import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/shared/utils/reminder_urgency.dart';
import 'package:siyanaty_plus/shared/constants/app_theme.dart';

void main() {
  group('daysLeftColor thresholds (≤7 red · 8–90 orange · >90 green)', () {
    test('7 days or fewer, including overdue, are red', () {
      expect(daysLeftColor(-2), AppTheme.errorColor);
      expect(daysLeftColor(3), AppTheme.errorColor);
      expect(daysLeftColor(7), AppTheme.errorColor);
    });

    test('8–90 days are orange', () {
      expect(daysLeftColor(8), AppTheme.warningColor);
      expect(daysLeftColor(45), AppTheme.warningColor);
      expect(daysLeftColor(90), AppTheme.warningColor);
    });

    test('more than 90 days are green', () {
      expect(daysLeftColor(91), AppTheme.secondaryGreen);
      expect(daysLeftColor(200), AppTheme.secondaryGreen);
    });
  });

  group('daysLeftText', () {
    test('overdue reads "Overdue by X days", never a negative number', () {
      expect(daysLeftText(-1), 'Overdue by 1 day');
      expect(daysLeftText(-5), 'Overdue by 5 days');
    });

    test('today and future', () {
      expect(daysLeftText(0), 'Today');
      expect(daysLeftText(1), '1 day');
      expect(daysLeftText(15), '15 days');
    });
  });
}
