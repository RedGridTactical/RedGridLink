/// NATO Phonetic Alphabet converter for radio-clear voice callouts.
///
/// Converts alphanumeric strings (such as MGRS grid references) into
/// their NATO phonetic equivalents for text-to-speech readability.
class NatoPhonetic {
  /// Standard NATO phonetic alphabet for letters.
  static const _letters = {
    'A': 'ALFA',
    'B': 'BRAVO',
    'C': 'CHARLIE',
    'D': 'DELTA',
    'E': 'ECHO',
    'F': 'FOXTROT',
    'G': 'GOLF',
    'H': 'HOTEL',
    'I': 'INDIA',
    'J': 'JULIET',
    'K': 'KILO',
    'L': 'LIMA',
    'M': 'MIKE',
    'N': 'NOVEMBER',
    'O': 'OSCAR',
    'P': 'PAPA',
    'Q': 'QUEBEC',
    'R': 'ROMEO',
    'S': 'SIERRA',
    'T': 'TANGO',
    'U': 'UNIFORM',
    'V': 'VICTOR',
    'W': 'WHISKEY',
    'X': 'X-RAY',
    'Y': 'YANKEE',
    'Z': 'ZULU',
  };

  /// NATO digit pronunciations for radio clarity.
  static const _digits = {
    '0': 'ZE-RO',
    '1': 'WUN',
    '2': 'TOO',
    '3': 'TREE',
    '4': 'FOW-ER',
    '5': 'FIFE',
    '6': 'SIX',
    '7': 'SEV-EN',
    '8': 'AIT',
    '9': 'NIN-ER',
  };

  /// Convert an alphanumeric string to NATO phonetic pronunciation.
  ///
  /// Each character is converted to its NATO equivalent, separated by spaces.
  /// Unknown characters (punctuation, symbols) pass through unchanged.
  ///
  /// Example: `convert('18SUC')` returns
  /// `'WUN AIT SIERRA UNIFORM CHARLIE'`.
  static String convert(String input) {
    return input.toUpperCase().split('').map((char) {
      return _letters[char] ?? _digits[char] ?? char;
    }).join(' ');
  }

  /// Convert an MGRS grid string to a spoken callout.
  ///
  /// Strips spaces before conversion so that formatted MGRS strings
  /// (e.g., `'18S UC 12345 67890'`) are handled correctly.
  static String convertMgrs(String mgrs) {
    return convert(mgrs.replaceAll(' ', ''));
  }

  /// Build a full callout string: "callsign, grid mgrs".
  ///
  /// Example: `buildCallout('ALPHA-1', '18SUC1234567890')` returns
  /// `'ALPHA-1, grid WUN AIT SIERRA UNIFORM CHARLIE ...'`.
  static String buildCallout(String callsign, String mgrs) {
    return '$callsign, grid ${convertMgrs(mgrs)}';
  }
}
