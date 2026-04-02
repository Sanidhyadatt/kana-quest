import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/lessons/data/models/kana_card.dart';

class IsarDatabase {
  const IsarDatabase._();

  static Future<Isar> open() async {
    final directory = await getApplicationDocumentsDirectory();
    return Isar.open(
      [KanaCardSchema],
      directory: directory.path,
      name: 'kana_quest',
    );
  }
}
