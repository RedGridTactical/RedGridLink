import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';

// ---------------------------------------------------------------------------
// Settings repository dependency
// ---------------------------------------------------------------------------

/// Provider for [SettingsRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by an initialized [SharedPreferences].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

// ---------------------------------------------------------------------------
// Theme ID
// ---------------------------------------------------------------------------

/// Notifier for the active color theme identifier.
class ThemeIdNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  ThemeIdNotifier(this._repo) : super(_repo.themeId);

  /// Update the theme and persist to storage.
  Future<void> set(String value) async {
    state = value;
    await _repo.setThemeId(value);
  }
}

/// Current theme ID (e.g., 'red', 'green', 'blue').
final themeIdProvider =
    StateNotifierProvider<ThemeIdNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeIdNotifier(repo);
});

// ---------------------------------------------------------------------------
// Operational mode
// ---------------------------------------------------------------------------

/// Notifier for the active operational mode.
class OperationalModeNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  OperationalModeNotifier(this._repo) : super(_repo.operationalMode);

  /// Update the operational mode and persist to storage.
  Future<void> set(String value) async {
    state = value;
    await _repo.setOperationalMode(value);
  }
}

/// Active operational mode: sar, backcountry, hunting, or training.
final operationalModeProvider =
    StateNotifierProvider<OperationalModeNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return OperationalModeNotifier(repo);
});

// ---------------------------------------------------------------------------
// Declination
// ---------------------------------------------------------------------------

/// Notifier for the magnetic declination offset.
class DeclinationNotifier extends StateNotifier<double> {
  final SettingsRepository _repo;

  DeclinationNotifier(this._repo) : super(_repo.declination);

  /// Update the declination and persist to storage.
  Future<void> set(double value) async {
    state = value;
    await _repo.setDeclination(value);
  }
}

/// Magnetic declination offset in degrees.
final declinationProvider =
    StateNotifierProvider<DeclinationNotifier, double>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return DeclinationNotifier(repo);
});

// ---------------------------------------------------------------------------
// Display name
// ---------------------------------------------------------------------------

/// Notifier for the user's display name.
class DisplayNameNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  DisplayNameNotifier(this._repo) : super(_repo.displayName);

  /// Update the display name and persist to storage.
  Future<void> set(String value) async {
    state = value;
    await _repo.setDisplayName(value);
  }
}

/// User's display name shown to peers.
final displayNameProvider =
    StateNotifierProvider<DisplayNameNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return DisplayNameNotifier(repo);
});

// ---------------------------------------------------------------------------
// Sync mode
// ---------------------------------------------------------------------------

/// Notifier for the sync mode setting.
class SyncModeNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  SyncModeNotifier(this._repo) : super(_repo.syncMode);

  /// Update the sync mode and persist to storage.
  Future<void> set(String value) async {
    state = value;
    await _repo.setSyncMode(value);
  }
}

/// Sync mode: expedition or active.
final syncModeProvider =
    StateNotifierProvider<SyncModeNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SyncModeNotifier(repo);
});

// ---------------------------------------------------------------------------
// Update interval
// ---------------------------------------------------------------------------

/// Notifier for the position update interval.
class UpdateIntervalNotifier extends StateNotifier<int> {
  final SettingsRepository _repo;

  UpdateIntervalNotifier(this._repo) : super(_repo.updateInterval);

  /// Update the interval (in milliseconds) and persist to storage.
  Future<void> set(int value) async {
    state = value;
    await _repo.setUpdateInterval(value);
  }
}

/// Position update broadcast interval in milliseconds.
final updateIntervalProvider =
    StateNotifierProvider<UpdateIntervalNotifier, int>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return UpdateIntervalNotifier(repo);
});

// ---------------------------------------------------------------------------
// Pace count
// ---------------------------------------------------------------------------

/// Notifier for the user's pace count.
class PaceCountNotifier extends StateNotifier<int> {
  final SettingsRepository _repo;

  PaceCountNotifier(this._repo) : super(_repo.paceCount);

  /// Update the pace count and persist to storage.
  Future<void> set(int value) async {
    state = value;
    await _repo.setPaceCount(value);
  }
}

/// User's pace count (steps per 100m).
final paceCountProvider =
    StateNotifierProvider<PaceCountNotifier, int>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return PaceCountNotifier(repo);
});

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

/// Notifier for the onboarding completion flag.
class OnboardingNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;

  OnboardingNotifier(this._repo) : super(_repo.hasCompletedOnboarding);

  /// Mark onboarding as completed and persist to storage.
  Future<void> complete() async {
    state = true;
    await _repo.setHasCompletedOnboarding(true);
  }
}

/// Whether the user has completed the initial onboarding flow.
final hasCompletedOnboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return OnboardingNotifier(repo);
});

// ---------------------------------------------------------------------------
// Demo Mode
// ---------------------------------------------------------------------------

/// Notifier for the demo mode toggle.
///
/// Demo mode is a developer-only feature that swaps real GPS + live peers
/// for a hard-coded fake session (Shenandoah NP reference point, 4 fake
/// peers, a boundary polygon).  It is used for App Store / Play Store
/// screenshot capture and reviewer walkthroughs.
///
/// Release-build safety: in [kReleaseMode] this notifier ignores any
/// persisted value and forces state to `false` permanently.  The Settings
/// UI toggle is also gated behind [kDebugMode], so there is no code path
/// that can enable demo mode in a production build.  This double-gate
/// guarantees end users see their real GPS position, not demo coordinates.
class DemoModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;

  DemoModeNotifier(this._repo)
      : super(kReleaseMode ? false : _repo.isDemoMode);

  /// Toggle demo mode and persist to storage.  No-op in release builds.
  Future<void> set(bool value) async {
    if (kReleaseMode) return;
    state = value;
    await _repo.setDemoMode(value);
  }
}

/// Whether demo mode is active (hard-coded fake data for screenshots).
/// Always `false` in release builds.
final demoModeProvider =
    StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return DemoModeNotifier(repo);
});

// ---------------------------------------------------------------------------
// Entitlement
// ---------------------------------------------------------------------------

/// Notifier for the user's entitlement tier.
class EntitlementNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  /// Whether the in-memory state has been deliberately overridden for
  /// the current session (demo mode). When true, [setNonPersisting]
  /// has installed a value that should NOT be written to storage.
  bool _sessionOverride = false;

  /// Construct with optional [initialOverride]. When non-null, the
  /// notifier starts in that state without writing to storage. Used by
  /// the entitlement provider to seed `proLink` for demo mode without
  /// reaching into a protected `state` setter from outside the class.
  ///
  /// Audit 2026-05-03 P1: previously the entitlement provider mutated
  /// `notifier.state = 'proLink'` from outside the StateNotifier, which
  /// triggered analyzer warnings (`invalid_use_of_protected_member` and
  /// `invalid_use_of_visible_for_testing_member`) and made it unclear
  /// to readers whether the value would be persisted.
  EntitlementNotifier(this._repo, {String? initialOverride})
      : super(initialOverride ?? _repo.entitlement) {
    _sessionOverride = initialOverride != null;
  }

  /// Update the entitlement tier and persist to storage.
  Future<void> set(String value) async {
    state = value;
    _sessionOverride = false;
    await _repo.setEntitlement(value);
  }

  /// Set an in-memory override without persisting. Intended for
  /// session-scoped overrides like demo mode.
  void setNonPersisting(String value) {
    state = value;
    _sessionOverride = true;
  }

  /// Whether the current state is a non-persisting session override.
  bool get isSessionOverride => _sessionOverride;
}

/// User entitlement tier: free, pro, proLink, or team.
///
/// SUNSET (v1.7.0, final release): Red Grid Link is now part of Red Grid
/// MGRS and no longer sells anything. Every free user is elevated to
/// `proLink` so all features (themes, maps, AAR export, full Field Link)
/// are unlocked at no charge for as long as the app stays installed.
/// Stored paid entitlements are left untouched. This supersedes the old
/// demo-mode override, which forced the same tier for screenshots.
final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  // Compute the seed up front so we don't need to mutate `state` from
  // outside the notifier subclass.
  final stored = repo.entitlement;
  final initial = (stored == 'free') ? 'proLink' : null;
  return EntitlementNotifier(repo, initialOverride: initial);
});
