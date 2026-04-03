import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/tactical_message.dart';

void main() {
  group('TacticalMessageType.fromString', () {
    test('parses all known types', () {
      for (final type in TacticalMessageType.values) {
        expect(
          TacticalMessageType.fromString(type.name),
          type,
          reason: 'Failed to parse ${type.name}',
        );
      }
    });

    test('defaults to custom for unknown value', () {
      expect(
        TacticalMessageType.fromString('nonexistent'),
        TacticalMessageType.custom,
      );
    });

    test('defaults to custom for empty string', () {
      expect(
        TacticalMessageType.fromString(''),
        TacticalMessageType.custom,
      );
    });
  });

  group('TacticalMessageType properties', () {
    test('all types have non-empty label', () {
      for (final type in TacticalMessageType.values) {
        expect(type.label, isNotEmpty, reason: '${type.name} label is empty');
      }
    });

    test('all types have non-empty icon', () {
      for (final type in TacticalMessageType.values) {
        expect(type.icon, isNotEmpty, reason: '${type.name} icon is empty');
      }
    });
  });

  group('TacticalMessage.toJson', () {
    test('produces correct payload for pre-canned message', () {
      final msg = TacticalMessage(
        senderId: 'device-1',
        senderCallsign: 'Alpha',
        type: TacticalMessageType.help,
        timestamp: DateTime(2026, 1, 1),
      );

      final json = msg.toJson();
      expect(json['evt'], 'message');
      expect(json['mt'], 'help');
      expect(json.containsKey('txt'), isFalse);
    });

    test('includes txt for custom message with text', () {
      final msg = TacticalMessage(
        senderId: 'device-1',
        senderCallsign: 'Alpha',
        type: TacticalMessageType.custom,
        customText: 'Meet at waypoint 3',
        timestamp: DateTime(2026, 1, 1),
      );

      final json = msg.toJson();
      expect(json['evt'], 'message');
      expect(json['mt'], 'custom');
      expect(json['txt'], 'Meet at waypoint 3');
    });

    test('omits txt when customText is null', () {
      final msg = TacticalMessage(
        senderId: 'device-1',
        senderCallsign: 'Alpha',
        type: TacticalMessageType.custom,
        timestamp: DateTime(2026, 1, 1),
      );

      expect(msg.toJson().containsKey('txt'), isFalse);
    });

    test('omits txt when customText is empty', () {
      final msg = TacticalMessage(
        senderId: 'device-1',
        senderCallsign: 'Alpha',
        type: TacticalMessageType.custom,
        customText: '',
        timestamp: DateTime(2026, 1, 1),
      );

      expect(msg.toJson().containsKey('txt'), isFalse);
    });
  });

  group('TacticalMessage.fromControl', () {
    test('parses pre-canned message correctly', () {
      final msg = TacticalMessage.fromControl(
        'peer-1',
        'Bravo',
        {'evt': 'message', 'mt': 'stop'},
      );

      expect(msg.senderId, 'peer-1');
      expect(msg.senderCallsign, 'Bravo');
      expect(msg.type, TacticalMessageType.stop);
      expect(msg.customText, isNull);
    });

    test('parses custom message with text', () {
      final msg = TacticalMessage.fromControl(
        'peer-2',
        'Charlie',
        {'evt': 'message', 'mt': 'custom', 'txt': 'On my way'},
      );

      expect(msg.senderId, 'peer-2');
      expect(msg.senderCallsign, 'Charlie');
      expect(msg.type, TacticalMessageType.custom);
      expect(msg.customText, 'On my way');
    });

    test('defaults to custom when mt is missing', () {
      final msg = TacticalMessage.fromControl(
        'peer-3',
        'Delta',
        {'evt': 'message'},
      );

      expect(msg.type, TacticalMessageType.custom);
    });

    test('defaults to custom when mt is unknown', () {
      final msg = TacticalMessage.fromControl(
        'peer-3',
        'Delta',
        {'evt': 'message', 'mt': 'unknown_type'},
      );

      expect(msg.type, TacticalMessageType.custom);
    });

    test('has a valid timestamp', () {
      final before = DateTime.now();
      final msg = TacticalMessage.fromControl(
        'peer-1',
        'Echo',
        {'evt': 'message', 'mt': 'help'},
      );
      final after = DateTime.now();

      expect(msg.timestamp.isAfter(before) || msg.timestamp == before, isTrue);
      expect(msg.timestamp.isBefore(after) || msg.timestamp == after, isTrue);
    });
  });
}
