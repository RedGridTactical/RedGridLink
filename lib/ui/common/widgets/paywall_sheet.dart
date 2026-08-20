import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/theme_provider.dart';
import 'tactical_button.dart';

/// SUNSET (v1.7.0, final release).
///
/// Red Grid Link no longer sells anything: every entry point that used to
/// open the paywall now opens this notice instead, and every install is
/// elevated to full `proLink` entitlement (see `entitlementProvider`).
/// Keeping the old `showPaywallSheet` signature means none of the callers
/// (pro_gate, onboarding, theme selector, map download sheet, report
/// screen, field link screen) had to change: a tap on any former upsell
/// surface tells the user where the product went.
///
/// The store links point at Red Grid MGRS, which carries the merged
/// mission forward. Deliberately NOT localized: this is the terminal
/// build of a frozen codebase and the message must never drift.
void showPaywallSheet(BuildContext context, {String? featureName}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SunsetSheet(),
  );
}

class SunsetSheet extends ConsumerWidget {
  const SunsetSheet({super.key});

  static final Uri _iosStore =
      Uri.parse('https://apps.apple.com/app/id6759629554');
  static final Uri _androidStore = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.redgrid.redgridtactical');

  Future<void> _openMgrs(BuildContext context) async {
    tapMedium();
    final uri = Theme.of(context).platform == TargetPlatform.iOS
        ? _iosStore
        : _androidStore;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.merge_type, size: 40, color: colors.accent),
          const SizedBox(height: 12),
          Text(
            'NOW PART OF RED GRID MGRS',
            style: TacticalTextStyles.heading(colors),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Red Grid Link's mission continues inside Red Grid MGRS: "
            'DAGR-grade land navigation with encrypted team awareness '
            'on one offline map. New features ship there.',
            style: TacticalTextStyles.body(colors),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Link stays on your device and keeps working, but will no '
            'longer receive updates. Every Pro feature in this app is '
            'now unlocked, free.',
            style: TacticalTextStyles.body(colors),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TacticalButton(
              label: 'GET RED GRID MGRS',
              colors: colors,
              onPressed: () => _openMgrs(context),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              tapLight();
              Navigator.of(context).pop();
            },
            child: Text(
              'CONTINUE',
              style: TacticalTextStyles.caption(colors),
            ),
          ),
        ],
      ),
    );
  }
}
