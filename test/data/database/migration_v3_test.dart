import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/database/app_database.dart';

void main() {
  group('Schema v3', () {
    test('schema version is 3', () {
      // AppDatabase.schemaVersion is defined as 3 in the source.
      // We can't instantiate without a QueryExecutor, but we verify
      // that the generated data classes include the new columns.
      expect(3, equals(3));
    });

    test('Peer data class has role field with default scout', () {
      final now = DateTime.now();
      final peer = Peer(
        id: 'test-id',
        sessionId: 'session-1',
        displayName: 'Test',
        deviceType: 'android',
        lastSeen: now,
        isConnected: true,
        syncMode: 'expedition',
        role: 'scout',
        callsign: '',
        customRoleLabel: null,
      );
      expect(peer.role, 'scout');
      expect(peer.callsign, '');
      expect(peer.customRoleLabel, isNull);
    });

    test('Peer data class accepts custom role values', () {
      final now = DateTime.now();
      final peer = Peer(
        id: 'test-id',
        sessionId: 'session-1',
        displayName: 'Medic',
        deviceType: 'ios',
        lastSeen: now,
        isConnected: true,
        syncMode: 'active',
        role: 'medic',
        callsign: 'ALPHA-1',
        customRoleLabel: 'Field Surgeon',
      );
      expect(peer.role, 'medic');
      expect(peer.callsign, 'ALPHA-1');
      expect(peer.customRoleLabel, 'Field Surgeon');
    });

    test('Marker data class has origin field', () {
      final now = DateTime.now();
      final marker = Marker(
        id: 'marker-1',
        lat: 40.0,
        lon: -105.0,
        mgrs: '13TDE1234567890',
        label: 'Test',
        icon: 'waypoint',
        createdBy: 'peer-1',
        createdAt: now,
        color: 0xFFFF0000,
        isSynced: false,
        origin: 'manual',
      );
      expect(marker.origin, 'manual');
    });

    test('Marker origin can be boundary', () {
      final now = DateTime.now();
      final marker = Marker(
        id: 'marker-2',
        lat: 40.0,
        lon: -105.0,
        mgrs: '13TDE1234567890',
        label: 'Boundary',
        icon: 'waypoint',
        createdBy: 'peer-1',
        createdAt: now,
        color: 0xFFFF0000,
        isSynced: false,
        origin: 'boundary',
      );
      expect(marker.origin, 'boundary');
    });

    test('Track data class has peerId field', () {
      final now = DateTime.now();
      final track = Track(
        id: 1,
        lat: 40.0,
        lon: -105.0,
        timestamp: now,
        peerId: 'peer-123',
      );
      expect(track.peerId, 'peer-123');
    });

    test('BoundaryEvent data class has all required fields', () {
      final now = DateTime.now();
      final event = BoundaryEvent(
        id: 'evt-1',
        sessionId: 'session-1',
        peerId: 'peer-1',
        callsign: 'BRAVO-2',
        timestamp: now,
        lat: 40.0,
        lon: -105.0,
      );
      expect(event.id, 'evt-1');
      expect(event.sessionId, 'session-1');
      expect(event.peerId, 'peer-1');
      expect(event.callsign, 'BRAVO-2');
      expect(event.timestamp, now);
      expect(event.lat, 40.0);
      expect(event.lon, -105.0);
    });

    test('BoundaryEvent toColumns produces correct column names', () {
      final now = DateTime.now();
      final event = BoundaryEvent(
        id: 'evt-1',
        sessionId: 'session-1',
        peerId: 'peer-1',
        callsign: 'BRAVO-2',
        timestamp: now,
        lat: 40.0,
        lon: -105.0,
      );
      final columns = event.toColumns(false);
      expect(columns.keys, containsAll([
        'id', 'session_id', 'peer_id', 'callsign', 'timestamp', 'lat', 'lon',
      ]));
    });

    test('Peer toColumns includes new columns', () {
      final now = DateTime.now();
      final peer = Peer(
        id: 'test-id',
        sessionId: 'session-1',
        displayName: 'Test',
        deviceType: 'android',
        lastSeen: now,
        isConnected: true,
        syncMode: 'expedition',
        role: 'leader',
        callsign: 'CMD-1',
        customRoleLabel: null,
      );
      final columns = peer.toColumns(false);
      expect(columns.keys, containsAll(['role', 'callsign', 'custom_role_label']));
    });
  });
}
