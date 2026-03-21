import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/marker.dart';

void main() {
  group('MarkerIcon', () {
    test('fromString maps old "danger" to hazard', () {
      expect(MarkerIcon.fromString('danger'), MarkerIcon.hazard);
    });

    test('fromString maps old "rally" to rallyPoint', () {
      expect(MarkerIcon.fromString('rally'), MarkerIcon.rallyPoint);
    });

    test('fromString parses "hazard"', () {
      expect(MarkerIcon.fromString('hazard'), MarkerIcon.hazard);
    });

    test('fromString parses "rallyPoint" (case-insensitive)', () {
      expect(MarkerIcon.fromString('rallypoint'), MarkerIcon.rallyPoint);
      expect(MarkerIcon.fromString('rallyPoint'), MarkerIcon.rallyPoint);
    });

    test('fromString parses new "objective" value', () {
      expect(MarkerIcon.fromString('objective'), MarkerIcon.objective);
    });

    test('fromString parses new "cache" value', () {
      expect(MarkerIcon.fromString('cache'), MarkerIcon.cache);
    });

    test('fromString defaults to waypoint for unknown values', () {
      expect(MarkerIcon.fromString('unknown'), MarkerIcon.waypoint);
      expect(MarkerIcon.fromString(''), MarkerIcon.waypoint);
    });

    test('all enum values round-trip through fromString', () {
      for (final icon in MarkerIcon.values) {
        final parsed = MarkerIcon.fromString(icon.name);
        expect(parsed, icon, reason: '${icon.name} should round-trip');
      }
    });
  });

  group('MarkerOrigin', () {
    test('fromString parses "manual"', () {
      expect(MarkerOrigin.fromString('manual'), MarkerOrigin.manual);
    });

    test('fromString parses "sw" to sharedWaypoint', () {
      expect(MarkerOrigin.fromString('sw'), MarkerOrigin.sharedWaypoint);
    });

    test('fromString parses "sharedWaypoint" (case-insensitive)', () {
      expect(
        MarkerOrigin.fromString('sharedwaypoint'),
        MarkerOrigin.sharedWaypoint,
      );
      expect(
        MarkerOrigin.fromString('sharedWaypoint'),
        MarkerOrigin.sharedWaypoint,
      );
    });

    test('fromString defaults to manual for unknown values', () {
      expect(MarkerOrigin.fromString('unknown'), MarkerOrigin.manual);
      expect(MarkerOrigin.fromString(''), MarkerOrigin.manual);
    });

    test('toShortString returns compact keys', () {
      expect(MarkerOrigin.manual.toShortString(), 'manual');
      expect(MarkerOrigin.sharedWaypoint.toShortString(), 'sw');
    });

    test('round-trip through toShortString and fromString', () {
      for (final origin in MarkerOrigin.values) {
        final shortStr = origin.toShortString();
        final parsed = MarkerOrigin.fromString(shortStr);
        expect(parsed, origin, reason: '${origin.name} should round-trip');
      }
    });
  });

  group('Marker', () {
    final now = DateTime(2026, 3, 21, 12, 0);

    Marker makeMarker({
      MarkerIcon icon = MarkerIcon.waypoint,
      MarkerOrigin origin = MarkerOrigin.manual,
    }) =>
        Marker(
          id: 'test-1',
          lat: 38.8977,
          lon: -77.0365,
          mgrs: '18SUJ2337106519',
          label: 'Test Marker',
          icon: icon,
          createdBy: 'user-1',
          createdAt: now,
          color: 0xFFFF0000,
          isSynced: true,
          origin: origin,
        );

    test('toJson includes origin field', () {
      final marker = makeMarker(origin: MarkerOrigin.sharedWaypoint);
      final json = marker.toJson();
      expect(json['o'], 'sw');
    });

    test('toJson includes origin as "manual" by default', () {
      final marker = makeMarker();
      final json = marker.toJson();
      expect(json['o'], 'manual');
    });

    test('fromJson parses origin', () {
      final marker = makeMarker(origin: MarkerOrigin.sharedWaypoint);
      final json = marker.toJson();
      final parsed = Marker.fromJson(json);
      expect(parsed.origin, MarkerOrigin.sharedWaypoint);
    });

    test('fromJson defaults origin to manual when missing', () {
      final json = makeMarker().toJson();
      json.remove('o');
      final parsed = Marker.fromJson(json);
      expect(parsed.origin, MarkerOrigin.manual);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      final marker = makeMarker(
        icon: MarkerIcon.cache,
        origin: MarkerOrigin.sharedWaypoint,
      );
      final json = marker.toJson();
      final parsed = Marker.fromJson(json);

      expect(parsed.id, marker.id);
      expect(parsed.lat, marker.lat);
      expect(parsed.lon, marker.lon);
      expect(parsed.mgrs, marker.mgrs);
      expect(parsed.label, marker.label);
      expect(parsed.icon, marker.icon);
      expect(parsed.createdBy, marker.createdBy);
      expect(parsed.createdAt, marker.createdAt);
      expect(parsed.color, marker.color);
      expect(parsed.isSynced, marker.isSynced);
      expect(parsed.origin, marker.origin);
    });

    test('fromJson handles legacy "danger" icon', () {
      final json = makeMarker().toJson();
      json['ico'] = 'danger';
      final parsed = Marker.fromJson(json);
      expect(parsed.icon, MarkerIcon.hazard);
    });

    test('fromJson handles legacy "rally" icon', () {
      final json = makeMarker().toJson();
      json['ico'] = 'rally';
      final parsed = Marker.fromJson(json);
      expect(parsed.icon, MarkerIcon.rallyPoint);
    });

    test('copyWith updates origin', () {
      final marker = makeMarker();
      final updated = marker.copyWith(origin: MarkerOrigin.sharedWaypoint);
      expect(updated.origin, MarkerOrigin.sharedWaypoint);
      expect(updated.id, marker.id);
    });

    test('copyWith preserves origin when not specified', () {
      final marker = makeMarker(origin: MarkerOrigin.sharedWaypoint);
      final updated = marker.copyWith(label: 'New Label');
      expect(updated.origin, MarkerOrigin.sharedWaypoint);
      expect(updated.label, 'New Label');
    });

    test('default origin is manual', () {
      final marker = Marker(
        id: 'x',
        lat: 0,
        lon: 0,
        createdBy: 'u',
        createdAt: now,
      );
      expect(marker.origin, MarkerOrigin.manual);
    });
  });
}
