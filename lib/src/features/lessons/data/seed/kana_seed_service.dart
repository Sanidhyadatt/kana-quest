import 'package:isar/isar.dart';

import '../models/kana_card.dart';
import 'kana_seed_data.dart';

class KanaSeedService {
  const KanaSeedService._();

  static Future<void> ensureSeeded(Isar isar) async {
    final existingCards = await isar.kanaCards.where().findAll();

    final expectedRowZeroCards =
        seedKanaCards.where((seed) => seed.row == 0).length;
    final existingRowZeroCards = existingCards
        .where((card) => card.row == 0 && card.character.trim().runes.length == 1)
        .length;

    if (existingCards.isNotEmpty && existingRowZeroCards < expectedRowZeroCards) {
      await isar.writeTxn(() async {
        await isar.kanaCards.clear();
      });

      existingCards.clear();
    }

    final idsToDelete = <Id>[];
    final canonicalExistingKeys = <String>{};

    for (final card in existingCards) {
      final normalizedCharacter = card.character.trim();
      final hasSingleKana = normalizedCharacter.runes.length == 1;

      // Remove malformed cards that break front-face rendering/session logic.
      if (!hasSingleKana) {
        idsToDelete.add(card.id);
        continue;
      }

      final key = '$normalizedCharacter|${card.script}';
      if (canonicalExistingKeys.contains(key)) {
        // Keep first canonical row and remove duplicates.
        idsToDelete.add(card.id);
        continue;
      }

      canonicalExistingKeys.add(key);
    }

    final existingKeys = canonicalExistingKeys;

    final toInsert = <KanaCard>[];
    for (final seed in seedKanaCards) {
      final key = '${seed.character}|0';
      if (existingKeys.contains(key)) {
        continue;
      }

      final card = KanaCard()
        ..character = seed.character
        ..script = 0
        ..romaji = seed.romaji
        ..mnemonic = seed.mnemonic
        ..row = seed.row
        ..easeFactor = 2.5
        ..interval = 0
        ..repetitions = 0
        ..nextReviewDate = DateTime.fromMillisecondsSinceEpoch(0);

      toInsert.add(card);
    }

    if (toInsert.isEmpty && idsToDelete.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      if (idsToDelete.isNotEmpty) {
        await isar.kanaCards.deleteAll(idsToDelete);
      }
      await isar.kanaCards.putAll(toInsert);
    });
  }
}
