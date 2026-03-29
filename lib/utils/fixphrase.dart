/// FixPhrase — Convert lat/lon to memorable 4-word phrases and back.
///
/// Based on the open-source FixPhrase algorithm (BSD-3-Clause, Netsyms Technologies).
/// ~11m accuracy with 4 words. Word order does not matter for decoding.
class FixPhrase {
  final List<String> _wordlist;
  final Map<String, int> _wordIndex;

  FixPhrase(List<String> wordlist)
      : _wordlist = wordlist,
        _wordIndex = {
          for (int i = 0; i < wordlist.length; i++) wordlist[i]: i,
        };

  /// Encode lat/lon to a 4-word hyphen-separated phrase.
  String encode(double lat, double lon) {
    if (lat < -90 || lat > 90) {
      throw ArgumentError('Latitude out of range: $lat');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError('Longitude out of range: $lon');
    }

    final latInt = (lat * 10000).round() + 900000;
    final lonInt = (lon * 10000).round() + 1800000;

    final latStr = latInt.toString().padLeft(7, '0');
    final lonStr = lonInt.toString().padLeft(7, '0');

    final g0 = int.parse(latStr.substring(0, 4));
    final g1 = int.parse(lonStr.substring(0, 4)) + 2000;
    final g2 = int.parse(latStr.substring(4, 6) + lonStr.substring(4, 5)) + 5610;
    final g3 = int.parse(latStr.substring(6, 7) + lonStr.substring(5, 7)) + 6610;

    return '${_wordlist[g0]}-${_wordlist[g1]}-${_wordlist[g2]}-${_wordlist[g3]}';
  }

  /// Decode a FixPhrase back to lat/lon.
  /// Words can be in any order (ranges are non-overlapping).
  /// Accepts hyphen or space separated.
  ({double lat, double lon, int wordsUsed}) decode(String phrase) {
    final words = phrase.toLowerCase().replaceAll('-', ' ').trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      throw ArgumentError('Need at least 2 words');
    }

    final indexes = [-1, -1, -1, -1];

    for (final word in words) {
      final idx = _wordIndex[word];
      if (idx == null) continue;

      if (idx >= 0 && idx < 2000) {
        indexes[0] = idx;
      } else if (idx >= 2000 && idx < 5610) {
        indexes[1] = idx - 2000;
      } else if (idx >= 5610 && idx < 6610) {
        indexes[2] = idx - 5610;
      } else if (idx >= 6610 && idx < 7610) {
        indexes[3] = idx - 6610;
      }
    }

    if (indexes[0] == -1 || indexes[1] == -1) {
      throw ArgumentError('Cannot determine location from supplied words');
    }

    // Count how many valid word groups were found (2, 3, or 4).
    int wordsUsed = 2;
    if (indexes[2] != -1) wordsUsed = 3;
    if (indexes[2] != -1 && indexes[3] != -1) wordsUsed = 4;

    double divby = 10.0;
    var latStr = indexes[0].toString().padLeft(4, '0');
    var lonStr = indexes[1].toString().padLeft(4, '0');

    String? latlon2dec;
    if (indexes[2] != -1) {
      divby = 100.0;
      latlon2dec = indexes[2].toString().padLeft(3, '0');
      latStr += latlon2dec.substring(0, 1);
      lonStr += latlon2dec.substring(2, 3);
    }

    if (indexes[2] != -1 && indexes[3] != -1) {
      divby = 10000.0;
      final latlon4dec = indexes[3].toString().padLeft(3, '0');
      latStr += latlon2dec!.substring(1, 2) + latlon4dec.substring(0, 1);
      lonStr += latlon4dec.substring(1, 3);
    }

    final latFinal = (((int.parse(latStr) / divby) - 90.0) * 10000).round() / 10000;
    final lonFinal = (((int.parse(lonStr) / divby) - 180.0) * 10000).round() / 10000;

    return (lat: latFinal, lon: lonFinal, wordsUsed: wordsUsed);
  }

  /// Format lat/lon as a FixPhrase, returning 'ERROR' on failure.
  String format(double lat, double lon) {
    try {
      return encode(lat, lon);
    } catch (_) {
      return 'ERROR';
    }
  }
}
