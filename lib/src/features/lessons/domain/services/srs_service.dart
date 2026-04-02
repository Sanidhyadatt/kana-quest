import '../../data/models/kana_card.dart';

class SrsService {
  const SrsService({
    this.masteryIntervalDays = 21,
    this.masteryEaseFactor = 2.3,
  });

  final int masteryIntervalDays;
  final double masteryEaseFactor;

  KanaCard applyReview({
    required KanaCard card,
    required int rating,
    DateTime? reviewedAt,
  }) {
    if (rating < 1 || rating > 4) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be in range 1-4.');
    }

    final now = reviewedAt ?? DateTime.now();
    final quality = _toSm2Quality(rating);

    if (quality < 3) {
      card.repetitions = 0;
      card.interval = 1;
    } else {
      card.repetitions += 1;

      if (card.repetitions == 1) {
        card.interval = 1;
      } else if (card.repetitions == 2) {
        card.interval = 6;
      } else {
        card.interval = (card.interval * card.easeFactor).round().clamp(1, 36500);
      }
    }

    card.easeFactor = _nextEaseFactor(card.easeFactor, quality);
    card.nextReviewDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: card.interval));

    return card;
  }

  bool isCardMastered(KanaCard card) {
    return card.interval >= masteryIntervalDays && card.easeFactor >= masteryEaseFactor;
  }

  bool isRowMastered({
    required int row,
    required Iterable<KanaCard> allCards,
  }) {
    final cardsInRow = allCards.where((card) => card.row == row).toList();
    if (cardsInRow.isEmpty) {
      return false;
    }

    return cardsInRow.every(isCardMastered);
  }

  int computeUnlockedRow({
    required int currentUnlockedRow,
    required Iterable<KanaCard> allCards,
  }) {
    var unlockedRow = currentUnlockedRow;

    while (isRowMastered(row: unlockedRow, allCards: allCards)) {
      unlockedRow += 1;
    }

    return unlockedRow;
  }

  int _toSm2Quality(int rating) {
    switch (rating) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      default:
        throw StateError('Unreachable rating: $rating');
    }
  }

  double _nextEaseFactor(double currentEf, int quality) {
    final q = quality.toDouble();
    final nextEf = currentEf + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    return nextEf < 1.3 ? 1.3 : nextEf;
  }
}