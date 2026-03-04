import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// Time-Distance-Speed three-way calculator.
///
/// Enter any 2, compute the 3rd.
class TdsTool extends StatefulWidget {
  const TdsTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  State<TdsTool> createState() => _TdsToolState();
}

class _TdsToolState extends State<TdsTool> {
  final _distanceController = TextEditingController();
  final _speedController = TextEditingController();
  final _timeController = TextEditingController();

  String? _resultLabel;
  String? _resultValue;
  String? _error;

  TacticalColorScheme get colors => widget.colors;

  @override
  void dispose() {
    _distanceController.dispose();
    _speedController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _calcTime() {
    tapMedium();
    final dist = double.tryParse(_distanceController.text);
    final speed = double.tryParse(_speedController.text);
    if (dist == null || dist <= 0) {
      setState(() {
        _error = 'Enter a valid distance';
        _resultLabel = null;
      });
      return;
    }
    if (speed == null || speed <= 0) {
      setState(() {
        _error = 'Enter a valid speed';
        _resultLabel = null;
      });
      return;
    }
    final mins = timeToTravel(dist, speed);
    setState(() {
      _resultLabel = 'TIME';
      _resultValue = formatMinutes(mins);
      _error = null;
    });
    notifySuccess();
  }

  void _calcSpeed() {
    tapMedium();
    final dist = double.tryParse(_distanceController.text);
    final timeMin = double.tryParse(_timeController.text);
    if (dist == null || dist <= 0) {
      setState(() {
        _error = 'Enter a valid distance';
        _resultLabel = null;
      });
      return;
    }
    if (timeMin == null || timeMin <= 0) {
      setState(() {
        _error = 'Enter a valid time';
        _resultLabel = null;
      });
      return;
    }
    // speed = distance / time, convert to km/h
    final speedKmh = (dist / 1000) / (timeMin / 60);
    setState(() {
      _resultLabel = 'SPEED';
      _resultValue = '${speedKmh.toStringAsFixed(1)} km/h';
      _error = null;
    });
    notifySuccess();
  }

  void _calcDistance() {
    tapMedium();
    final speed = double.tryParse(_speedController.text);
    final timeMin = double.tryParse(_timeController.text);
    if (speed == null || speed <= 0) {
      setState(() {
        _error = 'Enter a valid speed';
        _resultLabel = null;
      });
      return;
    }
    if (timeMin == null || timeMin <= 0) {
      setState(() {
        _error = 'Enter a valid time';
        _resultLabel = null;
      });
      return;
    }
    // distance = speed * time
    final distM = speed * (timeMin / 60) * 1000;
    setState(() {
      _resultLabel = 'DISTANCE';
      _resultValue =
          '${distM.toStringAsFixed(0)}m (${(distM / 1000).toStringAsFixed(2)}km)';
      _error = null;
    });
    notifySuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('TIME-DISTANCE-SPEED',
            style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Enter any 2 values', colors: colors),
            const SizedBox(height: 12),

            // Distance
            _TdsField(
              controller: _distanceController,
              label: 'DISTANCE (meters)',
              hint: 'e.g. 5000',
              colors: colors,
            ),
            const SizedBox(height: 12),

            // Speed
            _TdsField(
              controller: _speedController,
              label: 'SPEED (km/h)',
              hint: 'e.g. 5.0',
              colors: colors,
            ),
            const SizedBox(height: 12),

            // Time
            _TdsField(
              controller: _timeController,
              label: 'TIME (minutes)',
              hint: 'e.g. 60',
              colors: colors,
            ),
            const SizedBox(height: 20),

            // Calculate buttons
            SectionHeader(title: 'Calculate', colors: colors),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TacticalButton(
                    label: 'Time',
                    icon: Icons.timer,
                    colors: colors,
                    isCompact: true,
                    onPressed: _calcTime,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TacticalButton(
                    label: 'Speed',
                    icon: Icons.speed,
                    colors: colors,
                    isCompact: true,
                    onPressed: _calcSpeed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TacticalButton(
                    label: 'Dist',
                    icon: Icons.straighten,
                    colors: colors,
                    isCompact: true,
                    onPressed: _calcDistance,
                  ),
                ),
              ],
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

            if (_resultLabel != null && _resultValue != null) ...[
              const SizedBox(height: 20),
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _resultValue!));
                  notifySuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('COPIED',
                          style: TacticalTextStyles.caption(colors)
                              .copyWith(color: Colors.white)),
                      backgroundColor: colors.accent,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_resultLabel!,
                        style: TacticalTextStyles.label(colors)),
                    const SizedBox(height: 4),
                    Text(
                      _resultValue!,
                      style: TacticalTextStyles.bearingDisplay(colors),
                    ),
                    const SizedBox(height: 4),
                    Text('Tap to copy',
                        style: TacticalTextStyles.dim(colors)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TdsField extends StatelessWidget {
  const _TdsField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.colors,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TacticalColorScheme colors;

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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TacticalTextStyles.value(colors),
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
