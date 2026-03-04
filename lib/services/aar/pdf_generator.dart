import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:red_grid_link/core/constants/app_constants.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';

/// Generates a tactical-styled PDF report from [AarData].
///
/// Uses the `pdf` package to build a multi-page document with:
/// - Cover page (session name, mode, date/time, team roster)
/// - Statistics page (duration, participants, markers, distance)
/// - Marker log table
/// - Annotation summary
/// - Track summary per participant
class PdfGenerator {
  PdfGenerator();

  // ---------------------------------------------------------------------------
  // Colors — dark tactical palette for PDF (not Flutter colors)
  // ---------------------------------------------------------------------------
  static const PdfColor _bgColor = PdfColor.fromInt(0xFF0A0A0A);
  static const PdfColor _textColor = PdfColor.fromInt(0xFFCCCCCC);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFFCC0000);
  static const PdfColor _dimColor = PdfColor.fromInt(0xFF666666);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF333333);

  /// Generate a complete AAR PDF document.
  ///
  /// Returns the raw PDF bytes as [Uint8List].
  Future<Uint8List> generate(AarData aar) async {
    final pdf = pw.Document(
      title: 'AAR - ${aar.sessionName}',
      author: AppConstants.appName,
      creator: '${AppConstants.appName} v${AppConstants.appVersion}',
    );

    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();

    // Cover page
    pdf.addPage(_buildCoverPage(aar, mono, monoBold));

    // Statistics page
    pdf.addPage(_buildStatsPage(aar, mono, monoBold));

    // Marker log (may span multiple pages)
    if (aar.markers.isNotEmpty) {
      pdf.addPage(_buildMarkerLogPage(aar, mono, monoBold));
    }

    // Annotation summary
    if (aar.annotations.isNotEmpty) {
      pdf.addPage(_buildAnnotationPage(aar, mono, monoBold));
    }

    // Track summary
    if (aar.trackPoints.isNotEmpty) {
      pdf.addPage(_buildTrackPage(aar, mono, monoBold));
    }

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Cover page
  // ---------------------------------------------------------------------------

  pw.Page _buildCoverPage(AarData aar, pw.Font mono, pw.Font monoBold) {
    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _bgColor,
            border: pw.Border.all(color: _borderColor, width: 1),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title bar
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(color: _headerBg),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'AFTER-ACTION REPORT',
                      style: pw.TextStyle(
                        font: monoBold,
                        fontSize: 22,
                        color: _accentColor,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      AppConstants.appName.toUpperCase(),
                      style: pw.TextStyle(
                        font: mono,
                        fontSize: 10,
                        color: _dimColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Session name
              _labelValue('SESSION', aar.sessionName.toUpperCase(), mono, monoBold),
              pw.SizedBox(height: 16),

              // Mode
              _labelValue(
                'OPERATIONAL MODE',
                _modeDisplayName(aar.operationalMode),
                mono,
                monoBold,
              ),
              pw.SizedBox(height: 16),

              // Timestamps
              _labelValue(
                'START',
                AarService.formatTacticalTimestamp(aar.startTime),
                mono,
                monoBold,
              ),
              pw.SizedBox(height: 8),
              _labelValue(
                'END',
                AarService.formatTacticalTimestamp(aar.endTime),
                mono,
                monoBold,
              ),
              pw.SizedBox(height: 8),
              _labelValue(
                'DURATION',
                AarService.formatDuration(aar.duration),
                mono,
                monoBold,
              ),

              pw.SizedBox(height: 30),
              pw.Divider(color: _borderColor, thickness: 1),
              pw.SizedBox(height: 16),

              // Team roster
              pw.Text(
                'TEAM ROSTER',
                style: pw.TextStyle(
                  font: monoBold,
                  fontSize: 12,
                  color: _accentColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 10),

              if (aar.peers.isEmpty)
                pw.Text(
                  'No participants recorded',
                  style: pw.TextStyle(font: mono, fontSize: 10, color: _dimColor),
                )
              else
                ...aar.peers.map((p) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: const pw.BoxDecoration(
                              color: _accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            p.displayName.toUpperCase(),
                            style: pw.TextStyle(
                              font: mono,
                              fontSize: 11,
                              color: _textColor,
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Text(
                            '(${p.deviceType.name.toUpperCase()})',
                            style: pw.TextStyle(
                              font: mono,
                              fontSize: 9,
                              color: _dimColor,
                            ),
                          ),
                        ],
                      ),
                    )),

              pw.Spacer(),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(color: _headerBg),
                child: pw.Text(
                  'Generated by ${AppConstants.appName} v${AppConstants.appVersion}',
                  style: pw.TextStyle(
                    font: mono,
                    fontSize: 8,
                    color: _dimColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Statistics page
  // ---------------------------------------------------------------------------

  pw.Page _buildStatsPage(AarData aar, pw.Font mono, pw.Font monoBold) {
    final totalDistance = AarService.calculateTotalDistance(aar.trackPoints);
    final areaCovered = AarService.calculateAreaCovered(aar.trackPoints);

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _bgColor,
            border: pw.Border.all(color: _borderColor, width: 1),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pageHeader('SESSION STATISTICS', mono, monoBold),
              pw.SizedBox(height: 20),

              // Stats grid
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'DURATION',
                      AarService.formatDuration(aar.duration),
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'PARTICIPANTS',
                      aar.totalPeers.toString(),
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'MARKERS PLACED',
                      aar.totalMarkers.toString(),
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'TRACK POINTS',
                      aar.totalTrackPoints.toString(),
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'DISTANCE',
                      AarService.formatDistance(totalDistance),
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'AREA COVERED',
                      '${areaCovered.toStringAsFixed(2)} km\u00B2',
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'ANNOTATIONS',
                      aar.annotations.length.toString(),
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'MODE',
                      aar.operationalMode.label,
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              pw.Divider(color: _borderColor, thickness: 1),
              pw.SizedBox(height: 16),

              // Participant breakdown
              pw.Text(
                'PARTICIPANT DETAILS',
                style: pw.TextStyle(
                  font: monoBold,
                  fontSize: 12,
                  color: _accentColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 10),

              if (aar.peers.isEmpty)
                pw.Text(
                  'No participant data recorded',
                  style: pw.TextStyle(font: mono, fontSize: 10, color: _dimColor),
                )
              else
                _buildParticipantTable(aar, mono, monoBold),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _buildParticipantTable(AarData aar, pw.Font mono, pw.Font monoBold) {
    final headers = ['CALLSIGN', 'DEVICE', 'LAST SEEN', 'MARKERS'];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      headerStyle: pw.TextStyle(
        font: monoBold,
        fontSize: 9,
        color: _accentColor,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellStyle: pw.TextStyle(font: mono, fontSize: 9, color: _textColor),
      cellDecoration: (index, data, rowNum) =>
          pw.BoxDecoration(color: rowNum.isOdd ? _headerBg : _bgColor),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headers: headers,
      data: aar.peers.map((p) {
        final markersPlaced = aar.markers
            .where((m) => m.createdBy == p.id || m.createdBy == p.displayName)
            .length;

        return [
          p.displayName.toUpperCase(),
          p.deviceType.name.toUpperCase(),
          AarService.formatTacticalTimestamp(p.lastSeen),
          markersPlaced.toString(),
        ];
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Marker log page
  // ---------------------------------------------------------------------------

  pw.Page _buildMarkerLogPage(AarData aar, pw.Font mono, pw.Font monoBold) {
    final mode = aar.operationalMode;

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _bgColor,
            border: pw.Border.all(color: _borderColor, width: 1),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pageHeader(
                '${_markerTermForMode(mode).toUpperCase()} LOG',
                mono,
                monoBold,
              ),
              pw.SizedBox(height: 16),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  font: monoBold,
                  fontSize: 8,
                  color: _accentColor,
                ),
                headerDecoration: const pw.BoxDecoration(color: _headerBg),
                cellStyle: pw.TextStyle(
                  font: mono,
                  fontSize: 8,
                  color: _textColor,
                ),
                cellDecoration: (index, data, rowNum) =>
                    pw.BoxDecoration(color: rowNum.isOdd ? _headerBg : _bgColor),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(1.5),
                },
                headers: [
                  '#',
                  'LABEL',
                  'MGRS',
                  'PLACED BY',
                  'TIME',
                  'TYPE',
                ],
                data: aar.markers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return [
                    '${i + 1}',
                    m.label.isEmpty ? '-' : m.label.toUpperCase(),
                    m.mgrs.isEmpty ? '${m.lat.toStringAsFixed(5)}, ${m.lon.toStringAsFixed(5)}' : m.mgrs,
                    _truncate(m.createdBy, 12).toUpperCase(),
                    AarService.formatTacticalTimestamp(m.createdAt),
                    m.icon.name.toUpperCase(),
                  ];
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Annotation page
  // ---------------------------------------------------------------------------

  pw.Page _buildAnnotationPage(AarData aar, pw.Font mono, pw.Font monoBold) {
    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _bgColor,
            border: pw.Border.all(color: _borderColor, width: 1),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pageHeader('ANNOTATION SUMMARY', mono, monoBold),
              pw.SizedBox(height: 16),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  font: monoBold,
                  fontSize: 9,
                  color: _accentColor,
                ),
                headerDecoration: const pw.BoxDecoration(color: _headerBg),
                cellStyle: pw.TextStyle(
                  font: mono,
                  fontSize: 9,
                  color: _textColor,
                ),
                cellDecoration: (index, data, rowNum) =>
                    pw.BoxDecoration(color: rowNum.isOdd ? _headerBg : _bgColor),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['#', 'TYPE', 'LABEL', 'POINTS', 'CREATED BY', 'TIME'],
                data: aar.annotations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return [
                    '${i + 1}',
                    a.type.name.toUpperCase(),
                    a.label?.toUpperCase() ?? '-',
                    a.points.length.toString(),
                    _truncate(a.createdBy, 12).toUpperCase(),
                    AarService.formatTacticalTimestamp(a.createdAt),
                  ];
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Track summary page
  // ---------------------------------------------------------------------------

  pw.Page _buildTrackPage(AarData aar, pw.Font mono, pw.Font monoBold) {
    final totalDistance = AarService.calculateTotalDistance(aar.trackPoints);

    // Compute speed statistics
    final speeds = aar.trackPoints
        .where((tp) => tp.speed != null && tp.speed! > 0)
        .map((tp) => tp.speed!)
        .toList();

    final avgSpeed = speeds.isNotEmpty
        ? speeds.reduce((a, b) => a + b) / speeds.length
        : 0.0;
    final maxSpeed = speeds.isNotEmpty
        ? speeds.reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Elevation range
    final altitudes = aar.trackPoints
        .where((tp) => tp.altitude != null)
        .map((tp) => tp.altitude!)
        .toList();

    final minAlt = altitudes.isNotEmpty
        ? altitudes.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxAlt = altitudes.isNotEmpty
        ? altitudes.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: _bgColor,
            border: pw.Border.all(color: _borderColor, width: 1),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pageHeader('TRACK SUMMARY', mono, monoBold),
              pw.SizedBox(height: 20),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'TOTAL DISTANCE',
                      AarService.formatDistance(totalDistance),
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'TRACK POINTS',
                      aar.totalTrackPoints.toString(),
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _statBox(
                      'AVG SPEED',
                      '${avgSpeed.toStringAsFixed(1)} m/s',
                      mono,
                      monoBold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _statBox(
                      'MAX SPEED',
                      '${maxSpeed.toStringAsFixed(1)} m/s',
                      mono,
                      monoBold,
                    ),
                  ),
                ],
              ),
              if (altitudes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _statBox(
                        'MIN ELEVATION',
                        '${minAlt.round()}m',
                        mono,
                        monoBold,
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _statBox(
                        'MAX ELEVATION',
                        '${maxAlt.round()}m',
                        mono,
                        monoBold,
                      ),
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 24),
              pw.Divider(color: _borderColor, thickness: 1),
              pw.SizedBox(height: 12),

              pw.Text(
                'TRACK TIMELINE',
                style: pw.TextStyle(
                  font: monoBold,
                  fontSize: 11,
                  color: _accentColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 8),

              if (aar.trackPoints.isNotEmpty) ...[
                _labelValue(
                  'FIRST POINT',
                  AarService.formatTacticalTimestamp(aar.trackPoints.first.timestamp),
                  mono,
                  monoBold,
                ),
                pw.SizedBox(height: 4),
                _labelValue(
                  'LAST POINT',
                  AarService.formatTacticalTimestamp(aar.trackPoints.last.timestamp),
                  mono,
                  monoBold,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  pw.Widget _pageHeader(String title, pw.Font mono, pw.Font monoBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const pw.BoxDecoration(color: _headerBg),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: monoBold,
          fontSize: 14,
          color: _accentColor,
          letterSpacing: 3,
        ),
      ),
    );
  }

  pw.Widget _labelValue(
    String label,
    String value,
    pw.Font mono,
    pw.Font monoBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: mono,
              fontSize: 9,
              color: _dimColor,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: monoBold,
              fontSize: 11,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _statBox(
    String label,
    String value,
    pw.Font mono,
    pw.Font monoBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: mono,
              fontSize: 8,
              color: _dimColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: monoBold,
              fontSize: 16,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode-specific labels
  // ---------------------------------------------------------------------------

  String _modeDisplayName(OperationalMode mode) {
    switch (mode) {
      case OperationalMode.sar:
        return 'SEARCH AND RESCUE';
      case OperationalMode.backcountry:
        return 'BACKCOUNTRY NAVIGATION';
      case OperationalMode.hunting:
        return 'HUNTING PARTY';
      case OperationalMode.training:
        return 'TRAINING EXERCISE';
    }
  }

  String _markerTermForMode(OperationalMode mode) {
    switch (mode) {
      case OperationalMode.sar:
        return 'Find';
      case OperationalMode.backcountry:
        return 'Waypoint';
      case OperationalMode.hunting:
        return 'Stand';
      case OperationalMode.training:
        return 'Checkpoint';
    }
  }

  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 1)}\u2026';
  }
}
