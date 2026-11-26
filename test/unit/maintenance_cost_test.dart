import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/models/backup_maintenance.dart';

void main() {
  group('parseCost — safe cost parsing', () {
    test('null and empty become 0', () {
      expect(parseCost(null), 0.0);
      expect(parseCost(''), 0.0);
    });

    test('numbers pass through', () {
      expect(parseCost(100), 100.0);
      expect(parseCost(99.5), 99.5);
      expect(parseCost(0), 0.0);
    });

    test('numeric strings parse', () {
      expect(parseCost('250'), 250.0);
      expect(parseCost('99.5'), 99.5);
    });

    test('formatted / dirty strings are cleaned', () {
      expect(parseCost('1,200'), 1200.0);
      expect(parseCost('EGP 300'), 300.0);
      expect(parseCost('  450 '), 450.0);
    });

    test('non-numeric strings become 0 (never throws)', () {
      expect(parseCost('abc'), 0.0);
      expect(parseCost('N/A'), 0.0);
    });
  });

  group('fromMap uses safe cost parsing', () {
    Map<String, dynamic> row(dynamic cost) => {
          'id': 1,
          'title': 'Oil',
          'description': '',
          'cost': cost,
          'maintenance_date': '2026-01-01T00:00:00.000',
          'type': 'mechanics',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        };

    test('a string cost no longer crashes fromMap', () {
      expect(BackupMaintenance.fromMap(row('1,500')).cost, 1500.0);
      expect(BackupMaintenance.fromMap(row(null)).cost, 0.0);
      expect(BackupMaintenance.fromMap(row(320)).cost, 320.0);
    });
  });
}
