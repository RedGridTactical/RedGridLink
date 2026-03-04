import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/iap_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/iap/iap_service.dart';

/// Shows the paywall bottom sheet when a user taps a pro-gated feature.
///
/// [featureName] is displayed at the top so the user knows what they
/// tried to access.
void showPaywallSheet(BuildContext context, {String? featureName}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(featureName: featureName),
  );
}

class _PaywallSheet extends ConsumerWidget {
  const _PaywallSheet({this.featureName});

  final String? featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
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
                      if (featureName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          featureName!.toUpperCase(),
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

                      // --- Solo Plans ---
                      _SectionLabel(label: 'SOLO PLANS', colors: colors),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'PRO MONTHLY',
                        productId: IAPProducts.proMonthly,
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'PRO ANNUAL',
                        productId: IAPProducts.proAnnual,
                        isBestValue: true,
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),

                      const SizedBox(height: 16),

                      // --- Link Plans ---
                      _SectionLabel(label: 'LINK PLANS', colors: colors),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'PRO+LINK MONTHLY',
                        productId: IAPProducts.proLinkMonthly,
                        subtitle: '8 devices Field Link',
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'PRO+LINK ANNUAL',
                        productId: IAPProducts.proLinkAnnual,
                        subtitle: '8 devices Field Link',
                        isBestValue: true,
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'LIFETIME',
                        productId: IAPProducts.lifetime,
                        subtitle: 'Pro+Link forever, one-time purchase',
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),

                      const SizedBox(height: 16),

                      // --- Team ---
                      _SectionLabel(label: 'TEAM', colors: colors),
                      const SizedBox(height: 8),
                      _PricingCard(
                        title: 'TEAM ANNUAL',
                        productId: IAPProducts.teamAnnual,
                        subtitle: '8 seats included',
                        colors: colors,
                        ref: ref,
                        enabled: !isProcessing,
                      ),

                      const SizedBox(height: 20),

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
// Pricing card
// ---------------------------------------------------------------------------

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.productId,
    this.subtitle,
    this.isBestValue = false,
    required this.colors,
    required this.ref,
    this.enabled = true,
  });

  final String title;
  final String productId;
  final String? subtitle;
  final bool isBestValue;
  final TacticalColorScheme colors;
  final WidgetRef ref;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final service = ref.read(iapServiceProvider);
    final price = service.getPrice(productId);

    return GestureDetector(
      onTap: enabled
          ? () {
              tapMedium();
              ref.read(buyProductProvider(productId));
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBestValue ? colors.accent : colors.border,
              width: isBestValue ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
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
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.text3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
