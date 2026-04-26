import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/operational_mode.dart';
import 'field_link_provider.dart';
import 'settings_provider.dart';

/// Resolves the current [OperationalMode] enum for mode-aware UI surfaces
/// (message bar labels, marker labels, screen subtitles, quick actions).
///
/// While a Field Link session is active, the mode follows the SESSION's
/// operational mode — not the user's saved local preference. This keeps
/// every peer's UI labels consistent (a SAR session shows "SUBJECT FOUND"
/// on every device regardless of each device's saved mode setting).
///
/// When no session is active, falls back to the user's saved mode from
/// [operationalModeProvider]. The settings ModeSelector continues to
/// drive that saved preference directly so the user can still configure
/// their default mode for next time without affecting the active session.
///
/// Falls back to [OperationalMode.sar] if the stored value is unrecognized.
final currentModeProvider = Provider<OperationalMode>((ref) {
  // Prefer the active session's mode when one is running so all peers
  // see consistent labels.
  final sessionAsync = ref.watch(activeSessionProvider);
  final session = sessionAsync.valueOrNull;
  if (session != null) {
    return session.operationalMode;
  }

  // No active session — use the user's saved local preference.
  final modeId = ref.watch(operationalModeProvider);
  return OperationalMode.fromId(modeId);
});
