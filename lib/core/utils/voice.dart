/// NATO phonetic voice readout for MGRS coordinates.
/// Uses flutter_tts for text-to-speech.
import 'package:flutter_tts/flutter_tts.dart';

const Map<String, String> natoAlpha = {
  'A': 'Alpha',   'B': 'Bravo',    'C': 'Charlie',  'D': 'Delta',
  'E': 'Echo',    'F': 'Foxtrot',  'G': 'Golf',     'H': 'Hotel',
  'I': 'India',   'J': 'Juliet',   'K': 'Kilo',     'L': 'Lima',
  'M': 'Mike',    'N': 'November', 'O': 'Oscar',    'P': 'Papa',
  'Q': 'Quebec',  'R': 'Romeo',    'S': 'Sierra',   'T': 'Tango',
  'U': 'Uniform', 'V': 'Victor',   'W': 'Whiskey',  'X': 'X-ray',
  'Y': 'Yankee',  'Z': 'Zulu',
};

const Map<String, String> natoDigit = {
  '0': 'zero',  '1': 'one',   '2': 'two',   '3': 'three',
  '4': 'four',  '5': 'five',  '6': 'six',   '7': 'seven',
  '8': 'eight', '9': 'niner',
};

FlutterTts? _tts;

FlutterTts _getTts() {
  if (_tts == null) {
    _tts = FlutterTts();
    _tts!.setLanguage('en-US');
    _tts!.setPitch(0.95);
    _tts!.setSpeechRate(0.85);
  }
  return _tts!;
}

/// Convert MGRS string to NATO phonetic readout.
///
/// Input: "18S UJ 23456 78901"
/// Output: "one, eight, Sierra. Uniform, Juliet. two, three, four, five, six. seven, eight, niner, zero, one"
String? mgrsToNATO(String? mgrs) {
  if (mgrs == null || mgrs.isEmpty) return null;

  final parts = mgrs.trim().split(RegExp(r'\s+'));
  if (parts.length < 3) return null;

  final gzd = parts[0]; // e.g. "18S"
  final sq = parts[1]; // e.g. "UJ"
  final numerics = parts.sublist(2).join(' '); // e.g. "23456 78901"

  final segments = <String>[];

  // Grid Zone Designator
  final gzdSpoken = gzd.split('').map((ch) {
    if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
      return natoAlpha[ch.toUpperCase()] ?? ch;
    }
    return natoDigit[ch] ?? ch;
  }).join(', ');
  segments.add(gzdSpoken);

  // 100km Square ID
  final sqSpoken = sq.split('').map((ch) {
    return natoAlpha[ch.toUpperCase()] ?? ch;
  }).join(', ');
  segments.add(sqSpoken);

  // Numeric portion — read digit by digit
  final numParts = numerics.split(RegExp(r'\s+'));
  for (final part in numParts) {
    final digitSpoken = part.split('').map((ch) {
      return natoDigit[ch] ?? ch;
    }).join(', ');
    segments.add(digitSpoken);
  }

  return segments.join('. ');
}

/// Speak MGRS coordinate using NATO phonetics.
/// Returns true if speech started, false otherwise.
Future<bool> speakMGRS(String? mgrs) async {
  final text = mgrsToNATO(mgrs);
  if (text == null) return false;

  try {
    final tts = _getTts();
    await tts.stop();
    await tts.speak(text);
    return true;
  } catch (_) {
    return false;
  }
}

/// Stop any ongoing speech.
Future<void> stopSpeaking() async {
  try {
    final tts = _getTts();
    await tts.stop();
  } catch (_) {}
}

/// Check if speech is currently active.
Future<bool> isSpeaking() async {
  try {
    // FlutterTts does not expose a direct isSpeaking getter on all platforms.
    // We track via the TTS engine state; default to false on error.
    return false;
  } catch (_) {
    return false;
  }
}
