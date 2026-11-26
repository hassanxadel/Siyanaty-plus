import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Urgency color for a reminder's days-left — the single source of truth shared
/// by the Home card and the Reminders screen, so they can never drift.
/// ≤7 (including overdue): red · 8–90: orange · >90: green. Never
/// [AppTheme.backgroundGreen] (too dark to read on the app background).
Color daysLeftColor(int days) {
  if (days <= 7) return AppTheme.errorColor;
  if (days <= 90) return AppTheme.warningColor;
  return AppTheme.secondaryGreen;
}

/// Human text for days-left; overdue reads "Overdue by X days".
String daysLeftText(int days) {
  if (days < 0) {
    final d = days.abs();
    return 'Overdue by $d ${d == 1 ? 'day' : 'days'}';
  }
  if (days == 0) return 'Today';
  return '$days ${days == 1 ? 'day' : 'days'}';
}
