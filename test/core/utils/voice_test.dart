import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/utils/voice.dart';

void main() {
  // -----------------------------------------------------------------------
  // mgrsToNATO — basic conversions
  // -----------------------------------------------------------------------
  group('mgrsToNATO', () {
    test('converts "18S UJ 23456 78901" correctly', () {
      final result = mgrsToNATO('18S UJ 23456 78901');
      expect(result, isNotNull);
      // GZD "18S" should produce: one, eight, Sierra
      expect(result!, contains('one'));
      expect(result, contains('eight'));
      expect(result, contains('Sierra'));
      // Grid square "UJ" should produce: Uniform, Juliet
      expect(result, contains('Uniform'));
      expect(result, contains('Juliet'));
    });

    test('segments are separated by periods', () {
      final result = mgrsToNATO('18S UJ 23456 78901');
      expect(result, isNotNull);
      // Should have 4 segments: GZD, grid square, easting, northing
      final segments = result!.split('. ');
      expect(segments.length, equals(4));
    });

    test('digits within segments are separated by commas', () {
      final result = mgrsToNATO('18S UJ 23456 78901');
      expect(result, isNotNull);
      // First segment is GZD: "one, eight, Sierra"
      final segments = result!.split('. ');
      expect(segments[0], contains(', '));
    });
  });

  // -----------------------------------------------------------------------
  // mgrsToNATO — all NATO letters
  // -----------------------------------------------------------------------
  group('mgrsToNATO NATO alphabet coverage', () {
    test('A = Alpha', () {
      expect(natoAlpha['A'], equals('Alpha'));
    });

    test('B = Bravo', () {
      expect(natoAlpha['B'], equals('Bravo'));
    });

    test('C = Charlie', () {
      expect(natoAlpha['C'], equals('Charlie'));
    });

    test('D = Delta', () {
      expect(natoAlpha['D'], equals('Delta'));
    });

    test('E = Echo', () {
      expect(natoAlpha['E'], equals('Echo'));
    });

    test('F = Foxtrot', () {
      expect(natoAlpha['F'], equals('Foxtrot'));
    });

    test('G = Golf', () {
      expect(natoAlpha['G'], equals('Golf'));
    });

    test('H = Hotel', () {
      expect(natoAlpha['H'], equals('Hotel'));
    });

    test('I = India', () {
      expect(natoAlpha['I'], equals('India'));
    });

    test('J = Juliet', () {
      expect(natoAlpha['J'], equals('Juliet'));
    });

    test('K = Kilo', () {
      expect(natoAlpha['K'], equals('Kilo'));
    });

    test('L = Lima', () {
      expect(natoAlpha['L'], equals('Lima'));
    });

    test('M = Mike', () {
      expect(natoAlpha['M'], equals('Mike'));
    });

    test('N = November', () {
      expect(natoAlpha['N'], equals('November'));
    });

    test('O = Oscar', () {
      expect(natoAlpha['O'], equals('Oscar'));
    });

    test('P = Papa', () {
      expect(natoAlpha['P'], equals('Papa'));
    });

    test('Q = Quebec', () {
      expect(natoAlpha['Q'], equals('Quebec'));
    });

    test('R = Romeo', () {
      expect(natoAlpha['R'], equals('Romeo'));
    });

    test('S = Sierra', () {
      expect(natoAlpha['S'], equals('Sierra'));
    });

    test('T = Tango', () {
      expect(natoAlpha['T'], equals('Tango'));
    });

    test('U = Uniform', () {
      expect(natoAlpha['U'], equals('Uniform'));
    });

    test('V = Victor', () {
      expect(natoAlpha['V'], equals('Victor'));
    });

    test('W = Whiskey', () {
      expect(natoAlpha['W'], equals('Whiskey'));
    });

    test('X = X-ray', () {
      expect(natoAlpha['X'], equals('X-ray'));
    });

    test('Y = Yankee', () {
      expect(natoAlpha['Y'], equals('Yankee'));
    });

    test('Z = Zulu', () {
      expect(natoAlpha['Z'], equals('Zulu'));
    });

    test('natoAlpha contains all 26 letters', () {
      expect(natoAlpha.length, equals(26));
    });
  });

  // -----------------------------------------------------------------------
  // mgrsToNATO — all NATO digits
  // -----------------------------------------------------------------------
  group('mgrsToNATO NATO digit coverage', () {
    test('0 = zero', () {
      expect(natoDigit['0'], equals('zero'));
    });

    test('1 = one', () {
      expect(natoDigit['1'], equals('one'));
    });

    test('2 = two', () {
      expect(natoDigit['2'], equals('two'));
    });

    test('3 = three', () {
      expect(natoDigit['3'], equals('three'));
    });

    test('4 = four', () {
      expect(natoDigit['4'], equals('four'));
    });

    test('5 = five', () {
      expect(natoDigit['5'], equals('five'));
    });

    test('6 = six', () {
      expect(natoDigit['6'], equals('six'));
    });

    test('7 = seven', () {
      expect(natoDigit['7'], equals('seven'));
    });

    test('8 = eight', () {
      expect(natoDigit['8'], equals('eight'));
    });

    test('9 = niner', () {
      expect(natoDigit['9'], equals('niner'));
    });

    test('natoDigit contains all 10 digits', () {
      expect(natoDigit.length, equals(10));
    });
  });

  // -----------------------------------------------------------------------
  // mgrsToNATO — null / empty / invalid input
  // -----------------------------------------------------------------------
  group('mgrsToNATO edge cases', () {
    test('null input returns null', () {
      expect(mgrsToNATO(null), isNull);
    });

    test('empty string returns null', () {
      expect(mgrsToNATO(''), isNull);
    });

    test('input with fewer than 3 parts returns null', () {
      expect(mgrsToNATO('18S'), isNull);
      expect(mgrsToNATO('18S UJ'), isNull);
    });

    test('input with exactly 3 parts is valid', () {
      final result = mgrsToNATO('18S UJ 23456');
      expect(result, isNotNull);
    });

    test('input with 4 parts is valid', () {
      final result = mgrsToNATO('18S UJ 23456 78901');
      expect(result, isNotNull);
    });
  });

  // -----------------------------------------------------------------------
  // mgrsToNATO — digit rendering in context
  // -----------------------------------------------------------------------
  group('mgrsToNATO digit rendering', () {
    test('easting "09876" produces zero, niner, eight, seven, six', () {
      final result = mgrsToNATO('18S UJ 09876 12345');
      expect(result, isNotNull);
      // The third segment (easting) should contain these
      final segments = result!.split('. ');
      final eastingSegment = segments[2];
      expect(eastingSegment, contains('zero'));
      expect(eastingSegment, contains('niner'));
      expect(eastingSegment, contains('eight'));
      expect(eastingSegment, contains('seven'));
      expect(eastingSegment, contains('six'));
    });
  });
}
