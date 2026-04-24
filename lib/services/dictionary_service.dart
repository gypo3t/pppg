import 'dart:convert';
import 'package:flutter/services.dart';

class DictionaryService {
  DictionaryService._();

  static String _raw = '';
  static bool loaded = false;
  static int wordCount = 0;

  static Future<void> load() async {
    if (loaded) return;
    final data = await rootBundle.load('assets/words/ods7/ods7.dic');
    _raw = latin1.decode(data.buffer.asUint8List());
    wordCount = _raw.split(RegExp(r'[\r\n]+')).where((w) {
      final t = w.trim();
      return t.length >= 3 && t.length <= 15;
    }).length;
    loaded = true;
  }

  static String get raw => _raw;
}
