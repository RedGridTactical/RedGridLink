import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/entitlement.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import 'paywall_sheet.dart';

/// Feature gate that hides Pro-only content behind an upgrade prompt.
///
/// If the current user has a 'pro', 'proLink', or 'team' entitlement the
/// [child] is rendered normally. Otherwise [lockedWidget] is shown, or a
/// default semi-transparent overlay with a lock icon and "PRO" badge.
///
/// When a free user taps the locked overlay, the [PaywallSheet] is shown
/// with [featureName] for context. If no [featureName] is provided,
/// a generic paywall is shown.
class ProGate extends ConsumerWidget {
  const ProGate({
    super.key,
    required this.child,
    this.lockedWidget,
    this.featureName,
  });

  final Widget child;
  final Widget? lockedWidget;

  /// Optional name of the feature being gated. Displayed in the paywall
  /// so the user knows what they tried to access.
  final String? featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    final bool isPro = entitlement == 'pro' ||
        entitlement == 'proLink' ||
        entitlement == 'team';

    if (isPro) return child;

    if (lockedWidget != null) return lockedWidget!;

    final colors = ref.watch(currentThemeProvider);
    return _DefaultLockedOverlay(
      colors: colors,
      featureName: featureName,
      child: child,
    );
  }
}

/// Feature gate specifically for Field Link features that require >2 devices.
///
/// Checks the [Entitlement.fullFieldLink] flag rather than just pro status.
/// This means 'pro' users (who only get 2 devices) will see the gate,
/// while 'proLink' and 'team' users pass through.
class FieldLinkGate extends ConsumerWidget {
  const FieldLinkGate({
    super.key,
    required this.child,
    this.lockedWidget,
    this.featureName,
  });

  final Widget child;
  final Widget? lockedWidget;

  /// Optional name of the feature being gated.
  final String? featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementName = ref.watch(entitlementProvider);
    final entitlement = _entitlementFromName(entitlementName);

    if (entitlement.fullFieldLink) return child;

    if (lockedWidget != null) return lockedWidget!;

    final colors = ref.watch(currentThemeProvider);
    return _DefaultLockedOverlay(
      colors: colors,
      featureName: featureName ?? 'Full Field Link',
      child: child,
    );
  }

  /// Convert an entitlement name string to the enum.
  Entitlement _entitlementFromName(String name) {
    switch (name) {
      case 'pro':
        return Entitlement.pro;
      case 'proLink':
        return Entitlement.proLink;
      case 'team':
        return Entitlement.team;
      default:
        return Entitlement.free;
    }
  }
}

class _DefaultLockedOverlay extends StatelessWidget {
  const _DefaultLockedOverlay({
    required this.colors,
    required this.child,
    this.featureName,
  });

  final TacticalColorScheme colors;
  final Widget child;
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        tapMedium();
        showPaywallSheet(context, featureName: featureName);
      },
      child: Stack(
        children: [
          // Dimmed child underneath.
          Opacity(opacity: 0.25, child: IgnorePointer(child: child)),

          // Overlay with lock and PRO badge.
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 32, color: colors.accent),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PRO',
                      style: TacticalTextStyles.buttonText(colors).copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
