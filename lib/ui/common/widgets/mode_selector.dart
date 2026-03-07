import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/entitlement.dart';
import '../../../data/models/operational_mode.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';

/// Horizontal row of operational-mode chips.
///
/// The selected mode is highlighted with the accent colour. Pro-only modes
/// display a lock icon for free-tier users.
class ModeSelector extends ConsumerWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final currentMode = ref.watch(operationalModeProvider);
    final entitlementName = ref.watch(entitlementProvider);
    final entitlement = Entitlement.values.firstWhere(
      (e) => e.name == entitlementName,
      orElse: () => Entitlement.free,
    );
    final bool isPro = entitlement.allModes;

    return SizedBox(
      height: AppConstants.minTouchTarget,
      child: Row(
        children: OperationalMode.values.map((mode) {
          final bool isSelected = mode.id == currentMode;
          // SAR and BACKCOUNTRY are free; HUNTING and TRAINING require Pro.
          final bool requiresPro =
              !isPro && (mode == OperationalMode.hunting ||
                         mode == OperationalMode.training);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _ModeChip(
                mode: mode,
                isSelected: isSelected,
                isLocked: requiresPro,
                colors: colors,
                onTap: () {
                  if (requiresPro) {
                    tapLight();
                    return;
                  }
                  tapMedium();
                  ref.read(operationalModeProvider.notifier).set(mode.id);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.isSelected,
    required this.isLocked,
    required this.colors,
    required this.onTap,
  });

  final OperationalMode mode;
  final bool isSelected;
  final bool isLocked;
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors.accent : colors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accent : colors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                Icon(Icons.lock_outline, size: 12, color: colors.text3),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  mode.label,
                  style: TacticalTextStyles.caption(colors).copyWith(
                    color: isSelected ? Colors.white : colors.text2,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
