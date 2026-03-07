import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/mode_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // -----------------------------------------------------------------------
  // OperationalMode.fromId
  // -----------------------------------------------------------------------
  group('OperationalMode.fromId', () {
    test('resolves sar', () {
      expect(OperationalMode.fromId('sar'), OperationalMode.sar);
    });

    test('resolves backcountry', () {
      expect(OperationalMode.fromId('backcountry'), OperationalMode.backcountry);
    });

    test('resolves hunting', () {
      expect(OperationalMode.fromId('hunting'), OperationalMode.hunting);
    });

    test('resolves training', () {
      expect(OperationalMode.fromId('training'), OperationalMode.training);
    });

    test('unknown id defaults to sar', () {
      expect(OperationalMode.fromId('unknown'), OperationalMode.sar);
    });

    test('empty string defaults to sar', () {
      expect(OperationalMode.fromId(''), OperationalMode.sar);
    });
  });

  // -----------------------------------------------------------------------
  // OperationalMode enum fields
  // -----------------------------------------------------------------------
  group('OperationalMode fields', () {
    test('sar has search icon', () {
      expect(OperationalMode.sar.icon, isNotNull);
    });

    test('each mode has a non-empty toolsSubtitle', () {
      for (final mode in OperationalMode.values) {
        expect(mode.toolsSubtitle, isNotEmpty,
            reason: '${mode.label} has empty toolsSubtitle');
      }
    });

    test('each mode has unique toolsSubtitle', () {
      final subtitles = OperationalMode.values.map((m) => m.toolsSubtitle).toSet();
      expect(subtitles.length, OperationalMode.values.length);
    });

    test('each mode has unique id', () {
      final ids = OperationalMode.values.map((m) => m.id).toSet();
      expect(ids.length, OperationalMode.values.length);
    });

    test('each mode has non-empty markerLabel', () {
      for (final mode in OperationalMode.values) {
        expect(mode.markerLabel, isNotEmpty);
      }
    });

    test('each mode has non-empty baseLabel', () {
      for (final mode in OperationalMode.values) {
        expect(mode.baseLabel, isNotEmpty);
      }
    });

    test('each mode has non-empty rallyPointLabel', () {
      for (final mode in OperationalMode.values) {
        expect(mode.rallyPointLabel, isNotEmpty);
      }
    });
  });

  // -----------------------------------------------------------------------
  // currentModeProvider
  // -----------------------------------------------------------------------
  group('currentModeProvider', () {
    test('returns sar by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final mode = container.read(currentModeProvider);
      expect(mode, OperationalMode.sar);
    });

    test('reflects stored mode', () async {
      SharedPreferences.setMockInitialValues({'settings_operational_mode': 'hunting'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final mode = container.read(currentModeProvider);
      expect(mode, OperationalMode.hunting);
    });

    test('updates when mode changes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentModeProvider), OperationalMode.sar);

      await container
          .read(operationalModeProvider.notifier)
          .set('backcountry');

      expect(container.read(currentModeProvider), OperationalMode.backcountry);
    });
  });
}
