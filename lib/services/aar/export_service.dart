import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';
import 'package:red_grid_link/services/aar/pdf_generator.dart';

/// Export service for AAR PDF reports.
///
/// Takes compiled [AarData], generates a PDF via [PdfGenerator],
/// saves it to the device's temp directory, and shares it via the
/// system share sheet using [share_plus].
class ExportService {
  final PdfGenerator _pdfGenerator;

  ExportService({PdfGenerator? pdfGenerator})
      : _pdfGenerator = pdfGenerator ?? PdfGenerator();

  /// Generate a PDF from [aar], save to temp, and share via the
  /// system share sheet.
  ///
  /// Returns the file path of the saved PDF.
  Future<String> exportAndShare(AarData aar) async {
    // Generate PDF bytes
    final pdfBytes = await _pdfGenerator.generate(aar);

    // Save to temp directory
    final filePath = await _savePdf(pdfBytes, aar);

    // Share via system share sheet
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'AAR - ${aar.sessionName}',
      text: 'After-Action Report: ${aar.sessionName}\n'
          '${AarService.formatTacticalTimestamp(aar.startTime)} - '
          '${AarService.formatTacticalTimestamp(aar.endTime)}',
    );

    return filePath;
  }

  /// Generate and save the PDF without opening the share sheet.
  ///
  /// Useful for programmatic export or testing.
  /// Returns the file path of the saved PDF.
  Future<String> exportToFile(AarData aar) async {
    final pdfBytes = await _pdfGenerator.generate(aar);
    return _savePdf(pdfBytes, aar);
  }

  /// Save PDF bytes to the temp directory with a tactical filename.
  Future<String> _savePdf(List<int> pdfBytes, AarData aar) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = _buildFileName(aar);
    final filePath = p.join(tempDir.path, fileName);

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    return filePath;
  }

  /// Build a sanitized file name: "AAR_{sessionName}_{date}.pdf"
  String _buildFileName(AarData aar) {
    final sanitizedName = aar.sessionName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toUpperCase();

    final dateStr = _formatDateCompact(aar.startTime);

    return 'AAR_${sanitizedName}_$dateStr.pdf';
  }

  /// Format date as "02MAR26" for file naming.
  String _formatDateCompact(DateTime dt) {
    final utc = dt.toUtc();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];

    final day = utc.day.toString().padLeft(2, '0');
    final month = months[utc.month - 1];
    final year = (utc.year % 100).toString().padLeft(2, '0');

    return '$day$month$year';
  }
}
