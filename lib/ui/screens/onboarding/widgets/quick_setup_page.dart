import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/mode_selector.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/theme_preview.dart';

/// Onboarding page 4: Quick initial configuration.
///
/// Lets the user set display name, theme, and operational mode before
/// starting the app. Calls [onFinish] when the "Get Started" button
/// is pressed.
class QuickSetupPage extends ConsumerStatefulWidget {
  const QuickSetupPage({
    super.key,
    required this.onFinish,
  });

  final VoidCallback onFinish;

  @override
  ConsumerState<QuickSetupPage> createState() => _QuickSetupPageState();
}

class _QuickSetupPageState extends ConsumerState<QuickSetupPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(displayNameProvider),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final currentThemeId = ref.watch(themeIdProvider);
    final entitlement = ref.watch(entitlementProvider);
    final bool isPro = entitlement == 'pro' || entitlement == 'team';
    final themes = tacticalThemes.values.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Title
          Center(
            child: Icon(
              Icons.tune,
              size: 48,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'QUICK SETUP',
              style: TacticalTextStyles.heading(colors),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Configure your preferences',
              style: TacticalTextStyles.caption(colors),
            ),
          ),
          const SizedBox(height: 24),

          // --- Display Name ---
          SectionHeader(title: 'Display Name', colors: colors),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TacticalTextStyles.body(colors),
            maxLength: 16,
            decoration: InputDecoration(
              hintText: 'Operator',
              counterStyle: TacticalTextStyles.dim(colors),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                ref.read(displayNameProvider.notifier).set(value.trim());
              }
            },
          ),

          const SizedBox(height: 16),

          // --- Theme ---
          SectionHeader(title: 'Choose Theme', colors: colors),
          const SizedBox(height: 8),
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
                      if (!isLocked) {
                        ref.read(themeIdProvider.notifier).set(theme.id);
                      }
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

          const SizedBox(height: 16),

          // --- Mode ---
          SectionHeader(title: 'Operational Mode', colors: colors),
          const SizedBox(height: 8),
          const ModeSelector(),

          const SizedBox(height: 32),

          // --- Finish button ---
          TacticalButton(
            label: 'Start Using Red Grid Link',
            icon: Icons.rocket_launch,
            colors: colors,
            onPressed: widget.onFinish,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
