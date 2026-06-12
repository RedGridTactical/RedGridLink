import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/iap_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/iap/iap_service.dart';
import '../../../services/stats/funnel_stats.dart';
import '../../screens/settings/widgets/privacy_screen.dart';
import '../../screens/settings/widgets/terms_screen.dart';
import 'tactical_button.dart';

/// Shows the paywall bottom sheet when a user taps a pro-gated feature.
///
/// [featureName] is displayed at the top so the user knows what they
/// tried to access.
void showPaywallSheet(BuildContext context, {String? featureName}) {
  // Local-only funnel counters — never leave the device.
  unawaited(FunnelStats.instance.increment('paywall_views'));
  if (featureName != null) {
    unawaited(
      FunnelStats.instance
          .increment('gate.${FunnelStats.keyFor(featureName)}'),
    );
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(featureName: featureName),
  );
}

class _PaywallSheet extends ConsumerStatefulWidget {
  const _PaywallSheet({this.featureName});

  final String? featureName;

  @override
  ConsumerState<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<_PaywallSheet> {
  /// Pro Annual is the default selection — recurring annual is the tier
  /// the pricing model is built around.
  String _selected = IAPProducts.proAnnual;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
    final iap = ref.read(iapServiceProvider);
    final isProcessing = purchaseState == PurchaseFlowState.purchasing ||
        purchaseState == PurchaseFlowState.restoring;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              // Drag handle.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable content.
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Lock icon.
                      Icon(Icons.lock_outline, size: 40, color: colors.accent),
                      const SizedBox(height: 12),

                      // Feature context.
                      Text(
                        'PRO FEATURE',
                        style: TacticalTextStyles.heading(colors),
                      ),
                      if (widget.featureName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.featureName!.toUpperCase(),
                          style: TacticalTextStyles.caption(colors),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Upgrade to unlock this feature and more.',
                        style: TacticalTextStyles.body(colors),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Feature comparison table.
                      _FeatureTable(colors: colors),

                      const SizedBox(height: 24),

                      // Purchase loading state.
                      if (isProcessing) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(colors.accent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                purchaseState == PurchaseFlowState.restoring
                                    ? 'RESTORING...'
                                    : 'PROCESSING...',
                                style: TacticalTextStyles.caption(colors),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // --- Solo Plans (annual featured + default) ---
                      _SectionLabel(label: 'SOLO PLANS', colors: colors),
                      const SizedBox(height: 8),
                      _PlanCard(
                        title: 'PRO ANNUAL',
                        subtitle: 'Save 37% vs monthly',
                        price: iap.getPrice(IAPProducts.proAnnual),
                        isBestValue: true,
                        selected: _selected == IAPProducts.proAnnual,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.proAnnual),
                      ),
                      const SizedBox(height: 8),
                      _PlanCard(
                        title: 'PRO MONTHLY',
                        price: iap.getPrice(IAPProducts.proMonthly),
                        selected: _selected == IAPProducts.proMonthly,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.proMonthly),
                      ),

                      const SizedBox(height: 16),

                      // --- Link Plans ---
                      _SectionLabel(label: 'LINK PLANS', colors: colors),
                      const SizedBox(height: 8),
                      _PlanCard(
                        title: 'PRO+LINK ANNUAL',
                        subtitle: '8 devices Field Link',
                        price: iap.getPrice(IAPProducts.proLinkAnnual),
                        selected: _selected == IAPProducts.proLinkAnnual,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.proLinkAnnual),
                      ),
                      const SizedBox(height: 8),
                      _PlanCard(
                        title: 'PRO+LINK MONTHLY',
                        subtitle: '8 devices Field Link',
                        price: iap.getPrice(IAPProducts.proLinkMonthly),
                        selected: _selected == IAPProducts.proLinkMonthly,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.proLinkMonthly),
                      ),

                      const SizedBox(height: 16),

                      // --- Team ---
                      _SectionLabel(label: 'TEAM', colors: colors),
                      const SizedBox(height: 8),
                      _PlanCard(
                        title: 'TEAM ANNUAL',
                        subtitle: '8 seats included',
                        price: iap.getPrice(IAPProducts.teamAnnual),
                        selected: _selected == IAPProducts.teamAnnual,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.teamAnnual),
                      ),

                      const SizedBox(height: 12),

                      // Lifetime stays available but unpromoted — a quiet
                      // one-time-purchase row, never a featured card.
                      _LifetimeRow(
                        price: iap.getPrice(IAPProducts.lifetime),
                        selected: _selected == IAPProducts.lifetime,
                        enabled: !isProcessing,
                        colors: colors,
                        onSelect: () => _select(IAPProducts.lifetime),
                      ),

                      const SizedBox(height: 16),

                      // Purchase CTA for the selected plan.
                      _buildCta(iap, colors, isProcessing),

                      const SizedBox(height: 16),

                      // Subscription auto-renewal disclosure.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'Subscriptions auto-renew unless cancelled at '
                          'least 24 hours before the end of the current '
                          'period. Your account will be charged for renewal '
                          'within 24 hours prior to the end of the current '
                          'period. Manage or cancel subscriptions in your '
                          'device\u2019s account settings.',
                          style: TacticalTextStyles.dim(colors).copyWith(
                            fontSize: 10,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Restore purchases link.
                      GestureDetector(
                        onTap: isProcessing
                            ? null
                            : () {
                                tapLight();
                                ref.read(iapServiceProvider).restorePurchases();
                              },
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: AppConstants.minTouchTarget,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'RESTORE PURCHASES',
                            style:
                                TacticalTextStyles.caption(colors).copyWith(
                              color: isProcessing
                                  ? colors.text4
                                  : colors.accent,
                            ),
                          ),
                        ),
                      ),

                      // Terms of Use & Privacy Policy links.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TermsScreen(),
                              ),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: AppConstants.minTouchTarget,
                              ),
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Terms of Use',
                                style: TacticalTextStyles.caption(colors)
                                    .copyWith(
                                  color: colors.accent,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colors.accent,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '\u2022',
                            style: TacticalTextStyles.dim(colors),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PrivacyScreen(),
                              ),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: AppConstants.minTouchTarget,
                              ),
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Privacy Policy',
                                style: TacticalTextStyles.caption(colors)
                                    .copyWith(
                                  color: colors.accent,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colors.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Close button.
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: AppConstants.minTouchTarget,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'CLOSE',
                            style: TacticalTextStyles.buttonText(colors),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _select(String productId) {
    if (_selected == productId) return;
    tapLight();
    setState(() => _selected = productId);
  }

  /// CTA button + terms caption for the currently selected plan.
  ///
  /// Shows trial copy when the store (Android) or the declared ASC
  /// configuration (iOS / StoreKit 2) reports an introductory free trial.
  Widget _buildCta(
    IAPService iap,
    TacticalColorScheme colors,
    bool isProcessing,
  ) {
    final trial = iap.trialInfo(_selected);
    final price = iap.getPrice(_selected);
    final isLifetime = _selected == IAPProducts.lifetime;

    final label = trial != null
        ? 'START ${trial.days}-DAY FREE TRIAL'
        : (isLifetime ? 'BUY LIFETIME' : 'SUBSCRIBE');
    final caption = trial != null
        ? 'then $price · cancel anytime · trial for new subscribers'
        : (isLifetime ? '$price · one-time purchase' : '$price · cancel anytime');

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TacticalButton(
            label: label,
            icon: isLifetime ? Icons.workspace_premium : Icons.lock_open,
            colors: colors,
            onPressed: isProcessing
                ? null
                : () {
                    tapMedium();
                    unawaited(
                      FunnelStats.instance.increment(
                        trial != null
                            ? 'trial_cta.$_selected'
                            : 'buy_cta.$_selected',
                      ),
                    );
                    ref.read(buyProductProvider(_selected));
                  },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: TacticalTextStyles.dim(colors).copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colors});

  final String label;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: TacticalTextStyles.label(colors).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature comparison table
// ---------------------------------------------------------------------------

class _FeatureTable extends StatelessWidget {
  const _FeatureTable({required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row.
          _TableRow(
            feature: '',
            free: 'FREE',
            pro: 'PRO',
            proLink: 'PRO+LINK',
            team: 'TEAM',
            isHeader: true,
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Field Link devices',
            free: '2',
            pro: '2',
            proLink: '8',
            team: '8',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Operational modes',
            free: 'All 4',
            pro: 'All 4',
            proLink: 'All 4',
            team: 'All 4',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'AAR export',
            free: '--',
            pro: 'Yes',
            proLink: 'Yes',
            team: 'Yes',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Map regions',
            free: '1',
            pro: 'All',
            proLink: 'All',
            team: 'All',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Themes',
            free: 'Red',
            pro: 'All 4',
            proLink: 'All 4',
            team: 'All 4',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Team seats',
            free: '--',
            pro: '--',
            proLink: '--',
            team: '8',
            colors: colors,
          ),
          Divider(color: colors.border2, height: 1, thickness: 1),

          _TableRow(
            feature: 'Branded AARs',
            free: '--',
            pro: '--',
            proLink: '--',
            team: 'Yes',
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.feature,
    required this.free,
    required this.pro,
    required this.proLink,
    required this.team,
    this.isHeader = false,
    required this.colors,
  });

  final String feature;
  final String free;
  final String pro;
  final String proLink;
  final String team;
  final bool isHeader;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? TacticalTextStyles.label(colors).copyWith(
            fontWeight: FontWeight.bold,
          )
        : TacticalTextStyles.dim(colors);

    final valueStyle = isHeader
        ? TacticalTextStyles.label(colors).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 9,
          )
        : TacticalTextStyles.caption(colors);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: style)),
          Expanded(
            flex: 1,
            child: Text(free, style: valueStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text(
              pro,
              style: valueStyle.copyWith(
                color: isHeader ? null : colors.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              proLink,
              style: valueStyle.copyWith(
                color: isHeader ? null : colors.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              team,
              style: valueStyle.copyWith(
                color: isHeader ? null : colors.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card (selectable)
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    this.subtitle,
    this.isBestValue = false,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.onSelect,
  });

  final String title;
  final String price;
  final String? subtitle;
  final bool isBestValue;
  final bool selected;
  final bool enabled;
  final TacticalColorScheme colors;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onSelect : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected ? colors.accent : colors.text3,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TacticalTextStyles.subheading(colors),
                          ),
                        ),
                        if (isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TacticalTextStyles.dim(colors)),
                    ],
                  ],
                ),
              ),
              Text(
                price,
                style: TacticalTextStyles.body(colors).copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lifetime row (available, unpromoted)
// ---------------------------------------------------------------------------

class _LifetimeRow extends StatelessWidget {
  const _LifetimeRow({
    required this.price,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.onSelect,
  });

  final String price;
  final bool selected;
  final bool enabled;
  final TacticalColorScheme colors;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onSelect : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colors.accent : colors.border2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 16,
                color: selected ? colors.accent : colors.text4,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LIFETIME — Pro+Link, one-time purchase',
                  style: TacticalTextStyles.dim(colors),
                ),
              ),
              Text(
                price,
                style: TacticalTextStyles.caption(colors).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
