import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';

void main() {
  late ProviderContainer container;
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ---------------------------------------------------------------------------
  // ThemeIdNotifier
  // ---------------------------------------------------------------------------

  group('ThemeIdNotifier', () {
    test('initial state comes from repository default', () {
      final themeId = container.read(themeIdProvider);
      expect(themeId, 'red');
    });

    test('set updates state', () async {
      await container.read(themeIdProvider.notifier).set('green');
      expect(container.read(themeIdProvider), 'green');
    });

    test('set persists value to repository', () async {
      await container.read(themeIdProvider.notifier).set('blue');
      expect(repo.themeId, 'blue');
    });

    test('initial state reads pre-populated repository value', () async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_id': 'green',
      });
      final prefs = await SharedPreferences.getInstance();
      final customRepo = SettingsRepository(prefs);
      final customContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(customRepo),
        ],
      );
      expect(customContainer.read(themeIdProvider), 'green');
      customContainer.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // OperationalModeNotifier
  // ---------------------------------------------------------------------------

  group('OperationalModeNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(operationalModeProvider), 'sar');
    });

    test('set updates state', () async {
      await container.read(operationalModeProvider.notifier).set('hunting');
      expect(container.read(operationalModeProvider), 'hunting');
    });

    test('set persists value to repository', () async {
      await container.read(operationalModeProvider.notifier).set('training');
      expect(repo.operationalMode, 'training');
    });
  });

  // ---------------------------------------------------------------------------
  // DeclinationNotifier
  // ---------------------------------------------------------------------------

  group('DeclinationNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(declinationProvider), 0.0);
    });

    test('set updates state', () async {
      await container.read(declinationProvider.notifier).set(-8.5);
      expect(container.read(declinationProvider), -8.5);
    });

    test('set persists value to repository', () async {
      await container.read(declinationProvider.notifier).set(12.3);
      expect(repo.declination, 12.3);
    });
  });

  // ---------------------------------------------------------------------------
  // DisplayNameNotifier
  // ---------------------------------------------------------------------------

  group('DisplayNameNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(displayNameProvider), 'Operator');
    });

    test('set updates state', () async {
      await container.read(displayNameProvider.notifier).set('Alpha');
      expect(container.read(displayNameProvider), 'Alpha');
    });

    test('set persists value to repository', () async {
      await container.read(displayNameProvider.notifier).set('Bravo');
      expect(repo.displayName, 'Bravo');
    });
  });

  // ---------------------------------------------------------------------------
  // SyncModeNotifier
  // ---------------------------------------------------------------------------

  group('SyncModeNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(syncModeProvider), 'active');
    });

    test('set updates state', () async {
      await container.read(syncModeProvider.notifier).set('expedition');
      expect(container.read(syncModeProvider), 'expedition');
    });

    test('set persists value to repository', () async {
      await container.read(syncModeProvider.notifier).set('expedition');
      expect(repo.syncMode, 'expedition');
    });
  });

  // ---------------------------------------------------------------------------
  // UpdateIntervalNotifier
  // ---------------------------------------------------------------------------

  group('UpdateIntervalNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(updateIntervalProvider), 15000);
    });

    test('set updates state', () async {
      await container.read(updateIntervalProvider.notifier).set(5000);
      expect(container.read(updateIntervalProvider), 5000);
    });

    test('set persists value to repository', () async {
      await container.read(updateIntervalProvider.notifier).set(30000);
      expect(repo.updateInterval, 30000);
    });
  });

  // ---------------------------------------------------------------------------
  // PaceCountNotifier
  // ---------------------------------------------------------------------------

  group('PaceCountNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(paceCountProvider), 62);
    });

    test('set updates state', () async {
      await container.read(paceCountProvider.notifier).set(70);
      expect(container.read(paceCountProvider), 70);
    });

    test('set persists value to repository', () async {
      await container.read(paceCountProvider.notifier).set(55);
      expect(repo.paceCount, 55);
    });
  });

  // ---------------------------------------------------------------------------
  // OnboardingNotifier
  // ---------------------------------------------------------------------------

  group('OnboardingNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(hasCompletedOnboardingProvider), false);
    });

    test('complete updates state to true', () async {
      await container.read(hasCompletedOnboardingProvider.notifier).complete();
      expect(container.read(hasCompletedOnboardingProvider), true);
    });

    test('complete persists value to repository', () async {
      await container.read(hasCompletedOnboardingProvider.notifier).complete();
      expect(repo.hasCompletedOnboarding, true);
    });
  });

  // ---------------------------------------------------------------------------
  // EntitlementNotifier
  // ---------------------------------------------------------------------------

  group('EntitlementNotifier', () {
    test('initial state comes from repository default', () {
      expect(container.read(entitlementProvider), 'free');
    });

    test('set updates state', () async {
      await container.read(entitlementProvider.notifier).set('pro');
      expect(container.read(entitlementProvider), 'pro');
    });

    test('set persists value to repository', () async {
      await container.read(entitlementProvider.notifier).set('team');
      expect(repo.entitlement, 'team');
    });
  });
}
