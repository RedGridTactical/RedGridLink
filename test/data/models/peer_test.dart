import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/team_role.dart';

void main() {
  final now = DateTime(2026, 3, 21, 12, 0, 0);

  Peer makePeer({
    TeamRole role = TeamRole.scout,
    String callsign = '',
    String? customRoleLabel,
  }) =>
      Peer(
        id: 'peer-1',
        displayName: 'Alpha',
        lastSeen: now,
        role: role,
        callsign: callsign,
        customRoleLabel: customRoleLabel,
      );

  group('Peer role fields', () {
    test('default role is scout', () {
      final peer = Peer(
        id: 'peer-1',
        displayName: 'Alpha',
        lastSeen: now,
      );
      expect(peer.role, TeamRole.scout);
      expect(peer.callsign, '');
      expect(peer.customRoleLabel, isNull);
    });

    test('accepts role, callsign, and customRoleLabel', () {
      final peer = makePeer(
        role: TeamRole.medic,
        callsign: 'DOC',
        customRoleLabel: 'Field Surgeon',
      );
      expect(peer.role, TeamRole.medic);
      expect(peer.callsign, 'DOC');
      expect(peer.customRoleLabel, 'Field Surgeon');
    });
  });

  group('Peer toJson', () {
    test('includes role and callsign', () {
      final json = makePeer(
        role: TeamRole.lead,
        callsign: 'CMD',
      ).toJson();
      expect(json['role'], 'lead');
      expect(json['cs'], 'CMD');
    });

    test('includes customRoleLabel when set', () {
      final json = makePeer(
        role: TeamRole.custom,
        customRoleLabel: 'Drone Op',
      ).toJson();
      expect(json['crl'], 'Drone Op');
    });

    test('omits customRoleLabel when null', () {
      final json = makePeer().toJson();
      expect(json.containsKey('crl'), isFalse);
    });
  });

  group('Peer fromJson', () {
    test('parses role and callsign', () {
      final json = makePeer(
        role: TeamRole.comms,
        callsign: 'RADIO',
      ).toJson();
      final parsed = Peer.fromJson(json);
      expect(parsed.role, TeamRole.comms);
      expect(parsed.callsign, 'RADIO');
    });

    test('parses customRoleLabel', () {
      final json = makePeer(
        role: TeamRole.custom,
        customRoleLabel: 'Navigator',
      ).toJson();
      final parsed = Peer.fromJson(json);
      expect(parsed.customRoleLabel, 'Navigator');
    });

    test('defaults role to scout when missing from json', () {
      final json = makePeer().toJson();
      json.remove('role');
      json.remove('cs');
      final parsed = Peer.fromJson(json);
      expect(parsed.role, TeamRole.scout);
      expect(parsed.callsign, '');
    });
  });

  group('Peer copyWith', () {
    test('preserves role fields when not overridden', () {
      final peer = makePeer(
        role: TeamRole.medic,
        callsign: 'DOC',
        customRoleLabel: 'Paramedic',
      );
      final copy = peer.copyWith(displayName: 'Bravo');
      expect(copy.role, TeamRole.medic);
      expect(copy.callsign, 'DOC');
      expect(copy.customRoleLabel, 'Paramedic');
      expect(copy.displayName, 'Bravo');
    });

    test('overrides role fields', () {
      final peer = makePeer(role: TeamRole.scout);
      final copy = peer.copyWith(
        role: TeamRole.lead,
        callsign: 'BOSS',
      );
      expect(copy.role, TeamRole.lead);
      expect(copy.callsign, 'BOSS');
    });
  });
}
