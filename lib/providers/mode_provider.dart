import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/operational_mode.dart';
import 'settings_provider.dart';

/// Resolves the current [OperationalMode] enum from the stored mode string.
///
/// This is a convenience provider so UI widgets can get the full enum
/// (with labels, icon, toolsSubtitle, etc.) without manually resolving
/// the string every time.
///
/// Falls back to [OperationalMode.sar] if the stored value is unrecognized.
final currentModeProvider = Provider<OperationalMode>((ref) {
  final modeId = ref.watch(operationalModeProvider);
  return OperationalMode.fromId(modeId);
});
