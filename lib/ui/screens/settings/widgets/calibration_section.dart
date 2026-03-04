import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_card.dart';

/// Navigation calibration section for settings.
///
/// Contains inputs for magnetic declination, pace count, and default speed.
/// Each value persists immediately via the corresponding settings provider.
class CalibrationSection extends ConsumerStatefulWidget {
  const CalibrationSection({super.key});

  @override
  ConsumerState<CalibrationSection> createState() => _CalibrationSectionState();
}

class _CalibrationSectionState extends ConsumerState<CalibrationSection> {
  late TextEditingController _declinationController;
  late TextEditingController _paceCountController;

  @override
  void initState() {
    super.initState();
    final declination = ref.read(declinationProvider);
    final paceCount = ref.read(paceCountProvider);
    _declinationController = TextEditingController(
      text: declination.toStringAsFixed(1),
    );
    _paceCountController = TextEditingController(
      text: paceCount.toString(),
    );
  }

  @override
  void dispose() {
    _declinationController.dispose();
    _paceCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final declination = ref.watch(declinationProvider);
    final paceCount = ref.watch(paceCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Navigation', colors: colors),
        const SizedBox(height: 12),

        // --- Declination ---
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAGNETIC DECLINATION', style: TacticalTextStyles.label(colors)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    colors: colors,
                    onPressed: () {
                      final newVal = declination - 0.5;
                      if (newVal >= -30) {
                        ref.read(declinationProvider.notifier).set(newVal);
                        _declinationController.text = newVal.toStringAsFixed(1);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _declinationController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TacticalTextStyles.value(colors),
                      decoration: InputDecoration(
                        suffixText: '\u00B0',
                        suffixStyle: TacticalTextStyles.value(colors),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed >= -30 && parsed <= 30) {
                          ref.read(declinationProvider.notifier).set(parsed);
                        } else {
                          _declinationController.text =
                              declination.toStringAsFixed(1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StepButton(
                    icon: Icons.add,
                    colors: colors,
                    onPressed: () {
                      final newVal = declination + 0.5;
                      if (newVal <= 30) {
                        ref.read(declinationProvider.notifier).set(newVal);
                        _declinationController.text = newVal.toStringAsFixed(1);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                declination >= 0 ? 'EAST DECLINATION' : 'WEST DECLINATION',
                style: TacticalTextStyles.dim(colors),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- Pace Count ---
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PACE COUNT', style: TacticalTextStyles.label(colors)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    colors: colors,
                    onPressed: () {
                      final newVal = paceCount - 1;
                      if (newVal >= 30) {
                        ref.read(paceCountProvider.notifier).set(newVal);
                        _paceCountController.text = newVal.toString();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paceCountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TacticalTextStyles.value(colors),
                      decoration: InputDecoration(
                        suffixText: 'steps/100m',
                        suffixStyle: TacticalTextStyles.caption(colors),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed >= 30 && parsed <= 120) {
                          ref.read(paceCountProvider.notifier).set(parsed);
                        } else {
                          _paceCountController.text = paceCount.toString();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StepButton(
                    icon: Icons.add,
                    colors: colors,
                    onPressed: () {
                      final newVal = paceCount + 1;
                      if (newVal <= 120) {
                        ref.read(paceCountProvider.notifier).set(newVal);
                        _paceCountController.text = newVal.toString();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Steps per 100 meters on flat terrain. '
                'Default: ${AppConstants.defaultPaceCount}.',
                style: TacticalTextStyles.dim(colors),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small +/- step button that meets the 44px touch target.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final IconData icon;
  final TacticalColorScheme colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppConstants.minTouchTarget,
      height: AppConstants.minTouchTarget,
      child: Material(
        color: colors.card2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            tapLight();
            onPressed();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
        ),
      ),
    );
  }
}
