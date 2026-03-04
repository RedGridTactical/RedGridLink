import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/theme_preview.dart';

/// Theme picker section for the settings screen.
///
/// Displays a 2x2 grid of [ThemePreview] cards for each tactical theme.
/// Pro-only themes show a lock badge for free-tier users. Tapping a theme
/// immediately persists the selection and updates the entire app.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final currentThemeId = ref.watch(themeIdProvider);
    final entitlement = ref.watch(entitlementProvider);
    final bool isPro = entitlement == 'pro' || entitlement == 'team';

    final themes = tacticalThemes.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Theme', colors: colors),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final theme = themes[index];
            final isSelected = theme.id == currentThemeId;
            final isLocked = theme.pro && !isPro;

            return Stack(
              children: [
                ThemePreview(
                  previewColors: theme,
                  isSelected: isSelected,
                  appColors: colors,
                  onTap: () {
                    if (isLocked) {
                      _showProRequired(context, colors);
                      return;
                    }
                    ref.read(themeIdProvider.notifier).set(theme.id);
                  },
                ),
                if (isLocked)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: colors.text3,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showProRequired(BuildContext context, TacticalColorScheme colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'PRO THEME - Upgrade to unlock',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: colors.accent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
