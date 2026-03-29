import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/utils/fixphrase.dart';

void main() {
  late FixPhrase fixPhrase;

  setUpAll(() {
    final json = File('assets/fixphrase_wordlist.json').readAsStringSync();
    final words = List<String>.from(jsonDecode(json) as List);
    fixPhrase = FixPhrase(words);
  });

  group('encode/decode round-trips', () {
    final testCases = <String, List<double>>{
      'Washington Monument': [38.8895, -77.0353],
      'Eiffel Tower': [48.8584, 2.2945],
      'Sydney Opera House': [-33.8568, 151.2153],
      'North Pole area': [89.9999, 0.0001],
      'South Pole area': [-89.9999, -179.9999],
      'Origin': [0.0, 0.0],
      'Tokyo Tower': [35.6586, 139.7454],
    };

    for (final entry in testCases.entries) {
      test('${entry.key} round-trips within 0.0001 deg', () {
        final lat = entry.value[0];
        final lon = entry.value[1];
        final phrase = fixPhrase.encode(lat, lon);

        expect(phrase, isNotNull);
        expect(phrase.split('-').length, 4);

        final result = fixPhrase.decode(phrase);
        expect((result.lat - lat).abs(), lessThanOrEqualTo(0.0001));
        expect((result.lon - lon).abs(), lessThanOrEqualTo(0.0001));
        expect(result.wordsUsed, 4);
      });
    }
  });

  group('word order independence', () {
    test('reversed words decode to same location', () {
      final phrase = fixPhrase.encode(40.7128, -74.0060);
      final reversed = phrase.split('-').reversed.join('-');

      final original = fixPhrase.decode(phrase);
      final fromReversed = fixPhrase.decode(reversed);

      expect(fromReversed.lat, original.lat);
      expect(fromReversed.lon, original.lon);
      expect(fromReversed.wordsUsed, 4);
    });

    test('space-separated words work', () {
      final phrase = fixPhrase.encode(51.5074, -0.1278);
      final spaced = phrase.replaceAll('-', ' ');
      final result = fixPhrase.decode(spaced);
      expect((result.lat - 51.5074).abs(), lessThanOrEqualTo(0.0001));
      expect((result.lon - (-0.1278)).abs(), lessThanOrEqualTo(0.0001));
      expect(result.wordsUsed, 4);
    });
  });

  group('validation', () {
    test('throws on latitude > 90', () {
      expect(() => fixPhrase.encode(91, 0), throwsArgumentError);
    });

    test('throws on longitude < -180', () {
      expect(() => fixPhrase.encode(0, -181), throwsArgumentError);
    });

    test('throws on insufficient words', () {
      expect(() => fixPhrase.decode('hello'), throwsArgumentError);
    });
  });

  group('formatFixPhrase', () {
    test('returns a hyphen-separated string', () {
      final result = fixPhrase.format(34.0522, -118.2437);
      expect(result, matches(RegExp(r'^[a-z]+-[a-z]+-[a-z]+-[a-z]+$')));
    });

    test('returns ERROR for invalid input', () {
      expect(fixPhrase.format(999, 999), 'ERROR');
    });
  });
}
