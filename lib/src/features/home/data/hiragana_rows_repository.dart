import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/hiragana_row.dart';

class KanaRowsRepository {
  const KanaRowsRepository();

  Future<List<HiraganaRow>> loadRows(int scriptType) async {
    final filename = scriptType == 0
        ? 'assets/hiragana_rows.json'
        : scriptType == 1
            ? 'assets/katakana_rows.json'
            : 'assets/kanji_rows.json';
    
    final rawJson = await rootBundle.loadString(filename);
    final decoded = jsonDecode(rawJson) as List<dynamic>;

    final rows =
        decoded
            .map((entry) => HiraganaRow.fromJson(entry as Map<String, dynamic>))
            .toList()
          ..sort((left, right) => left.row.compareTo(right.row));

    return rows;
  }
}
