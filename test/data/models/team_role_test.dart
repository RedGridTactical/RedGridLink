import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/team_role.dart';

void main() {
  group('TeamRole', () {
    group('fromString', () {
      test('parses lead', () {
        expect(TeamRole.fromString('lead'), TeamRole.lead);
      });

      test('parses scout', () {
        expect(TeamRole.fromString('scout'), TeamRole.scout);
      });

      test('parses medic', () {
        expect(TeamRole.fromString('medic'), TeamRole.medic);
      });

      test('parses comms', () {
        expect(TeamRole.fromString('comms'), TeamRole.comms);
      });

      test('parses custom', () {
        expect(TeamRole.fromString('custom'), TeamRole.custom);
      });

      test('is case-insensitive', () {
        expect(TeamRole.fromString('LEAD'), TeamRole.lead);
        expect(TeamRole.fromString('Medic'), TeamRole.medic);
        expect(TeamRole.fromString('COMMS'), TeamRole.comms);
      });

      test('defaults to scout for unknown values', () {
        expect(TeamRole.fromString('unknown'), TeamRole.scout);
        expect(TeamRole.fromString(''), TeamRole.scout);
        expect(TeamRole.fromString('operator'), TeamRole.scout);
      });
    });

    group('toShortString', () {
      test('returns compact key for each role', () {
        expect(TeamRole.lead.toShortString(), 'lead');
        expect(TeamRole.scout.toShortString(), 'scout');
        expect(TeamRole.medic.toShortString(), 'medic');
        expect(TeamRole.comms.toShortString(), 'comms');
        expect(TeamRole.custom.toShortString(), 'custom');
      });
    });

    group('displayName', () {
      test('returns human-readable label for each role', () {
        expect(TeamRole.lead.displayName, 'Lead');
        expect(TeamRole.scout.displayName, 'Scout');
        expect(TeamRole.medic.displayName, 'Medic');
        expect(TeamRole.comms.displayName, 'Comms');
        expect(TeamRole.custom.displayName, 'Custom');
      });
    });

    group('isLead', () {
      test('returns true only for lead', () {
        expect(TeamRole.lead.isLead, isTrue);
      });

      test('returns false for all other roles', () {
        expect(TeamRole.scout.isLead, isFalse);
        expect(TeamRole.medic.isLead, isFalse);
        expect(TeamRole.comms.isLead, isFalse);
        expect(TeamRole.custom.isLead, isFalse);
      });
    });
  });
}
