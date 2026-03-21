import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/data/models/peer.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';
import 'package:red_grid_link/services/field_link/role_manager.dart';
import 'package:red_grid_link/ui/common/role_icon.dart';
import 'package:red_grid_link/ui/screens/field_link/widgets/role_selector_dialog.dart';
import 'package:red_grid_link/ui/screens/field_link/widgets/team_roster_sheet.dart';

/// Minimal stub of FieldLinkService for testing the roster sheet.
///
/// Only [roleManager] and [localDeviceId] are used by TeamRosterSheet.
class _FakeFieldLinkService implements FieldLinkService {
  final RoleManager _roleManager;

  _FakeFieldLinkService({required RoleManager roleManager})
      : _roleManager = roleManager;

  @override
  RoleManager get roleManager => _roleManager;

  @override
  String get localDeviceId => 'local-device-id';

  // --- Stubs for unused members ---
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RoleManager roleManager;
  late StreamController<List<Peer>> peersController;

  final testPeers = [
    Peer(
      id: 'peer-1',
      displayName: 'Alpha',
      lastSeen: DateTime(2026, 3, 21),
      role: TeamRole.medic,
      callsign: 'DOC',
    ),
    Peer(
      id: 'peer-2',
      displayName: 'Bravo',
      lastSeen: DateTime(2026, 3, 21),
      role: TeamRole.scout,
      callsign: '',
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    peersController = StreamController<List<Peer>>.broadcast();
    roleManager = RoleManager(localDeviceId: 'local-device-id');
  });

  tearDown(() {
    peersController.close();
  });

  Widget buildSheet({
    TeamRole localRole = TeamRole.scout,
    bool isLead = false,
  }) {
    if (isLead) {
      roleManager.initializeAsCreator();
    } else {
      roleManager.initializeAsJoiner();
    }
    roleManager.setCallsign('LOCAL-CS');

    final fakeService = _FakeFieldLinkService(roleManager: roleManager);

    return ProviderScope(
      overrides: [
        fieldLinkServiceProvider.overrideWithValue(fakeService),
        localRoleProvider.overrideWithValue(localRole),
        isLeadProvider.overrideWithValue(isLead),
        localDeviceIdProvider.overrideWithValue('local-device-id'),
        connectedPeersProvider.overrideWith(
          (ref) => peersController.stream,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: TeamRosterSheet(),
        ),
      ),
    );
  }

  /// Pumps the widget and emits peers on the stream after subscription.
  Future<void> pumpWithPeers(
    WidgetTester tester, {
    TeamRole localRole = TeamRole.scout,
    bool isLead = false,
    List<Peer> peers = const [],
  }) async {
    await tester.pumpWidget(buildSheet(localRole: localRole, isLead: isLead));
    await tester.pump(); // let StreamProvider subscribe
    peersController.add(peers); // emit after subscription
    await tester.pump(); // process stream event
    await tester.pump(); // rebuild with data
  }

  group('TeamRosterSheet', () {
    testWidgets('renders title', (WidgetTester tester) async {
      await pumpWithPeers(tester);
      expect(find.text('TEAM ROSTER'), findsOneWidget);
    });

    testWidgets('renders local user with role and callsign',
        (WidgetTester tester) async {
      await pumpWithPeers(tester, localRole: TeamRole.lead);

      // Local callsign is shown
      expect(find.text('LOCAL-CS'), findsOneWidget);
      // Role label with (You) suffix
      expect(find.text('Lead (You)'), findsOneWidget);
      // Lead star icon
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders connected peers with role icons',
        (WidgetTester tester) async {
      await pumpWithPeers(tester, peers: testPeers);

      // Peer callsign is shown for peer-1
      expect(find.text('DOC'), findsOneWidget);
      // Peer displayName fallback for peer-2 (empty callsign)
      expect(find.text('Bravo'), findsOneWidget);
      // Medic icon for peer-1
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
      // Explore icon for peer-2 (scout) + local user (scout)
      expect(find.byIcon(Icons.explore), findsWidgets);
    });

    testWidgets('lead user sees manage buttons', (WidgetTester tester) async {
      await pumpWithPeers(
        tester,
        localRole: TeamRole.lead,
        isLead: true,
        peers: testPeers,
      );

      // PopupMenuButton with more_vert icon for each peer
      expect(find.byIcon(Icons.more_vert), findsNWidgets(testPeers.length));
    });

    testWidgets('non-lead user does not see manage buttons',
        (WidgetTester tester) async {
      await pumpWithPeers(
        tester,
        localRole: TeamRole.scout,
        isLead: false,
        peers: testPeers,
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('shows no peers message when list is empty',
        (WidgetTester tester) async {
      await pumpWithPeers(tester, peers: []);
      expect(find.text('No peers connected'), findsOneWidget);
    });
  });

  group('RoleSelectorDialog', () {
    testWidgets('shows all role options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RoleSelectorDialog(),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump();

      expect(find.text('SELECT ROLE'), findsOneWidget);
      for (final role in TeamRole.values) {
        expect(find.text(role.displayName), findsOneWidget);
      }
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);
    });

    testWidgets('shows custom label field when custom selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RoleSelectorDialog(),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump();

      // Tap on Custom radio
      await tester.tap(find.text('Custom'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Custom role label'), findsOneWidget);
    });
  });

  group('iconForRole', () {
    test('maps all roles to distinct icons', () {
      expect(iconForRole(TeamRole.lead), Icons.star);
      expect(iconForRole(TeamRole.scout), Icons.explore);
      expect(iconForRole(TeamRole.medic), Icons.medical_services);
      expect(iconForRole(TeamRole.comms), Icons.cell_tower);
      expect(iconForRole(TeamRole.custom), Icons.person);
    });
  });
}
