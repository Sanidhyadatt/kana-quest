import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/storage/isar_database.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/domain/services/srs_service.dart';
import '../data/hiragana_rows_repository.dart';
import '../domain/hiragana_row.dart';
import '../domain/world_map_progress.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  return IsarDatabase.getInstance();
});

final hiraganaRowsProvider = FutureProvider<List<HiraganaRow>>((ref) async {
  return const HiraganaRowsRepository().loadRows();
});

final worldMapProgressProvider = FutureProvider<WorldMapProgress>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final rows = await ref.watch(hiraganaRowsProvider.future);
  final cards = await isar.kanaCards.where().findAll();
  final srsService = SrsService();

  return buildWorldMapProgress(
    rows: rows,
    cards: cards,
    now: DateTime.now(),
    isCardMastered: srsService.isCardMastered,
    isCardCompleted: srsService.isCardCompleted,
    computeUnlockedRow: srsService.computeUnlockedRow,
  );
});
