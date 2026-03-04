import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
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

    return MaterialApp(
      title: 'Red Grid Link',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(colors),
      home: hasCompletedOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
