import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tactical_colors.dart';
import 'settings_provider.dart';

/// Provides the active [TacticalColorScheme] to all ConsumerWidgets.
///
/// Reads the persisted theme-id from [themeIdProvider] and maps it to the
/// corresponding [TacticalColorScheme] via [getTacticalColors].
final currentThemeProvider = Provider<TacticalColorScheme>((ref) {
  final themeId = ref.watch(themeIdProvider);
  return getTacticalColors(themeId);
});
