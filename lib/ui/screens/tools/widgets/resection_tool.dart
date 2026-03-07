import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../core/utils/tactical.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../../../../data/models/waypoint.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// Two-point resection calculator.
///
/// Input: 2 known points (MGRS) + bearing from your position to each.
/// Calculates position via [resection].
class ResectionTool extends ConsumerStatefulWidget {
  const ResectionTool({super.key});

  @override
  ConsumerState<ResectionTool> createState() => _ResectionToolState();
}

class _ResectionToolState extends ConsumerState<ResectionTool> {
  final _mgrs1Controller = TextEditingController();
  final _bearing1Controller = TextEditingController();
  final _mgrs2Controller = TextEditingController();
  final _bearing2Controller = TextEditingController();

  ({double lat, double lon, String mgrs, String mgrsFormatted})? _result;
  String? _error;

  @override
  void dispose() {
    _mgrs1Controller.dispose();
    _bearing1Controller.dispose();
    _mgrs2Controller.dispose();
    _bearing2Controller.dispose();
    super.dispose();
  }

  void _calculate() {
    tapMedium();

    final point1 = parseMGRSToLatLon(_mgrs1Controller.text);
    final point2 = parseMGRSToLatLon(_mgrs2Controller.text);
    final bearing1 = double.tryParse(_bearing1Controller.text);
    final bearing2 = double.tryParse(_bearing2Controller.text);

    if (point1 == null) {
      setState(() {
        _error = 'Invalid MGRS for Point 1';
        _result = null;
      });
      return;
    }
    if (point2 == null) {
      setState(() {
        _error = 'Invalid MGRS for Point 2';
        _result = null;
      });
      return;
    }
    if (bearing1 == null || bearing1 < 0 || bearing1 > 360) {
      setState(() {
        _error = 'Enter a valid bearing to Point 1 (0-360)';
        _result = null;
      });
      return;
    }
    if (bearing2 == null || bearing2 < 0 || bearing2 > 360) {
      setState(() {
        _error = 'Enter a valid bearing to Point 2 (0-360)';
        _result = null;
      });
      return;
    }

    // resection expects bearings FROM the known points TO the unknown position.
    // The user provides bearings FROM their position TO the known points,
    // so we need the back azimuths.
    final backBearing1 = backAzimuth(bearing1);
    final backBearing2 = backAzimuth(bearing2);

    final result = resection(
      point1.lat,
      point1.lon,
      backBearing1,
      point2.lat,
      point2.lon,
      backBearing2,
    );

    if (result == null) {
      setState(() {
        _error = 'Lines are parallel or coincident -- cannot resolve position';
        _result = null;
      });
      return;
    }

    setState(() {
      _result = result;
      _error = null;
    });
    notifySuccess();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('RESECTION', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Point 1', colors: colors),
            const SizedBox(height: 8),
            _ResectionTextField(
              controller: _mgrs1Controller,
              label: 'MGRS (e.g. 18SUJ2345067890)',
              colors: colors,
              isNumeric: false,
            ),
            const SizedBox(height: 8),
            _ResectionTextField(
              controller: _bearing1Controller,
              label: 'BEARING TO POINT 1 (degrees)',
              colors: colors,
            ),

            const SizedBox(height: 16),
            SectionHeader(title: 'Point 2', colors: colors),
            const SizedBox(height: 8),
            _ResectionTextField(
              controller: _mgrs2Controller,
              label: 'MGRS (e.g. 18SUJ3456078901)',
              colors: colors,
              isNumeric: false,
            ),
            const SizedBox(height: 8),
            _ResectionTextField(
              controller: _bearing2Controller,
              label: 'BEARING TO POINT 2 (degrees)',
              colors: colors,
            ),

            const SizedBox(height: 16),
            TacticalButton(
              label: 'Calculate Position',
              icon: Icons.calculate,
              colors: colors,
              onPressed: _calculate,
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

            if (_result != null) ...[
              const SizedBox(height: 20),
              SectionHeader(title: 'Computed Position', colors: colors),
              const SizedBox(height: 12),
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR POSITION (MGRS)',
                        style: TacticalTextStyles.label(colors)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _result!.mgrsFormatted));
                        notifySuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('MGRS COPIED',
                                style: TacticalTextStyles.caption(colors)
                                    .copyWith(color: Colors.white)),
                            backgroundColor: colors.accent,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        _result!.mgrsFormatted,
                        style: TacticalTextStyles.mgrsDisplay(colors),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('LAT/LON', style: TacticalTextStyles.label(colors)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                '${_result!.lat.toStringAsFixed(6)}, ${_result!.lon.toStringAsFixed(6)}'));
                        notifySuccess();
                      },
                      child: Text(
                        '${_result!.lat.toStringAsFixed(6)}, ${_result!.lon.toStringAsFixed(6)}',
                        style: TacticalTextStyles.body(colors),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TacticalButton(
                label: 'Set as Waypoint',
                icon: Icons.add_location_alt,
                colors: colors,
                onPressed: () {
                  tapMedium();
                  ref.read(activeWaypointProvider.notifier).state = Waypoint(
                        id: generateDeviceId(),
                        name: 'Resection',
                        lat: _result!.lat,
                        lon: _result!.lon,
                        mgrs: _result!.mgrs,
                        mgrsFormatted: _result!.mgrsFormatted,
                        createdAt: DateTime.now(),
                      );
                  notifySuccess();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResectionTextField extends StatelessWidget {
  const _ResectionTextField({
    required this.controller,
    required this.label,
    required this.colors,
    this.isNumeric = true,
  });

  final TextEditingController controller;
  final String label;
  final TacticalColorScheme colors;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textCapitalization:
            isNumeric ? TextCapitalization.none : TextCapitalization.characters,
        style: TacticalTextStyles.value(colors).copyWith(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TacticalTextStyles.label(colors),
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
    );
  }
}
