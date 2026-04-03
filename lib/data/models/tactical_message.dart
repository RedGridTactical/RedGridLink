/// Pre-defined tactical messages for quick team communication.
enum TacticalMessageType {
  help,
  stop,
  rallyOnMe,
  allClear,
  foundSomething,
  headingBack,
  needSupplies,
  custom;

  String get label {
    switch (this) {
      case TacticalMessageType.help:
        return 'HELP';
      case TacticalMessageType.stop:
        return 'STOP / HOLD';
      case TacticalMessageType.rallyOnMe:
        return 'RALLY ON ME';
      case TacticalMessageType.allClear:
        return 'ALL CLEAR';
      case TacticalMessageType.foundSomething:
        return 'FOUND SOMETHING';
      case TacticalMessageType.headingBack:
        return 'HEADING BACK';
      case TacticalMessageType.needSupplies:
        return 'NEED SUPPLIES';
      case TacticalMessageType.custom:
        return 'MESSAGE';
    }
  }

  String get icon {
    switch (this) {
      case TacticalMessageType.help:
        return '!';
      case TacticalMessageType.stop:
        return 'X';
      case TacticalMessageType.rallyOnMe:
        return 'R';
      case TacticalMessageType.allClear:
        return 'OK';
      case TacticalMessageType.foundSomething:
        return '?';
      case TacticalMessageType.headingBack:
        return '<';
      case TacticalMessageType.needSupplies:
        return 'S';
      case TacticalMessageType.custom:
        return 'M';
    }
  }

  static TacticalMessageType fromString(String value) {
    return TacticalMessageType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TacticalMessageType.custom,
    );
  }
}

/// A tactical message sent between peers.
class TacticalMessage {
  final String senderId;
  final String senderCallsign;
  final TacticalMessageType type;
  final String? customText; // Only for TacticalMessageType.custom
  final DateTime timestamp;

  const TacticalMessage({
    required this.senderId,
    required this.senderCallsign,
    required this.type,
    this.customText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'evt': 'message',
        'mt': type.name,
        if (customText != null && customText!.isNotEmpty) 'txt': customText,
      };

  factory TacticalMessage.fromControl(
    String senderId,
    String senderCallsign,
    Map<String, dynamic> data,
  ) {
    return TacticalMessage(
      senderId: senderId,
      senderCallsign: senderCallsign,
      type: TacticalMessageType.fromString(data['mt'] as String? ?? 'custom'),
      customText: data['txt'] as String?,
      timestamp: DateTime.now(),
    );
  }
}
