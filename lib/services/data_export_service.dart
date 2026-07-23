import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../shared/constants/app_constants.dart';
import '../shared/utils/app_logger.dart';

/// Result of a data-export attempt.
///
/// Follows the project convention of returning result objects rather than
/// throwing: screens branch on [isSuccess] instead of wrapping in try/catch.
class ExportResult {
  final bool isSuccess;
  final String message;
  final File? file;

  const ExportResult._({
    required this.isSuccess,
    required this.message,
    this.file,
  });

  factory ExportResult.success(File file) => ExportResult._(
        isSuccess: true,
        message: 'Export ready',
        file: file,
      );

  factory ExportResult.error(String message) =>
      ExportResult._(isSuccess: false, message: message);
}

/// Collects everything the app stores locally into a single JSON file the user
/// can save to their device or share to another app.
///
/// It dumps every user table in the local SQLite database generically (via
/// `sqlite_master`) rather than naming each one, so new tables are captured
/// automatically and the export can't silently miss a data type.
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  static DataExportService get instance => _instance;

  /// Build the export file. Returns its path via [ExportResult]; the caller is
  /// responsible for sharing it (e.g. with `share_plus`).
  Future<ExportResult> exportToFile() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // All user tables — skip SQLite/Android internal bookkeeping tables.
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' "
        "AND name NOT LIKE 'android_%'",
      );

      final tables = <String, dynamic>{};
      var totalRows = 0;
      for (final row in tableRows) {
        final name = row['name'] as String?;
        if (name == null) continue;
        try {
          final data = await db.query(name);
          tables[name] = data;
          totalRows += data.length;
        } catch (e) {
          // One unreadable table must not abort the whole export.
          AppLogger.warning('Skipped table "$name" during export', error: e);
        }
      }

      final export = <String, dynamic>{
        'app': AppConstants.appName,
        'appVersion': AppConstants.appVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'totalRows': totalRows,
        'tables': tables,
      };

      // Rows can contain BLOBs (Uint8List) or other non-JSON types; the
      // toEncodable fallback stringifies anything the encoder can't handle.
      final json = JsonEncoder.withIndent('  ', (obj) => obj.toString())
          .convert(export);

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/siyanaty_export_$stamp.json');
      await file.writeAsString(json);

      AppLogger.info('Data export written: ${file.path} ($totalRows rows)');
      return ExportResult.success(file);
    } catch (e) {
      AppLogger.error('Data export failed', error: e);
      return ExportResult.error('Could not export your data');
    }
  }
}
