import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/services/field_link/role_manager.dart';

void main() {
  late RoleManager manager;

  setUp(() {
    manager = RoleManager(localDeviceId: 'device-local');
  });

  group('initialization', () {
    test('session creator becomes lead', () {
      manager.initializeAsCreator();
      expect(manager.localRole, TeamRole.lead);
      expect(manager.isLead, isTrue);
    });

    test('session joiner becomes scout by default', () {
      manager.initializeAsJoiner();
      expect(manager.localRole, TeamRole.scout);
      expect(manager.isLead, isFalse);
    });
  });

  group('role assignment', () {
    test('lead can assign roles to peers', () {
      manager.initializeAsCreator();
      final result = manager.assignRole('peer-1', TeamRole.medic);

      expect(result, isTrue);
      expect(manager.roleForPeer('peer-1'), TeamRole.medic);
    });

    test('non-lead cannot assign roles', () {
      manager.initializeAsJoiner();
      final result = manager.assignRole('peer-1', TeamRole.medic);

      expect(result, isFalse);
      expect(manager.roleForPeer('peer-1'), TeamRole.scout);
    });

    test('lead can promote another peer to lead (transfers role)', () {
      manager.initializeAsCreator();
      manager.promotePeerToLead('peer-1');

      expect(manager.roleForPeer('peer-1'), TeamRole.lead);
      expect(manager.localRole, TeamRole.scout);
      expect(manager.isLead, isFalse);
    });

    test('non-lead cannot promote peer', () {
      manager.initializeAsJoiner();
      manager.promotePeerToLead('peer-1');

      // Should remain unchanged
      expect(manager.localRole, TeamRole.scout);
      expect(manager.roleForPeer('peer-1'), TeamRole.scout);
    });
  });

  group('remote state application', () {
    test('applyRemoteRoleChange updates local role when target is local', () {
      manager.initializeAsJoiner();
      manager.applyRemoteRoleChange(
        'device-local',
        TeamRole.medic,
        fromLeader: 'leader-1',
      );

      expect(manager.localRole, TeamRole.medic);
    });

    test('applyRemoteRoleChange updates peer role when target is peer', () {
      manager.applyRemoteRoleChange(
        'peer-2',
        TeamRole.comms,
        fromLeader: 'leader-1',
      );

      expect(manager.roleForPeer('peer-2'), TeamRole.comms);
    });

    test('applyRemoteRoleChange stores custom label', () {
      manager.applyRemoteRoleChange(
        'peer-2',
        TeamRole.custom,
        fromLeader: 'leader-1',
        customLabel: 'Navigator',
      );

      expect(manager.roleForPeer('peer-2'), TeamRole.custom);
      expect(manager.customLabelForPeer('peer-2'), 'Navigator');
    });

    test('applyRemoteCallsign stores peer callsign', () {
      manager.applyRemoteCallsign('peer-1', 'Alpha');
      expect(manager.callsignForPeer('peer-1'), 'Alpha');
    });
  });

  group('encoding', () {
    test('encodeRoleAssignment produces control payload when lead', () {
      manager.initializeAsCreator();
      final payload = manager.encodeRoleAssignment('peer-1', TeamRole.medic);

      expect(payload, isNotNull);
      expect(payload!['evt'], 'role_assign');
      expect(payload['target'], 'peer-1');
      expect(payload['role'], 'medic');
    });

    test('encodeRoleAssignment includes customLabel when provided', () {
      manager.initializeAsCreator();
      final payload = manager.encodeRoleAssignment(
        'peer-1',
        TeamRole.custom,
        customLabel: 'Navigator',
      );

      expect(payload, isNotNull);
      expect(payload!['crl'], 'Navigator');
    });

    test('encodeRoleAssignment returns null when not lead', () {
      manager.initializeAsJoiner();
      final payload = manager.encodeRoleAssignment('peer-1', TeamRole.medic);

      expect(payload, isNull);
    });

    test('encodeCallsignUpdate produces callsign payload', () {
      manager.setCallsign('Bravo');
      final payload = manager.encodeCallsignUpdate();

      expect(payload['evt'], 'callsign_update');
      expect(payload['cs'], 'Bravo');
    });
  });

  group('handleControlEvent', () {
    test('processes role_assign event from leader', () {
      // Register leader-1 as lead peer first.
      manager.applyRemoteRoleChange(
        'leader-1',
        TeamRole.lead,
        fromLeader: 'leader-1',
      );

      manager.handleControlEvent({
        'evt': 'role_assign',
        'target': 'device-local',
        'role': 'medic',
      }, 'leader-1');

      expect(manager.localRole, TeamRole.medic);
    });

    test('processes role_assign for peer target from leader', () {
      // Register leader-1 as lead peer first.
      manager.applyRemoteRoleChange(
        'leader-1',
        TeamRole.lead,
        fromLeader: 'leader-1',
      );

      manager.handleControlEvent({
        'evt': 'role_assign',
        'target': 'peer-2',
        'role': 'comms',
      }, 'leader-1');

      expect(manager.roleForPeer('peer-2'), TeamRole.comms);
    });

    test('non-lead peer cannot assign roles via control event', () {
      manager.initializeAsJoiner();

      manager.handleControlEvent({
        'evt': 'role_assign',
        'target': 'device-local',
        'role': 'medic',
      }, 'non-leader-peer');

      // Should remain unchanged — non-leader cannot assign roles.
      expect(manager.localRole, TeamRole.scout);
    });

    test('custom role label is preserved through control event round-trip', () {
      // Set up a lead manager to encode the assignment.
      final leadManager = RoleManager(localDeviceId: 'leader-1');
      leadManager.initializeAsCreator();
      final payload = leadManager.encodeRoleAssignment(
        'peer-2',
        TeamRole.custom,
        customLabel: 'Navigator',
      );

      expect(payload, isNotNull);
      expect(payload!['crl'], 'Navigator');

      // On the receiving side, register leader-1 as lead.
      manager.applyRemoteRoleChange(
        'leader-1',
        TeamRole.lead,
        fromLeader: 'leader-1',
      );

      // Process the encoded payload as a control event.
      manager.handleControlEvent(payload, 'leader-1');

      expect(manager.roleForPeer('peer-2'), TeamRole.custom);
      expect(manager.customLabelForPeer('peer-2'), 'Navigator');
    });

    test('processes callsign_update event', () {
      manager.handleControlEvent({
        'evt': 'callsign_update',
        'cs': 'Charlie',
      }, 'peer-3');

      expect(manager.callsignForPeer('peer-3'), 'Charlie');
    });

    test('handles callsign_update with null cs gracefully', () {
      manager.handleControlEvent({
        'evt': 'callsign_update',
      }, 'peer-3');

      expect(manager.callsignForPeer('peer-3'), '');
    });
  });

  group('callsign', () {
    test('defaults to empty string', () {
      expect(manager.callsign, '');
    });

    test('setCallsign updates callsign', () {
      manager.setCallsign('Delta');
      expect(manager.callsign, 'Delta');
    });

    test('callsignForPeer defaults to empty for unknown peer', () {
      expect(manager.callsignForPeer('unknown'), '');
    });
  });

  group('reset', () {
    test('clears all state including custom labels', () {
      manager.initializeAsCreator();
      manager.setCallsign('Echo');
      manager.assignRole('peer-1', TeamRole.medic);
      manager.applyRemoteCallsign('peer-1', 'Foxtrot');
      // Store a custom label via remote role change (local is lead).
      manager.applyRemoteRoleChange(
        'peer-2',
        TeamRole.custom,
        fromLeader: 'device-local',
        customLabel: 'Navigator',
      );

      manager.reset();

      expect(manager.localRole, TeamRole.scout);
      expect(manager.isLead, isFalse);
      expect(manager.callsign, '');
      expect(manager.roleForPeer('peer-1'), TeamRole.scout);
      expect(manager.callsignForPeer('peer-1'), '');
      expect(manager.customLabelForPeer('peer-2'), isNull);
    });
  });

  group('peer queries', () {
    test('roleForPeer defaults to scout for unknown peer', () {
      expect(manager.roleForPeer('unknown'), TeamRole.scout);
    });
  });
}
