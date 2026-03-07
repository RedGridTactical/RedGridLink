import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/section_header.dart';
import 'terms_screen.dart';

/// Full About screen for Red Grid Link.
///
/// Displays app name, version, disclaimers, safety notice,
/// terms of use link, privacy policy link, and open source licenses.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          'ABOUT',
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
            // App identity
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.grid_on,
                    size: 48,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName.toUpperCase(),
                    style: TacticalTextStyles.heading(colors).copyWith(
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: TacticalTextStyles.caption(colors),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offline-first MGRS proximity coordination',
                    style: TacticalTextStyles.dim(colors),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About text
            _AboutCard(
              colors: colors,
              children: [
                Text(
                  'Red Grid Link is an offline-first, MGRS-native '
                  'proximity coordination platform designed for small '
                  'civilian teams of 2-8 people.',
                  style: TacticalTextStyles.body(colors),
                ),
                const SizedBox(height: 8),
                Text(
                  'Built for search & rescue volunteers, backcountry '
                  'hikers, hunting parties, and training exercises. '
                  'No internet required. No accounts. No tracking.',
                  style: TacticalTextStyles.body(colors),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Range disclaimer
            SectionHeader(title: 'Range Disclaimer', colors: colors),
            const SizedBox(height: 12),
            _AboutCard(
              colors: colors,
              children: [
                Text(
                  AppConstants.rangeDisclaimer,
                  style: TacticalTextStyles.body(colors),
                ),
                const SizedBox(height: 8),
                Text(
                  'Actual range depends on terrain, vegetation, weather, '
                  'and device hardware. BLE (Bluetooth Low Energy) '
                  'typically provides 50-100m in heavy cover, 150-300m '
                  'in open terrain. WiFi Direct can extend range to '
                  '~200m under ideal conditions.',
                  style: TacticalTextStyles.dim(colors),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Safety notice
            SectionHeader(title: 'Safety Notice', colors: colors),
            const SizedBox(height: 12),
            _AboutCard(
              colors: colors,
              children: [
                Text(
                  'This app is a coordination tool, not a safety device. '
                  'Always carry proper navigation equipment including '
                  'compass, paper maps, and backup communication.',
                  style: TacticalTextStyles.body(colors),
                ),
                const SizedBox(height: 8),
                Text(
                  'GPS accuracy varies by conditions. MGRS coordinates '
                  'are derived from device GPS and may not match '
                  'survey-grade positions. Do not rely solely on this '
                  'app for life-safety decisions.',
                  style: TacticalTextStyles.dim(colors),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Links section
            SectionHeader(title: 'Legal', colors: colors),
            const SizedBox(height: 12),
            _AboutCard(
              colors: colors,
              children: [
                _LinkRow(
                  label: 'Terms of Use',
                  icon: Icons.description,
                  colors: colors,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TermsScreen(),
                    ),
                  ),
                ),
                Divider(color: colors.border2),
                _LinkRow(
                  label: 'Privacy Policy',
                  icon: Icons.privacy_tip,
                  colors: colors,
                  onTap: () {
                    // In a full implementation, this would open the
                    // privacy policy URL or a dedicated screen.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Privacy policy at redgridlink.com/privacy',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: colors.card,
                      ),
                    );
                  },
                ),
                Divider(color: colors.border2),
                _LinkRow(
                  label: 'Open Source Licenses',
                  icon: Icons.code,
                  colors: colors,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                  ),
                ),
              ],
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

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.colors, required this.children});

  final TacticalColorScheme colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final TacticalColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppConstants.minTouchTarget,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TacticalTextStyles.body(colors).copyWith(
                  color: colors.accent,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.text3),
          ],
        ),
      ),
    );
  }
}
