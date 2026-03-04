import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/widgets/tactical_button.dart';
import '../home/home_screen.dart';
import 'widgets/disclaimer_page.dart';
import 'widgets/permissions_page.dart';
import 'widgets/quick_setup_page.dart';

/// First-launch onboarding flow.
///
/// 4 pages:
///   0 — Welcome / branding
///   1 — Safety disclaimer (must accept to proceed)
///   2 — Permission requests (location + Bluetooth)
///   3 — Quick setup (name, theme, mode)
///
/// Marks onboarding complete on finish and navigates to [HomeScreen].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _disclaimerAccepted = false;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Block advancing past disclaimer without acceptance.
    if (_currentPage == 1 && !_disclaimerAccepted) {
      notifyWarning();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'YOU MUST ACKNOWLEDGE THE DISCLAIMER TO CONTINUE',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: Color(0xFFCC0000),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentPage < _pageCount - 1) {
      tapLight();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    tapHeavy();
    await ref.read(hasCompletedOnboardingProvider.notifier).complete();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  // Page 0: Welcome
                  _WelcomePage(colors: colors),

                  // Page 1: Disclaimer
                  DisclaimerPage(
                    colors: colors,
                    isAccepted: _disclaimerAccepted,
                    onAcceptChanged: (v) {
                      setState(() => _disclaimerAccepted = v);
                    },
                  ),

                  // Page 2: Permissions
                  PermissionsPage(colors: colors),

                  // Page 3: Quick Setup
                  QuickSetupPage(onFinish: _finish),
                ],
              ),
            ),

            // Bottom bar: dots + next button
            if (_currentPage < _pageCount - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(_pageCount, (i) {
                        return Container(
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentPage
                                ? colors.accent
                                : colors.border,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Next button
                    SizedBox(
                      width: 120,
                      child: TacticalButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        colors: colors,
                        isCompact: true,
                        onPressed: _nextPage,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Show dots only on last page (button is inside QuickSetupPage)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pageCount, (i) {
                    return Container(
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentPage
                            ? colors.accent
                            : colors.border,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome page (page 0)
// ---------------------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.colors});

  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon / branding
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.accent, width: 2),
                color: colors.card,
              ),
              child: Icon(
                Icons.grid_on,
                size: 48,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'RED GRID LINK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: colors.accent,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PROXIMITY COORDINATION',
              style: TacticalTextStyles.label(colors),
            ),
            const SizedBox(height: 32),

            Text(
              'Offline-first MGRS navigation and proximity '
              'sync for small civilian teams.',
              style: TacticalTextStyles.body(colors),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Feature bullets
            _FeatureBullet(
              icon: Icons.grid_on,
              text: 'MGRS-native coordinate display',
              colors: colors,
            ),
            _FeatureBullet(
              icon: Icons.bluetooth,
              text: 'Field Link proximity sync (2-8 devices)',
              colors: colors,
            ),
            _FeatureBullet(
              icon: Icons.map,
              text: 'Offline map support',
              colors: colors,
            ),
            _FeatureBullet(
              icon: Icons.battery_full,
              text: 'Battery-efficient expedition mode',
              colors: colors,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.icon,
    required this.text,
    required this.colors,
  });

  final IconData icon;
  final String text;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TacticalTextStyles.caption(colors),
            ),
          ),
        ],
      ),
    );
  }
}
