import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/theme_provider.dart';

/// Terms of Use / EULA screen.
///
/// Displays the end-user terms of service covering app usage,
/// privacy, Field Link limitations, IAP terms, and liability.
class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          'TERMS OF USE',
          style: TacticalTextStyles.heading(colors),
        ),
        backgroundColor: colors.card,
        iconTheme: IconThemeData(color: colors.accent),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TermsSection(
              title: '1. Acceptance of Terms',
              body: 'By downloading, installing, or using Red Grid Link '
                  '("the App"), you agree to be bound by these Terms of '
                  'Use. If you do not agree to these terms, do not use '
                  'the App.',
              colors: colors,
            ),
            _TermsSection(
              title: '2. App Usage',
              body: 'Red Grid Link is designed for personal and team '
                  'coordination use in outdoor activities including '
                  'search & rescue, backcountry navigation, hunting, '
                  'and training exercises. The App is provided as a '
                  'coordination tool, not a safety device.\n\n'
                  'You may not use this App for any unlawful purpose '
                  'or in any way that could damage, disable, or impair '
                  'the App.',
              colors: colors,
            ),
            _TermsSection(
              title: '3. Privacy & Data',
              body: 'Red Grid Link is offline-first. No user data is '
                  'collected, transmitted to, or stored on any external '
                  'server. All position data, session data, and '
                  'configuration remain on your device.\n\n'
                  'Field Link peer-to-peer communication occurs directly '
                  'between devices via Bluetooth and WiFi Direct. '
                  'Position data shared during a session is encrypted '
                  'with AES-256 and is not retained after the session '
                  'ends on peer devices.',
              colors: colors,
            ),
            _TermsSection(
              title: '4. Field Link Limitations',
              body: 'The Field Link feature uses Bluetooth Low Energy '
                  'and WiFi Direct for peer-to-peer communication. '
                  'Actual range depends on terrain, vegetation, weather, '
                  'and device hardware.\n\n'
                  'Field Link is not a substitute for proper '
                  'communication equipment (radios, satellite '
                  'communicators). Do not rely on Field Link for '
                  'life-safety communications.',
              colors: colors,
            ),
            _TermsSection(
              title: '5. In-App Purchases',
              body: 'Certain features require a paid subscription or '
                  'one-time purchase. Subscriptions auto-renew unless '
                  'cancelled at least 24 hours before the end of the '
                  'current period.\n\n'
                  'Subscription management and cancellation are handled '
                  'through the Apple App Store or Google Play Store. '
                  'Refund policies are subject to the respective store '
                  'policies.',
              colors: colors,
            ),
            _TermsSection(
              title: '6. Disclaimer of Warranties',
              body: 'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES '
                  'OF ANY KIND. GPS accuracy, MGRS coordinate accuracy, '
                  'and connectivity are subject to device hardware, '
                  'environmental conditions, and other factors outside '
                  'our control.\n\n'
                  'We do not warrant that the App will be uninterrupted, '
                  'error-free, or that coordinates will be accurate to '
                  'any particular precision.',
              colors: colors,
            ),
            _TermsSection(
              title: '7. Limitation of Liability',
              body: 'TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE '
                  'DEVELOPERS SHALL NOT BE LIABLE FOR ANY INDIRECT, '
                  'INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES '
                  'ARISING FROM USE OF THE APP.\n\n'
                  'Always carry proper navigation equipment including '
                  'compass, paper maps, and backup communication devices.',
              colors: colors,
            ),
            _TermsSection(
              title: '8. Changes to Terms',
              body: 'We reserve the right to modify these terms at any '
                  'time. Continued use of the App after changes '
                  'constitutes acceptance of the new terms.',
              colors: colors,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last updated: March 2026',
                style: TacticalTextStyles.dim(colors),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.body,
    required this.colors,
  });

  final String title;
  final String body;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TacticalTextStyles.body(colors).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: TacticalTextStyles.dim(colors)),
        ],
      ),
    );
  }
}
