import 'package:isar/isar.dart';

import '../models/kana_card.dart';
import 'kana_seed_data.dart';

class KanaSeedService {
  const KanaSeedService._();

  static Future<void> ensureSeeded(Isar isar) async {
    final existingCards = await isar.kanaCards.where().findAll();

    final allSeeds = [
      ...seedKanaCards,
      ...seedKatakanaCards,
      ...seedKanjiCards,
    ];

    final existingKeys = existingCards.map((c) => '${c.character}|${c.script}').toSet();
    final toInsert = <KanaCard>[];

    for (final seed in allSeeds) {
      final key = '${seed.character}|${seed.script}';
      if (!existingKeys.contains(key)) {
        final card = KanaCard()
          ..character = seed.character
          ..script = seed.script
          ..romaji = seed.romaji
          ..mnemonic = seed.mnemonic
          ..row = seed.row
          ..relatedWords = seed.relatedWords
          ..easeFactor = 2.5
          ..interval = 0
          ..repetitions = 0
          ..nextReviewDate = DateTime.fromMillisecondsSinceEpoch(0);
        
        toInsert.add(card);
      }
    }

    if (toInsert.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.kanaCards.putAll(toInsert);
      });
    }
  }
}
