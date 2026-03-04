import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';

void main() {
  late SettingsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  group('SettingsRepository default values', () {
    test('themeId defaults to red', () {
      expect(repo.themeId, 'red');
    });

    test('operationalMode defaults to sar', () {
      expect(repo.operationalMode, 'sar');
    });

    test('declination defaults to 0.0', () {
      expect(repo.declination, 0.0);
    });

    test('paceCount defaults to 62', () {
      expect(repo.paceCount, 62);
    });

    test('updateInterval defaults to 15000', () {
      expect(repo.updateInterval, 15000);
    });

    test('syncMode defaults to active', () {
      expect(repo.syncMode, 'active');
    });

    test('displayName defaults to Operator', () {
      expect(repo.displayName, 'Operator');
    });

    test('hasCompletedOnboarding defaults to false', () {
      expect(repo.hasCompletedOnboarding, false);
    });

    test('entitlement defaults to free', () {
      expect(repo.entitlement, 'free');
    });
  });

  group('SettingsRepository set and get', () {
    test('setThemeId persists and retrieves correctly', () async {
      await repo.setThemeId('green');
      expect(repo.themeId, 'green');
    });

    test('setOperationalMode persists and retrieves correctly', () async {
      await repo.setOperationalMode('hunting');
      expect(repo.operationalMode, 'hunting');
    });

    test('setDeclination persists and retrieves correctly', () async {
      await repo.setDeclination(-12.5);
      expect(repo.declination, -12.5);
    });

    test('setPaceCount persists and retrieves correctly', () async {
      await repo.setPaceCount(70);
      expect(repo.paceCount, 70);
    });

    test('setUpdateInterval persists and retrieves correctly', () async {
      await repo.setUpdateInterval(30000);
      expect(repo.updateInterval, 30000);
    });

    test('setSyncMode persists and retrieves correctly', () async {
      await repo.setSyncMode('expedition');
      expect(repo.syncMode, 'expedition');
    });

    test('setDisplayName persists and retrieves correctly', () async {
      await repo.setDisplayName('Alpha');
      expect(repo.displayName, 'Alpha');
    });

    test('setHasCompletedOnboarding persists and retrieves correctly', () async {
      await repo.setHasCompletedOnboarding(true);
      expect(repo.hasCompletedOnboarding, true);
    });

    test('setEntitlement persists and retrieves correctly', () async {
      await repo.setEntitlement('pro');
      expect(repo.entitlement, 'pro');
    });
  });

  group('SettingsRepository persistence round-trip', () {
    test('values survive SharedPreferences re-instantiation', () async {
      // Set values on first repo instance
      await repo.setThemeId('blue');
      await repo.setOperationalMode('training');
      await repo.setDeclination(5.5);
      await repo.setPaceCount(68);
      await repo.setUpdateInterval(10000);
      await repo.setSyncMode('expedition');
      await repo.setDisplayName('Bravo');
      await repo.setHasCompletedOnboarding(true);
      await repo.setEntitlement('team');

      // Get a fresh SharedPreferences instance (backed by same mock store)
      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = SettingsRepository(prefs2);

      expect(repo2.themeId, 'blue');
      expect(repo2.operationalMode, 'training');
      expect(repo2.declination, 5.5);
      expect(repo2.paceCount, 68);
      expect(repo2.updateInterval, 10000);
      expect(repo2.syncMode, 'expedition');
      expect(repo2.displayName, 'Bravo');
      expect(repo2.hasCompletedOnboarding, true);
      expect(repo2.entitlement, 'team');
    });

    test('overwriting a value replaces previous value', () async {
      await repo.setThemeId('green');
      expect(repo.themeId, 'green');

      await repo.setThemeId('blue');
      expect(repo.themeId, 'blue');
    });
  });

  group('SettingsRepository with pre-populated values', () {
    test('reads pre-existing SharedPreferences values', () async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_id': 'green',
        'settings_operational_mode': 'hunting',
        'settings_declination': 7.2,
        'settings_pace_count': 55,
        'settings_update_interval': 5000,
        'settings_sync_mode': 'expedition',
        'settings_display_name': 'Charlie',
        'settings_has_completed_onboarding': true,
        'settings_entitlement': 'pro',
      });
      final prefs = await SharedPreferences.getInstance();
      final prePopulatedRepo = SettingsRepository(prefs);

      expect(prePopulatedRepo.themeId, 'green');
      expect(prePopulatedRepo.operationalMode, 'hunting');
      expect(prePopulatedRepo.declination, 7.2);
      expect(prePopulatedRepo.paceCount, 55);
      expect(prePopulatedRepo.updateInterval, 5000);
      expect(prePopulatedRepo.syncMode, 'expedition');
      expect(prePopulatedRepo.displayName, 'Charlie');
      expect(prePopulatedRepo.hasCompletedOnboarding, true);
      expect(prePopulatedRepo.entitlement, 'pro');
    });
  });
}
