import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../providers/iap_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/iap/iap_service.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Settings subscription management section.
///
/// Shows the current entitlement tier and provides upgrade options
/// for free users, or subscription details for pro/proLink/team users.
class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final entitlement = ref.watch(entitlementProvider);
    final purchaseState = ref.watch(purchaseStateProvider);
    final purchaseError = ref.watch(purchaseErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Subscription', colors: colors),
        const SizedBox(height: 12),

        // Current tier display.
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT TIER', style: TacticalTextStyles.label(colors)),
              _TierBadge(
                tier: _displayTierName(entitlement),
                colors: colors,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Error banner.
        if (purchaseError != null) ...[
          _ErrorBanner(message: purchaseError, colors: colors, ref: ref),
          const SizedBox(height: 12),
        ],

        // Loading state during purchase.
        if (purchaseState == PurchaseFlowState.purchasing ||
            purchaseState == PurchaseFlowState.restoring) ...[
          _PurchaseLoadingIndicator(
            state: purchaseState,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],

        // Success state.
        if (purchaseState == PurchaseFlowState.success) ...[
          _SuccessBanner(colors: colors),
          const SizedBox(height: 12),
        ],

        // Show upgrade cards if free.
        if (entitlement == 'free') ...[
          _UpgradeCards(colors: colors, ref: ref),
        ],

        // Show active subscription details if pro, proLink, or team.
        if (entitlement == 'pro' ||
            entitlement == 'proLink' ||
            entitlement == 'team') ...[
          _ActiveSubscriptionCard(
            entitlement: entitlement,
            colors: colors,
          ),
        ],

        const SizedBox(height: 12),

        // Restore purchases button.
        _RestoreButton(colors: colors, ref: ref),
      ],
    );
  }

  /// Convert the raw entitlement string to a display name.
  String _displayTierName(String entitlement) {
    switch (entitlement) {
      case 'proLink':
        return 'PRO+LINK';
      default:
        return entitlement.toUpperCase();
    }
  }
}

// ---------------------------------------------------------------------------
// Tier badge
// ---------------------------------------------------------------------------

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.colors});

  final String tier;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bool isFree = tier == 'FREE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFree ? colors.card2 : colors.accent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFree ? colors.border : colors.accent,
        ),
      ),
      child: Text(
        tier,
        style: TacticalTextStyles.buttonText(colors).copyWith(
          color: isFree ? colors.text2 : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upgrade cards (for free users)
// ---------------------------------------------------------------------------

class _UpgradeCards extends StatelessWidget {
  const _UpgradeCards({required this.colors, required this.ref});

  final TacticalColorScheme colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        final service = ref.read(iapServiceProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Solo Plans ---
            _SectionLabel(label: 'SOLO PLANS', colors: colors),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'PRO MONTHLY',
              price: service.getPrice(IAPProducts.proMonthly),
              description: 'All themes, unlimited maps, AAR export. '
                  '2-device Field Link.',
              productId: IAPProducts.proMonthly,
              colors: colors,
              ref: ref,
            ),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'PRO ANNUAL',
              price: service.getPrice(IAPProducts.proAnnual),
              description: 'Same as Pro Monthly. Save with annual billing.',
              productId: IAPProducts.proAnnual,
              isBestValue: true,
              colors: colors,
              ref: ref,
            ),

            const SizedBox(height: 16),

            // --- Link Plans ---
            _SectionLabel(label: 'LINK PLANS', colors: colors),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'PRO+LINK MONTHLY',
              price: service.getPrice(IAPProducts.proLinkMonthly),
              description: 'Full Field Link (8 devices), all Pro features.',
              productId: IAPProducts.proLinkMonthly,
              colors: colors,
              ref: ref,
            ),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'PRO+LINK ANNUAL',
              price: service.getPrice(IAPProducts.proLinkAnnual),
              description: 'Same as Pro+Link Monthly. Save with annual billing.',
              productId: IAPProducts.proLinkAnnual,
              isBestValue: true,
              colors: colors,
              ref: ref,
            ),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'LIFETIME',
              price: service.getPrice(IAPProducts.lifetime),
              description: 'Pro+Link forever. One-time purchase, never expires.',
              productId: IAPProducts.lifetime,
              colors: colors,
              ref: ref,
            ),

            const SizedBox(height: 16),

            // --- Team ---
            _SectionLabel(label: 'TEAM', colors: colors),
            const SizedBox(height: 8),
            _SubscriptionCard(
              title: 'TEAM ANNUAL',
              price: service.getPrice(IAPProducts.teamAnnual),
              description: 'Pro+Link for your whole team (8 seats). '
                  'Branded AARs and priority support.',
              productId: IAPProducts.teamAnnual,
              colors: colors,
              ref: ref,
            ),
          ],
        );
      },
      loading: () => TacticalCard(
        colors: colors,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'LOADING SUBSCRIPTIONS...',
                style: TacticalTextStyles.caption(colors),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => TacticalCard(
        colors: colors,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COULD NOT LOAD SUBSCRIPTIONS',
              style: TacticalTextStyles.caption(colors).copyWith(
                color: const Color(0xFFCC0000),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TacticalTextStyles.dim(colors),
            ),
            const SizedBox(height: 8),
            TacticalButton(
              label: 'Retry',
              icon: Icons.refresh,
              isCompact: true,
              colors: colors,
              onPressed: () => ref.invalidate(productsProvider),
            ),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: TacticalTextStyles.label(colors).copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription card
// ---------------------------------------------------------------------------

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.title,
    required this.price,
    required this.description,
    required this.productId,
    this.isBestValue = false,
    required this.colors,
    required this.ref,
  });

  final String title;
  final String price;
  final String description;
  final String productId;
  final bool isBestValue;
  final TacticalColorScheme colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          Text(description, style: TacticalTextStyles.dim(colors)),
          const SizedBox(height: 12),
          TacticalButton(
            label: productId == IAPProducts.lifetime ? 'Buy' : 'Subscribe',
            icon: Icons.star,
            colors: colors,
            onPressed: () {
              tapMedium();
              ref.read(buyProductProvider(productId));
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active subscription card
// ---------------------------------------------------------------------------

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({
    required this.entitlement,
    required this.colors,
  });

  final String entitlement;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final displayTier = entitlement == 'proLink'
        ? 'PRO+LINK'
        : entitlement.toUpperCase();

    final maxDevices = (entitlement == 'proLink' || entitlement == 'team')
        ? '8 max'
        : '2 max';

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'ACTIVE SUBSCRIPTION',
                style: TacticalTextStyles.subheading(colors),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'TIER',
            value: displayTier,
            colors: colors,
          ),
          const SizedBox(height: 4),
          _DetailRow(
            label: 'DEVICES',
            value: maxDevices,
            colors: colors,
          ),
          const SizedBox(height: 4),
          _DetailRow(
            label: 'FEATURES',
            value: 'All unlocked',
            colors: colors,
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your subscription through the app store.',
            style: TacticalTextStyles.dim(colors),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        Text(value, style: TacticalTextStyles.body(colors)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading indicator
// ---------------------------------------------------------------------------

class _PurchaseLoadingIndicator extends StatelessWidget {
  const _PurchaseLoadingIndicator({
    required this.state,
    required this.colors,
  });

  final PurchaseFlowState state;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final label = state == PurchaseFlowState.restoring
        ? 'RESTORING PURCHASES...'
        : 'PROCESSING PURCHASE...';

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: TacticalTextStyles.caption(colors)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success banner
// ---------------------------------------------------------------------------

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Purchase successful! Features unlocked.',
              style: TacticalTextStyles.body(colors),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.colors,
    required this.ref,
  });

  final String message;
  final TacticalColorScheme colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFCC0000), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TacticalTextStyles.caption(colors).copyWith(
                color: const Color(0xFFCC0000),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(purchaseErrorProvider.notifier).clear(),
            child: SizedBox(
              width: AppConstants.minTouchTarget,
              height: AppConstants.minTouchTarget,
              child: Icon(Icons.close, color: colors.text3, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Restore button
// ---------------------------------------------------------------------------

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.colors, required this.ref});

  final TacticalColorScheme colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
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
            style: TacticalTextStyles.caption(colors).copyWith(
              color: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
