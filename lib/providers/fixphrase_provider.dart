import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/fixphrase.dart';

/// Provides a loaded [FixPhrase] instance with the bundled wordlist.
final fixPhraseProvider = FutureProvider<FixPhrase>((ref) async {
  final json = await rootBundle.loadString('assets/fixphrase_wordlist.json');
  final words = List<String>.from(jsonDecode(json) as List);
  return FixPhrase(words);
});
