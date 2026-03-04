import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/entitlement.dart';

void main() {
  group('Entitlement', () {
    test('has four tiers', () {
      expect(Entitlement.values, hasLength(4));
    });

    test('free tier has correct defaults', () {
      final e = Entitlement.free;
      expect(e.maxDevices, 2);
      expect(e.allModes, isTrue);
      expect(e.aarExport, isFalse);
      expect(e.allMapRegions, isFalse);
      expect(e.allThemes, isFalse);
      expect(e.fullFieldLink, isFalse);
    });

    test('pro tier has 2 devices and no fullFieldLink', () {
      final e = Entitlement.pro;
      expect(e.maxDevices, 2);
      expect(e.allModes, isTrue);
      expect(e.aarExport, isTrue);
      expect(e.allMapRegions, isTrue);
      expect(e.allThemes, isTrue);
      expect(e.fullFieldLink, isFalse);
    });

    test('proLink tier has 8 devices and fullFieldLink', () {
      final e = Entitlement.proLink;
      expect(e.maxDevices, 8);
      expect(e.allModes, isTrue);
      expect(e.aarExport, isTrue);
      expect(e.allMapRegions, isTrue);
      expect(e.allThemes, isTrue);
      expect(e.fullFieldLink, isTrue);
    });

    test('team tier has 8 devices and fullFieldLink', () {
      final e = Entitlement.team;
      expect(e.maxDevices, 8);
      expect(e.allModes, isTrue);
      expect(e.aarExport, isTrue);
      expect(e.allMapRegions, isTrue);
      expect(e.allThemes, isTrue);
      expect(e.fullFieldLink, isTrue);
    });

    test('free tier name is free', () {
      expect(Entitlement.free.name, 'free');
    });

    test('pro tier name is pro', () {
      expect(Entitlement.pro.name, 'pro');
    });

    test('proLink tier name is proLink', () {
      expect(Entitlement.proLink.name, 'proLink');
    });

    test('team tier name is team', () {
      expect(Entitlement.team.name, 'team');
    });

    test('only proLink and team have fullFieldLink', () {
      for (final e in Entitlement.values) {
        if (e == Entitlement.proLink || e == Entitlement.team) {
          expect(e.fullFieldLink, isTrue, reason: '${e.name} should have fullFieldLink');
        } else {
          expect(e.fullFieldLink, isFalse, reason: '${e.name} should not have fullFieldLink');
        }
      }
    });

    test('only free and pro have 2 maxDevices', () {
      expect(Entitlement.free.maxDevices, 2);
      expect(Entitlement.pro.maxDevices, 2);
      expect(Entitlement.proLink.maxDevices, 8);
      expect(Entitlement.team.maxDevices, 8);
    });

    test('all tiers have allModes true', () {
      for (final e in Entitlement.values) {
        expect(e.allModes, isTrue, reason: '${e.name} should have allModes');
      }
    });
  });
}
