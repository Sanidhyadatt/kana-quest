import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/hiragana_row.dart';

class HiraganaRowsRepository {
  const HiraganaRowsRepository();

  Future<List<HiraganaRow>> loadRows() async {
    final rawJson = await rootBundle.loadString('assets/hiragana_rows.json');
    final decoded = jsonDecode(rawJson) as List<dynamic>;

    final rows =
        decoded
            .map((entry) => HiraganaRow.fromJson(entry as Map<String, dynamic>))
            .toList()
          ..sort((left, right) => left.row.compareTo(right.row));

    return rows;
  }
}
