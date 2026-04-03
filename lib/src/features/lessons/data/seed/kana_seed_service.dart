import 'package:isar/isar.dart';

import '../models/kana_card.dart';
import '../repositories/stroke_path_repository.dart';
import 'stroke_order_data.dart';
import 'kana_seed_data.dart';

class KanaSeedService {
  const KanaSeedService._();

  static Future<void> ensureSeeded(Isar isar) async {
    final existingCards = await isar.kanaCards.where().findAll();
    final existingByKey = {
      for (final card in existingCards)
        '${card.character}|${card.script}': card,
    };
    final strokeRepository = StrokePathRepository();

    final allSeeds = [
      ...seedKanaCards,
      ...seedKatakanaCards,
      ...seedKanjiCards,
    ];

    final toUpsert = <KanaCard>[];

    for (final seed in allSeeds) {
      final key = '${seed.character}|${seed.script}';
      final strokeData = strokeRepository.getStrokeData(seed.character);
      final strokePaths = strokeData?.paths ?? const <String>[];
      final strokeCount = strokePaths.isNotEmpty
          ? strokePaths.length
          : (kanaCharacterInfo[seed.character]?.strokeCount ?? 0);

      final card =
          existingByKey[key] ??
          (KanaCard()
            ..easeFactor = 2.5
            ..interval = 0
            ..repetitions = 0
            ..nextReviewDate = DateTime.fromMillisecondsSinceEpoch(0));

      card
        ..character = seed.character
        ..script = seed.script
        ..romaji = seed.romaji
        ..mnemonic = seed.mnemonic
        ..row = seed.row
        ..relatedWords = seed.relatedWords
        ..strokeCount = strokeCount
        ..strokePaths = List<String>.from(strokePaths);

      toUpsert.add(card);
    }

    if (toUpsert.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.kanaCards.putAll(toUpsert);
      });
    }
  }
}
