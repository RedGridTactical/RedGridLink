import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../common/widgets/section_header.dart';
import '../onboarding/onboarding_screen.dart';

/// Help & Getting Started screen.
///
/// Provides a scrollable guide covering:
/// - Quick start walkthrough
/// - Feature overview (modes, Field Link, tools, themes)
/// - Replay onboarding option
/// - FAQ section
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          'HELP & GUIDE',
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
            // ── QUICK START ─────────────────────────────────
            SectionHeader(title: 'Quick Start', colors: colors),
            const SizedBox(height: 12),
            _HelpCard(
              colors: colors,
              children: [
                _StepItem(
                  number: '1',
                  title: 'Create a Session',
                  description:
                      'Go to the LINK tab and tap CREATE SESSION. Choose '
                      'a name, security mode (Open, PIN, or QR), and '
                      'operational mode.',
                  colors: colors,
                ),
                _StepItem(
                  number: '2',
                  title: 'Navigate with MGRS',
                  description:
                      'The GRID tab shows your real-time MGRS coordinate '
                      'with precision display. The MAP tab overlays an '
                      'MGRS grid on the map.',
                  colors: colors,
                ),
                _StepItem(
                  number: '3',
                  title: 'Connect with Teammates',
                  description:
                      'Other team members can join your session via the '
                      'LINK tab. Their positions appear as markers on '
                      'your map in real time.',
                  colors: colors,
                ),
                _StepItem(
                  number: '4',
                  title: 'Use Tactical Tools',
                  description:
                      'The TOOLS tab provides 11 field calculators '
                      'including Dead Reckoning, Resection, Pace Count, '
                      'Coordinate Converter, and more.',
                  colors: colors,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── FEATURES ────────────────────────────────────
            SectionHeader(title: 'Feature Overview', colors: colors),
            const SizedBox(height: 12),
            _HelpCard(
              colors: colors,
              children: [
                _FeatureItem(
                  icon: Icons.map,
                  title: 'Offline Maps',
                  description:
                      'Download map regions for use without cellular '
                      'signal. Supports OSM and TOPO tile sources.',
                  colors: colors,
                ),
                _FeatureItem(
                  icon: Icons.bluetooth,
                  title: 'Field Link',
                  description:
                      'Peer-to-peer coordination via BLE and WiFi Direct. '
                      'Share positions with your team without internet. '
                      '${AppConstants.rangeDisclaimer}',
                  colors: colors,
                ),
                _FeatureItem(
                  icon: Icons.build,
                  title: '11 Tactical Tools',
                  description:
                      'Dead Reckoning, Resection, Pace Count, Back '
                      'Azimuth, Coordinate Converter, Range Estimation, '
                      'Slope Calculator, ETA/Speed, Declination, '
                      'Celestial Nav, and MGRS Reference.',
                  colors: colors,
                ),
                _FeatureItem(
                  icon: Icons.palette,
                  title: '4 Tactical Themes',
                  description:
                      'Red Light (free), NVG Green, Day White, and Blue '
                      'Force. Each designed for specific field conditions.',
                  colors: colors,
                ),
                _FeatureItem(
                  icon: Icons.settings,
                  title: '4 Operational Modes',
                  description:
                      'SAR, Backcountry, Hunting, and Training. Each mode '
                      'uses context-specific terminology throughout the app.',
                  colors: colors,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── FAQ ─────────────────────────────────────────
            SectionHeader(title: 'FAQ', colors: colors),
            const SizedBox(height: 12),
            _HelpCard(
              colors: colors,
              children: [
                _FaqItem(
                  question: 'What is the range of Field Link?',
                  answer: AppConstants.rangeDisclaimer,
                  colors: colors,
                ),
                _FaqItem(
                  question: 'How does battery usage work?',
                  answer:
                      'Expedition Mode uses BLE only with 30-second '
                      'updates (~3%/hr). Ultra Expedition extends to '
                      '60-second updates (~2%/hr). Active Mode uses '
                      'BLE + WiFi Direct with 5-second updates for '
                      'real-time tracking at higher battery cost.',
                  colors: colors,
                ),
                _FaqItem(
                  question: 'Is my data private?',
                  answer:
                      'Yes. Red Grid Link is offline-first. No data is '
                      'sent to any server. All communication is peer-to-peer '
                      'with AES-256 encryption. Position data stays on '
                      'your device and connected peers only.',
                  colors: colors,
                ),
                _FaqItem(
                  question: 'How do I download maps?',
                  answer:
                      'On the MAP tab, tap the download button (cloud icon) '
                      'in the controls. This opens the Offline Maps sheet '
                      'where you can download the current map view for '
                      'offline use.',
                  colors: colors,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── REPLAY WELCOME GUIDE ────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppConstants.minTouchTarget,
              child: OutlinedButton.icon(
                icon: Icon(Icons.replay, color: colors.accent),
                label: Text(
                  'REPLAY WELCOME GUIDE',
                  style: TacticalTextStyles.body(colors).copyWith(
                    color: colors.accent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(readOnly: true),
                    ),
                  );
                },
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

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.colors, required this.children});

  final TacticalColorScheme colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.title,
    required this.description,
    required this.colors,
  });

  final String number;
  final String title;
  final String description;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.2),
              border: Border.all(color: colors.accent),
            ),
            child: Text(
              number,
              style: TacticalTextStyles.caption(colors).copyWith(
                color: colors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TacticalTextStyles.body(colors)),
                const SizedBox(height: 2),
                Text(description, style: TacticalTextStyles.dim(colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String description;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TacticalTextStyles.body(colors)),
                const SizedBox(height: 2),
                Text(description, style: TacticalTextStyles.dim(colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.colors,
  });

  final String question;
  final String answer;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TacticalTextStyles.body(colors).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(answer, style: TacticalTextStyles.dim(colors)),
        ],
      ),
    );
  }
}
