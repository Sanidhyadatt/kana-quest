import '../../lessons/data/models/kana_card.dart';
import 'hiragana_row.dart';

class RankProgress {
  const RankProgress({
    required this.label,
    required this.currentXp,
    required this.currentThreshold,
    required this.nextThreshold,
  });

  final String label;
  final int currentXp;
  final int currentThreshold;
  final int nextThreshold;

  double get fraction {
    if (nextThreshold <= currentThreshold) {
      return 1;
    }

    final rawProgress =
        (currentXp - currentThreshold) / (nextThreshold - currentThreshold);
    return rawProgress.clamp(0.0, 1.0);
  }

  int get remainingXp {
    final remaining = nextThreshold - currentXp;
    return remaining < 0 ? 0 : remaining;
  }
}

class ShrineProgress {
  const ShrineProgress({
    required this.row,
    required this.masteredCount,
    required this.dueCount,
    required this.totalCount,
    required this.isLocked,
    required this.isMastered,
  });

  final HiraganaRow row;
  final int masteredCount;
  final int dueCount;
  final int totalCount;
  final bool isLocked;
  final bool isMastered;

  double get masteryFraction {
    if (totalCount == 0) {
      return 0;
    }

    return masteredCount / totalCount;
  }
}

class WorldMapProgress {
  const WorldMapProgress({
    required this.dueCount,
    required this.masteredCount,
    required this.totalCards,
    required this.streakDays,
    required this.rank,
    required this.shrines,
  });

  final int dueCount;
  final int masteredCount;
  final int totalCards;
  final int streakDays;
  final RankProgress rank;
  final List<ShrineProgress> shrines;
}

RankProgress rankFromXp(int xp) {
  const ranks = <({int threshold, String label})>[
    (threshold: 0, label: 'White Belt'),
    (threshold: 250, label: 'Yellow Belt'),
    (threshold: 600, label: 'Orange Belt'),
    (threshold: 1000, label: 'Green Belt'),
    (threshold: 1500, label: 'Blue Belt'),
    (threshold: 2200, label: 'Brown Belt'),
    (threshold: 3000, label: 'Black Belt'),
  ];

  var currentIndex = 0;
  for (var index = 0; index < ranks.length; index += 1) {
    if (xp >= ranks[index].threshold) {
      currentIndex = index;
    }
  }

  final currentRank = ranks[currentIndex];
  final nextRank = currentIndex == ranks.length - 1
      ? currentRank
      : ranks[currentIndex + 1];

  return RankProgress(
    label: currentRank.label,
    currentXp: xp,
    currentThreshold: currentRank.threshold,
    nextThreshold: nextRank.threshold,
  );
}

WorldMapProgress buildWorldMapProgress({
  required List<HiraganaRow> rows,
  required List<KanaCard> cards,
  required DateTime now,
  required bool Function(KanaCard card) isCardMastered,
  required bool Function(KanaCard card) isCardCompleted,
  required int Function({
    required int currentUnlockedRow,
    required Iterable<KanaCard> allCards,
  })
  computeUnlockedRow,
}) {
  final cardsByRow = <int, List<KanaCard>>{};
  for (final card in cards) {
    cardsByRow.putIfAbsent(card.row, () => <KanaCard>[]).add(card);
  }

  final dueCards = cards
      .where((card) => !card.nextReviewDate.isAfter(now))
      .toList();
  final completedCards = cards.where(isCardCompleted).toList();
  final unlockedRow = computeUnlockedRow(
    currentUnlockedRow: 0,
    allCards: cards,
  );

  final shrineProgress = rows.map((row) {
    final rowCards = cardsByRow[row.row] ?? const <KanaCard>[];
    final masteredCount = rowCards.where(isCardCompleted).length;
    final dueCount = rowCards
        .where((card) => !card.nextReviewDate.isAfter(now))
        .length;
    final totalCount = rowCards.length;

    return ShrineProgress(
      row: row,
      masteredCount: masteredCount,
      dueCount: dueCount,
      totalCount: totalCount,
      isLocked: row.row > unlockedRow,
      isMastered: totalCount > 0 && rowCards.every(isCardCompleted),
    );
  }).toList();

  final xp = completedCards.length * 20 + dueCards.length * 2;

  return WorldMapProgress(
    dueCount: dueCards.length,
    masteredCount: completedCards.length,
    totalCards: cards.length,
    streakDays: 5,
    rank: rankFromXp(xp),
    shrines: shrineProgress,
  );
}
