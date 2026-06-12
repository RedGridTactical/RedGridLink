import 'package:shared_preferences/shared_preferences.dart';

/// Local-only conversion counters: paywall views, gate hits, purchases.
///
/// Counts never leave the device — no network, no analytics, no identifiers.
/// They exist so rough funnel numbers (how often is the paywall seen, which
/// gate gets hit, how many purchases) can be read off the diagnostics screen
/// without violating the zero-network privacy rule.
class FunnelStats {
  FunnelStats._();

  static final FunnelStats instance = FunnelStats._();

  static const String _prefix = 'funnel.';

  /// Increment [key] by one. Failures are swallowed — stats must never
  /// interfere with the flow being counted.
  Future<void> increment(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = '$_prefix$key';
      await prefs.setInt(fullKey, (prefs.getInt(fullKey) ?? 0) + 1);
    } catch (_) {
      // Best-effort only.
    }
  }

  /// All counters recorded so far, keyed without the storage prefix.
  Future<Map<String, int>> snapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final out = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_prefix)) {
          out[key.substring(_prefix.length)] = prefs.getInt(key) ?? 0;
        }
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Normalize a human-readable feature name into a counter key segment,
  /// e.g. 'After-Action Reports' -> 'after_action_reports'.
  static String keyFor(String featureName) => featureName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
