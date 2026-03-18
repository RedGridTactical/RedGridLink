import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/theme_provider.dart';

/// Privacy Policy screen.
///
/// Displays the full privacy policy covering data collection,
/// Field Link peer-to-peer data handling, analytics, and user rights.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          'PRIVACY POLICY',
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
            _PolicySection(
              title: '1. Overview',
              body: 'Red Grid Link ("the App") is built with a privacy-first, '
                  'offline-first architecture. We do not collect, transmit, or '
                  'store any personal data on external servers. Your location '
                  'data, session history, waypoints, and configuration remain '
                  'entirely on your device.',
              colors: colors,
            ),
            _PolicySection(
              title: '2. Data We Do Not Collect',
              body: 'We do not collect:\n\n'
                  '\u2022 GPS or location data\n'
                  '\u2022 Personal information (name, email, phone)\n'
                  '\u2022 Device identifiers for tracking\n'
                  '\u2022 Usage analytics or behavioral data\n'
                  '\u2022 Contacts, photos, or other device content\n\n'
                  'The App has no user accounts, no login, and no cloud sync.',
              colors: colors,
            ),
            _PolicySection(
              title: '3. Field Link Peer-to-Peer Data',
              body: 'When you use the Field Link feature, position data is '
                  'shared directly between nearby devices via Bluetooth Low '
                  'Energy and WiFi Direct. This data:\n\n'
                  '\u2022 Is encrypted with AES-256-GCM\n'
                  '\u2022 Travels only between devices in the same session\n'
                  '\u2022 Is never sent to any server\n'
                  '\u2022 Is not retained on peer devices after the session ends\n\n'
                  'Session keys are generated via ECDH P-256 key exchange and '
                  'are ephemeral — they exist only for the duration of a session.',
              colors: colors,
            ),
            _PolicySection(
              title: '4. Local Storage',
              body: 'The App stores the following data locally on your device:\n\n'
                  '\u2022 App settings and preferences\n'
                  '\u2022 Saved waypoints\n'
                  '\u2022 Session history\n'
                  '\u2022 Downloaded offline map tiles\n'
                  '\u2022 Subscription entitlement status\n\n'
                  'All local data can be cleared by uninstalling the App.',
              colors: colors,
            ),
            _PolicySection(
              title: '5. Crash Reporting',
              body: 'In release builds, the App uses Sentry for crash '
                  'reporting to help us fix bugs. Crash reports:\n\n'
                  '\u2022 Do not include location data (stripped before sending)\n'
                  '\u2022 Do not include personal information\n'
                  '\u2022 Contain only technical stack traces and device model info\n'
                  '\u2022 Are used solely for stability improvements',
              colors: colors,
            ),
            _PolicySection(
              title: '6. In-App Purchases',
              body: 'Subscription and purchase transactions are processed '
                  'entirely by the Apple App Store or Google Play Store. We do '
                  'not have access to your payment information. Subscription '
                  'management is handled through your store account settings.',
              colors: colors,
            ),
            _PolicySection(
              title: '7. Third-Party Services',
              body: 'The App uses OpenStreetMap and OpenTopoMap for map tiles '
                  'when in online mode. These services may log standard HTTP '
                  'request data (IP address, tile coordinates). Offline map '
                  'tiles, once downloaded, require no network connection.\n\n'
                  'We do not embed any third-party advertising, analytics, or '
                  'social media SDKs.',
              colors: colors,
            ),
            _PolicySection(
              title: '8. Children\'s Privacy',
              body: 'The App is not directed at children under 13. We do not '
                  'knowingly collect any information from children.',
              colors: colors,
            ),
            _PolicySection(
              title: '9. Changes to This Policy',
              body: 'We may update this Privacy Policy from time to time. '
                  'Changes will be reflected in the App with an updated date. '
                  'Continued use of the App after changes constitutes '
                  'acceptance of the revised policy.',
              colors: colors,
            ),
            _PolicySection(
              title: '10. Contact',
              body: 'If you have questions about this Privacy Policy, '
                  'contact us at support@redgridtactical.com.',
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({
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
