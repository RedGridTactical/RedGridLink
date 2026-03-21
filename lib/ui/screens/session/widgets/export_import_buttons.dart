import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/aar_data.dart';
import '../../../../services/session/session_exporter.dart';
import '../../../../services/session/session_importer.dart';

/// Export button for a single session row.
///
/// Serializes the given [aarData] to JSON, writes it to a temp file,
/// and opens the system share sheet.
class SessionExportButton extends StatelessWidget {
  const SessionExportButton({
    super.key,
    required this.aarData,
    required this.colors,
  });

  final AarData aarData;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.file_upload_outlined, color: colors.accent, size: 20),
      tooltip: 'Export Session',
      onPressed: () => _export(context),
    );
  }

  Future<void> _export(BuildContext context) async {
    tapMedium();
    try {
      final jsonString = SessionExporter.exportToJson(aarData);
      final filename = SessionExporter.generateFilename(aarData.sessionName);

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, filename);
      await File(filePath).writeAsString(jsonString, flush: true);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Session Export - ${aarData.sessionName}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

/// Import button that opens a file picker, reads a .json file,
/// and passes the parsed [AarData] to [onImported].
class SessionImportButton extends StatelessWidget {
  const SessionImportButton({
    super.key,
    required this.colors,
    required this.onImported,
  });

  final TacticalColorScheme colors;

  /// Callback invoked with the successfully imported [AarData].
  final ValueChanged<AarData> onImported;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.file_download_outlined, color: colors.accent, size: 20),
      tooltip: 'Import Session',
      onPressed: () => _import(context),
    );
  }

  Future<void> _import(BuildContext context) async {
    tapMedium();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final importResult = SessionImporter.importFromJson(jsonString);

      if (!context.mounted) return;

      if (importResult.isSuccess) {
        onImported(importResult.data!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported: ${importResult.data!.sessionName}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: ${importResult.error}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}

/// A combined export/import action bar, suitable for an app bar or
/// bottom toolbar on the session history screen.
class ExportImportActions extends StatelessWidget {
  const ExportImportActions({
    super.key,
    required this.colors,
    required this.onImported,
  });

  final TacticalColorScheme colors;
  final ValueChanged<AarData> onImported;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SessionImportButton(
          colors: colors,
          onImported: onImported,
        ),
      ],
    );
  }
}
