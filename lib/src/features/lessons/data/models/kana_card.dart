import 'package:isar/isar.dart';

part 'kana_card.g.dart';


@collection
class KanaCard {
  Id id = Isar.autoIncrement;

  late String character;

  late int script;

  late String romaji;
  late String mnemonic;

  // Feature progression bucket (for example: row 0 = vowels, row 1 = K-row).
  late int row;

  // SM-2 metadata.
  double easeFactor = 2.5;
  int interval = 0;
  int repetitions = 0;
  late DateTime nextReviewDate;
}