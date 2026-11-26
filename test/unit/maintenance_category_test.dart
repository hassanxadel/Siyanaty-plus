import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/models/backup_maintenance.dart';
import 'package:siyanaty_plus/presentation/screens/services/maintenance_screen.dart';

void main() {
  group('MaintenanceType category mapping', () {
    test('every type has a non-empty display name', () {
      for (final t in MaintenanceType.values) {
        expect(t.displayName.trim(), isNotEmpty);
      }
    });

    test('every type maps to a distinct icon (one consistent mapping)', () {
      final icons = MaintenanceType.values.map((t) => t.icon).toSet();
      expect(icons.length, MaintenanceType.values.length);
      for (final t in MaintenanceType.values) {
        expect(t.icon, isA<IconData>());
      }
    });
  });

  group('BackupMaintenance.fromMap category safety', () {
    Map<String, dynamic> baseMap(String? type) => {
          'id': 1,
          'title': 'Oil change',
          'description': '',
          'cost': 100.0,
          'maintenance_date': '2026-01-01T00:00:00.000',
          'type': type,
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        };

    test('known types parse exactly (existing records unaffected)', () {
      for (final t in MaintenanceType.values) {
        final m = BackupMaintenance.fromMap(baseMap(t.name));
        expect(m.type, t);
      }
    });

    test('an unknown type string falls back to Others, never Mechanics', () {
      final m = BackupMaintenance.fromMap(baseMap('spaceship'));
      expect(m.type, MaintenanceType.others);
    });

    test('a missing (null) type falls back to Others', () {
      final m = BackupMaintenance.fromMap(baseMap(null));
      expect(m.type, MaintenanceType.others);
    });
  });
}
