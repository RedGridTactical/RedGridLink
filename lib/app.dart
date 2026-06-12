import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'providers/field_link_provider.dart';
import 'providers/preflight_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';

/// Root widget for Red Grid Link.
///
/// Watches [currentThemeProvider] so the entire MaterialApp rebuilds
/// instantly when the user switches tactical themes. Routes to
/// [OnboardingScreen] on first launch, then [HomeScreen] thereafter.
class RedGridLinkApp extends ConsumerWidget {
  const RedGridLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    // Wire RSSI polling callbacks so signal bars work during BLE sessions.
    ref.watch(rssiWiringProvider);
    // Wire remote emergency state so alert overlay shows for remote SOS.
    ref.watch(emergencyWiringProvider);
    // Push GPS positions to the sync engine when a session is active.
    // This runs regardless of which tab is visible — critical for peer
    // visibility. Without it, positions only update on the MAP tab.
    ref.watch(positionSyncProvider);
    // Wire Field Readiness preflight broadcast + inbound team board updates.
    ref.watch(preflightWiringProvider);
    // Wire the host-side device-cap rejection → Pro+Link upsell signal.
    ref.watch(capUpsellWiringProvider);

    return MaterialApp(
      title: 'Red Grid Link',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(colors),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: hasCompletedOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
