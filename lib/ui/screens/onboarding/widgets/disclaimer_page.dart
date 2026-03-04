import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_card.dart';

/// Onboarding page 2: Safety and range disclaimer.
///
/// The user must check the "I understand" checkbox before proceeding.
/// The parent [OnboardingScreen] reads [isAccepted] via [onAcceptChanged].
class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({
    super.key,
    required this.colors,
    required this.isAccepted,
    required this.onAcceptChanged,
  });

  final TacticalColorScheme colors;
  final bool isAccepted;
  final ValueChanged<bool> onAcceptChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Title
          Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'IMPORTANT',
              style: TacticalTextStyles.heading(colors),
            ),
          ),
          const SizedBox(height: 24),

          // Range disclaimer
          SectionHeader(title: 'Range & Limitations', colors: colors),
          const SizedBox(height: 12),
          TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(16),
            child: Text(
              AppConstants.rangeDisclaimer,
              style: TacticalTextStyles.body(colors),
            ),
          ),

          const SizedBox(height: 16),

          // Safety disclaimer
          SectionHeader(title: 'Safety Notice', colors: colors),
          const SizedBox(height: 12),
          TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app is a coordination tool, not a safety device.',
                  style: TacticalTextStyles.body(colors).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Always carry proper navigation equipment including a '
                  'map, compass, and GPS device. Do not rely solely on '
                  'this app for navigation or safety-critical decisions.',
                  style: TacticalTextStyles.body(colors),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bluetooth and WiFi Direct range varies significantly '
                  'based on terrain, vegetation, weather, and device '
                  'hardware. Positions may be delayed or unavailable.',
                  style: TacticalTextStyles.body(colors),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Acknowledgement checkbox
          GestureDetector(
            onTap: () {
              tapMedium();
              onAcceptChanged(!isAccepted);
            },
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppConstants.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isAccepted ? colors.accent : colors.border,
                        width: 2,
                      ),
                      color: isAccepted ? colors.accent : Colors.transparent,
                    ),
                    child: isAccepted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I understand the limitations and will carry '
                      'proper navigation equipment.',
                      style: TacticalTextStyles.body(colors).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
