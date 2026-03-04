import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/extensions/string_ext.dart';

void main() {
  // -----------------------------------------------------------------------
  // truncate
  // -----------------------------------------------------------------------
  group('truncate', () {
    test('short string unchanged when within limit', () {
      expect('hello'.truncate(10), equals('hello'));
    });

    test('exact length string unchanged', () {
      expect('hello'.truncate(5), equals('hello'));
    });

    test('long string truncated with ellipsis', () {
      expect('hello world'.truncate(8), equals('hello...'));
    });

    test('maxLength of 3 returns first 3 characters (no room for ellipsis)', () {
      expect('hello world'.truncate(3), equals('hel'));
    });

    test('maxLength of 2 returns first 2 characters', () {
      expect('hello world'.truncate(2), equals('he'));
    });

    test('maxLength of 1 returns first character', () {
      expect('hello world'.truncate(1), equals('h'));
    });

    test('maxLength of 4 truncates with ellipsis', () {
      expect('hello world'.truncate(4), equals('h...'));
    });

    test('empty string remains empty', () {
      expect(''.truncate(10), equals(''));
    });
  });

  // -----------------------------------------------------------------------
  // toTitleCase
  // -----------------------------------------------------------------------
  group('toTitleCase', () {
    test('hello world -> Hello World', () {
      expect('hello world'.toTitleCase(), equals('Hello World'));
    });

    test('already title case stays the same', () {
      expect('Hello World'.toTitleCase(), equals('Hello World'));
    });

    test('all uppercase becomes title case', () {
      expect('HELLO WORLD'.toTitleCase(), equals('Hello World'));
    });

    test('single word', () {
      expect('hello'.toTitleCase(), equals('Hello'));
    });

    test('empty string remains empty', () {
      expect(''.toTitleCase(), equals(''));
    });

    test('single character', () {
      expect('a'.toTitleCase(), equals('A'));
    });

    test('mixed case words', () {
      expect('hELLO wORLD'.toTitleCase(), equals('Hello World'));
    });
  });

  // -----------------------------------------------------------------------
  // isValidPin
  // -----------------------------------------------------------------------
  group('isValidPin', () {
    test('"1234" is valid', () {
      expect('1234'.isValidPin(), isTrue);
    });

    test('"0000" is valid', () {
      expect('0000'.isValidPin(), isTrue);
    });

    test('"9999" is valid', () {
      expect('9999'.isValidPin(), isTrue);
    });

    test('"123" is invalid (too short)', () {
      expect('123'.isValidPin(), isFalse);
    });

    test('"12345" is invalid (too long)', () {
      expect('12345'.isValidPin(), isFalse);
    });

    test('"abcd" is invalid (not digits)', () {
      expect('abcd'.isValidPin(), isFalse);
    });

    test('"12ab" is invalid (mixed)', () {
      expect('12ab'.isValidPin(), isFalse);
    });

    test('empty string is invalid', () {
      expect(''.isValidPin(), isFalse);
    });

    test('"1 34" is invalid (contains space)', () {
      expect('1 34'.isValidPin(), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // isValidMGRS
  // -----------------------------------------------------------------------
  group('isValidMGRS', () {
    test('"18SUJ2345678901" is valid (10-digit)', () {
      expect('18SUJ2345678901'.isValidMGRS(), isTrue);
    });

    test('"18SUJ23456789" is valid (8-digit)', () {
      expect('18SUJ23456789'.isValidMGRS(), isTrue);
    });

    test('"18SUJ234567" is valid (6-digit)', () {
      expect('18SUJ234567'.isValidMGRS(), isTrue);
    });

    test('"18SUJ2345" is valid (4-digit)', () {
      expect('18SUJ2345'.isValidMGRS(), isTrue);
    });

    test('"18SUJ23" is valid (2-digit)', () {
      expect('18SUJ23'.isValidMGRS(), isTrue);
    });

    test('single-digit zone "4QFJ12345678" is valid', () {
      expect('4QFJ12345678'.isValidMGRS(), isTrue);
    });

    test('with spaces is valid (spaces stripped)', () {
      expect('18S UJ 23456 78901'.isValidMGRS(), isTrue);
    });

    test('empty string is invalid', () {
      expect(''.isValidMGRS(), isFalse);
    });

    test('"INVALID" is invalid', () {
      expect('INVALID'.isValidMGRS(), isFalse);
    });

    test('odd digit count is invalid ("18SUJ12345")', () {
      // 5 digits (not 2,4,6,8,10) should fail
      expect('18SUJ12345'.isValidMGRS(), isFalse);
    });

    test('zone letter I is invalid', () {
      expect('18IUJ2345678901'.isValidMGRS(), isFalse);
    });

    test('zone letter O is invalid', () {
      expect('18OUJ2345678901'.isValidMGRS(), isFalse);
    });

    test('zone letter A is invalid (below C)', () {
      expect('18AUJ2345678901'.isValidMGRS(), isFalse);
    });

    test('case insensitive', () {
      expect('18suj2345678901'.isValidMGRS(), isTrue);
    });
  });
}
