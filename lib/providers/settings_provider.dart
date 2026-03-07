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
class DemoModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;

  DemoModeNotifier(this._repo) : super(_repo.isDemoMode);

  /// Toggle demo mode and persist to storage.
  Future<void> set(bool value) async {
    state = value;
    await _repo.setDemoMode(value);
  }
}

/// Whether demo mode is active (fake DC coordinates for screenshots).
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

  EntitlementNotifier(this._repo) : super(_repo.entitlement);

  /// Update the entitlement tier and persist to storage.
  Future<void> set(String value) async {
    state = value;
    await _repo.setEntitlement(value);
  }
}

/// User entitlement tier: free, pro, proLink, or team.
final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return EntitlementNotifier(repo);
});
