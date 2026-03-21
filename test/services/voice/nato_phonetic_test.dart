import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/voice/nato_phonetic.dart';

void main() {
  group('NatoPhonetic', () {
    group('convert', () {
      test('converts single letter to NATO phonetic', () {
        expect(NatoPhonetic.convert('A'), 'ALFA');
        expect(NatoPhonetic.convert('B'), 'BRAVO');
        expect(NatoPhonetic.convert('Z'), 'ZULU');
      });

      test('converts lowercase to NATO phonetic', () {
        expect(NatoPhonetic.convert('a'), 'ALFA');
        expect(NatoPhonetic.convert('z'), 'ZULU');
      });

      test('converts digits to NATO pronunciation', () {
        expect(NatoPhonetic.convert('0'), 'ZE-RO');
        expect(NatoPhonetic.convert('1'), 'WUN');
        expect(NatoPhonetic.convert('2'), 'TOO');
        expect(NatoPhonetic.convert('3'), 'TREE');
        expect(NatoPhonetic.convert('4'), 'FOW-ER');
        expect(NatoPhonetic.convert('5'), 'FIFE');
        expect(NatoPhonetic.convert('6'), 'SIX');
        expect(NatoPhonetic.convert('7'), 'SEV-EN');
        expect(NatoPhonetic.convert('8'), 'AIT');
        expect(NatoPhonetic.convert('9'), 'NIN-ER');
      });

      test('converts mixed alphanumeric string', () {
        expect(
          NatoPhonetic.convert('18SUC'),
          'WUN AIT SIERRA UNIFORM CHARLIE',
        );
      });

      test('converts all letters correctly', () {
        expect(NatoPhonetic.convert('X'), 'X-RAY');
        expect(NatoPhonetic.convert('Q'), 'QUEBEC');
        expect(NatoPhonetic.convert('W'), 'WHISKEY');
      });

      test('unknown characters pass through unchanged', () {
        expect(NatoPhonetic.convert('-'), '-');
        expect(NatoPhonetic.convert('.'), '.');
        expect(NatoPhonetic.convert('A-1'), 'ALFA - WUN');
      });

      test('empty string returns empty string', () {
        expect(NatoPhonetic.convert(''), '');
      });

      test('full MGRS grid converts correctly', () {
        final result = NatoPhonetic.convert('18SUC1234567890');
        expect(
          result,
          'WUN AIT SIERRA UNIFORM CHARLIE '
          'WUN TOO TREE FOW-ER FIFE '
          'SIX SEV-EN AIT NIN-ER ZE-RO',
        );
      });
    });

    group('convertMgrs', () {
      test('strips spaces before converting', () {
        final withSpaces = NatoPhonetic.convertMgrs('18S UC 12345 67890');
        final withoutSpaces = NatoPhonetic.convertMgrs('18SUC1234567890');
        expect(withSpaces, withoutSpaces);
      });

      test('handles already clean MGRS', () {
        expect(
          NatoPhonetic.convertMgrs('18SUC'),
          'WUN AIT SIERRA UNIFORM CHARLIE',
        );
      });
    });

    group('buildCallout', () {
      test('formats callsign and grid correctly', () {
        final result = NatoPhonetic.buildCallout('ALPHA-1', '18SUC');
        expect(result, 'ALPHA-1, grid WUN AIT SIERRA UNIFORM CHARLIE');
      });

      test('uses callsign as-is without conversion', () {
        final result = NatoPhonetic.buildCallout('Bravo', '1A');
        expect(result, 'Bravo, grid WUN ALFA');
      });
    });
  });
}
