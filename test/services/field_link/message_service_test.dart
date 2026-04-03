import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/tactical_message.dart';
import 'package:red_grid_link/services/field_link/message_service.dart';

void main() {
  late MessageService service;

  setUp(() {
    service = MessageService();
  });

  tearDown(() {
    service.dispose();
  });

  TacticalMessage _makeMessage({
    TacticalMessageType type = TacticalMessageType.help,
    String senderId = 'peer-1',
    String callsign = 'Alpha',
  }) {
    return TacticalMessage(
      senderId: senderId,
      senderCallsign: callsign,
      type: type,
      timestamp: DateTime.now(),
    );
  }

  group('addMessage', () {
    test('adds to history', () {
      final msg = _makeMessage();
      service.addMessage(msg);

      expect(service.history, hasLength(1));
      expect(service.history.first, msg);
    });

    test('inserts at front (most recent first)', () {
      final msg1 = _makeMessage(callsign: 'Alpha');
      final msg2 = _makeMessage(callsign: 'Bravo');

      service.addMessage(msg1);
      service.addMessage(msg2);

      expect(service.history.first.senderCallsign, 'Bravo');
      expect(service.history.last.senderCallsign, 'Alpha');
    });

    test('emits on stream', () async {
      final msg = _makeMessage();

      expectLater(
        service.onMessage,
        emits(msg),
      );

      service.addMessage(msg);
    });

    test('emits multiple messages in order', () async {
      final msg1 = _makeMessage(type: TacticalMessageType.help);
      final msg2 = _makeMessage(type: TacticalMessageType.stop);

      expectLater(
        service.onMessage,
        emitsInOrder([msg1, msg2]),
      );

      service.addMessage(msg1);
      service.addMessage(msg2);
    });
  });

  group('history limit', () {
    test('limits to maxHistory entries', () {
      for (var i = 0; i < MessageService.maxHistory + 10; i++) {
        service.addMessage(_makeMessage(callsign: 'Peer-$i'));
      }

      expect(service.history, hasLength(MessageService.maxHistory));
    });

    test('keeps most recent messages when over limit', () {
      for (var i = 0; i < MessageService.maxHistory + 5; i++) {
        service.addMessage(_makeMessage(callsign: 'Peer-$i'));
      }

      // Most recent should be the last added.
      final lastIndex = MessageService.maxHistory + 5 - 1;
      expect(service.history.first.senderCallsign, 'Peer-$lastIndex');
    });
  });

  group('clear', () {
    test('empties history', () {
      service.addMessage(_makeMessage());
      service.addMessage(_makeMessage());
      expect(service.history, hasLength(2));

      service.clear();
      expect(service.history, isEmpty);
    });
  });

  group('history immutability', () {
    test('returned list is unmodifiable', () {
      service.addMessage(_makeMessage());
      final history = service.history;

      expect(
        () => history.add(_makeMessage()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
