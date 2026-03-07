import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Coordinate Converter: converts between MGRS, Lat/Lon DD, DMS, and UTM.
///
/// Input format is selected via dropdown. Results show all other formats
/// with tap-to-copy support.
class CoordinateConverterTool extends StatefulWidget {
  const CoordinateConverterTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  State<CoordinateConverterTool> createState() =>
      _CoordinateConverterToolState();
}

enum _InputFormat { mgrs, latLonDD, latLonDMS }

class _CoordinateConverterToolState extends State<CoordinateConverterTool> {
  _InputFormat _format = _InputFormat.mgrs;

  // MGRS input
  final _mgrsController = TextEditingController();

  // Lat/Lon DD input
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  // DMS input
  final _latDmsController = TextEditingController();
  final _lonDmsController = TextEditingController();

  // Results
  String? _resultMGRS;
  String? _resultMGRSFormatted;
  String? _resultLatDD;
  String? _resultLonDD;
  String? _resultLatDMS;
  String? _resultLonDMS;
  String? _resultUTM;
  String? _error;

  TacticalColorScheme get colors => widget.colors;

  @override
  void dispose() {
    _mgrsController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _latDmsController.dispose();
    _lonDmsController.dispose();
    super.dispose();
  }

  void _convert() {
    tapMedium();
    setState(() => _error = null);

    double? lat;
    double? lon;

    switch (_format) {
      case _InputFormat.mgrs:
        final result = parseMGRSToLatLon(_mgrsController.text);
        if (result == null) {
          setState(() {
            _error = 'Invalid MGRS coordinate';
            _clearResults();
          });
          return;
        }
        lat = result.lat;
        lon = result.lon;
        break;

      case _InputFormat.latLonDD:
        lat = double.tryParse(_latController.text);
        lon = double.tryParse(_lonController.text);
        if (lat == null || lon == null) {
          setState(() {
            _error = 'Enter valid decimal degrees';
            _clearResults();
          });
          return;
        }
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
          setState(() {
            _error = 'Lat: -90 to 90, Lon: -180 to 180';
            _clearResults();
          });
          return;
        }
        break;

      case _InputFormat.latLonDMS:
        lat = parseDMS(_latDmsController.text);
        lon = parseDMS(_lonDmsController.text);
        if (lat == null || lon == null) {
          setState(() {
            _error = 'Enter valid DMS (e.g., N 38 53 51.7)';
            _clearResults();
          });
          return;
        }
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
          setState(() {
            _error = 'Parsed values out of range';
            _clearResults();
          });
          return;
        }
        break;
    }

    // Now convert lat/lon to all formats
    final mgrsRaw = toMGRS(lat, lon, 5);
    final mgrsFormatted = formatMGRS(mgrsRaw);
    final latDMS = formatCoordinate(lat, true);
    final lonDMS = formatCoordinate(lon, false);
    final utm = formatUTM(lat, lon);

    setState(() {
      _resultMGRS = mgrsRaw;
      _resultMGRSFormatted = mgrsFormatted;
      _resultLatDD = lat!.toStringAsFixed(6);
      _resultLonDD = lon!.toStringAsFixed(6);
      _resultLatDMS = latDMS;
      _resultLonDMS = lonDMS;
      _resultUTM = utm;
    });
    notifySuccess();
  }

  void _clearResults() {
    _resultMGRS = null;
    _resultMGRSFormatted = null;
    _resultLatDD = null;
    _resultLonDD = null;
    _resultLatDMS = null;
    _resultLonDMS = null;
    _resultUTM = null;
  }

  void _copyResult(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    notifySuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label COPIED',
            style: TacticalTextStyles.caption(colors)
                .copyWith(color: Colors.white)),
        backgroundColor: colors.accent,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('COORD CONVERTER',
            style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Input Format', colors: colors),
            const SizedBox(height: 8),

            // Format selector
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: colors.card2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_InputFormat>(
                  value: _format,
                  isExpanded: true,
                  dropdownColor: colors.card,
                  style: TacticalTextStyles.value(colors),
                  items: const [
                    DropdownMenuItem(
                      value: _InputFormat.mgrs,
                      child: Text('MGRS'),
                    ),
                    DropdownMenuItem(
                      value: _InputFormat.latLonDD,
                      child: Text('Lat/Lon (Decimal)'),
                    ),
                    DropdownMenuItem(
                      value: _InputFormat.latLonDMS,
                      child: Text('Lat/Lon (DMS)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _format = v;
                        _clearResults();
                        _error = null;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input fields based on format
            ..._buildInputFields(),

            const SizedBox(height: 16),

            // Convert button
            TacticalButton(
              label: 'Convert',
              icon: Icons.sync_alt,
              colors: colors,
              onPressed: _convert,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TacticalTextStyles.body(colors).copyWith(
                  color: const Color(0xFFCC0000),
                ),
              ),
            ],

            if (_resultMGRS != null) ...[
              const SizedBox(height: 20),
              SectionHeader(title: 'Results', colors: colors),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'MGRS',
                value: _resultMGRSFormatted!,
                colors: colors,
                onCopy: () => _copyResult(_resultMGRS!, 'MGRS'),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'LAT/LON DD',
                value: '$_resultLatDD, $_resultLonDD',
                colors: colors,
                onCopy: () =>
                    _copyResult('$_resultLatDD, $_resultLonDD', 'LAT/LON'),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'LAT/LON DMS',
                value: '$_resultLatDMS\n$_resultLonDMS',
                colors: colors,
                onCopy: () => _copyResult(
                    '$_resultLatDMS, $_resultLonDMS', 'DMS'),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'UTM',
                value: _resultUTM!,
                colors: colors,
                onCopy: () => _copyResult(_resultUTM!, 'UTM'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    switch (_format) {
      case _InputFormat.mgrs:
        return [
          _InputField(
            controller: _mgrsController,
            label: 'MGRS COORDINATE',
            hint: 'e.g., 18SUJ2337806446',
            colors: colors,
            onSubmitted: (_) => _convert(),
            isText: true,
          ),
        ];

      case _InputFormat.latLonDD:
        return [
          _InputField(
            controller: _latController,
            label: 'LATITUDE (decimal degrees)',
            hint: 'e.g., 38.8977',
            colors: colors,
            onSubmitted: (_) => _convert(),
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _lonController,
            label: 'LONGITUDE (decimal degrees)',
            hint: 'e.g., -77.0365',
            colors: colors,
            onSubmitted: (_) => _convert(),
          ),
        ];

      case _InputFormat.latLonDMS:
        return [
          _InputField(
            controller: _latDmsController,
            label: 'LATITUDE (DMS)',
            hint: 'e.g., N 38 53 51.7',
            colors: colors,
            onSubmitted: (_) => _convert(),
            isText: true,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _lonDmsController,
            label: 'LONGITUDE (DMS)',
            hint: 'e.g., W 77 02 11.4',
            colors: colors,
            onSubmitted: (_) => _convert(),
            isText: true,
          ),
        ];
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable input field
// ---------------------------------------------------------------------------

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.colors,
    this.onSubmitted,
    this.isText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TacticalColorScheme colors;
  final ValueChanged<String>? onSubmitted;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            keyboardType: isText
                ? TextInputType.text
                : const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
            textCapitalization:
                isText ? TextCapitalization.characters : TextCapitalization.none,
            style: TacticalTextStyles.value(colors),
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TacticalTextStyles.dim(colors),
              filled: true,
              fillColor: colors.card2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Result row with tap-to-copy
// ---------------------------------------------------------------------------

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.onCopy,
  });

  final String label;
  final String value;
  final TacticalColorScheme colors;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      onTap: onCopy,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TacticalTextStyles.label(colors)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TacticalTextStyles.value(colors),
                ),
              ],
            ),
          ),
          Icon(Icons.copy, color: colors.text3, size: 16),
        ],
      ),
    );
  }
}
