/// Represents a single achievement badge in The Dojo.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.flavor,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String flavor;
  final bool isUnlocked;

  /// Computes the full list of achievements from current stats.
  static List<Achievement> compute({
    required int streak,
    required int xp,
    required int kanaMastered,
    required int totalCardsReviewed,
    required int totalKana,
  }) {
    Achievement make({
      required String id,
      required String title,
      required String emoji,
      required String flavor,
      required bool unlocked,
      String? unlockedSubtitle,
      String? lockedSubtitle,
    }) {
      return Achievement(
        id: id,
        title: title,
        subtitle: unlocked ? (unlockedSubtitle ?? 'UNLOCKED') : (lockedSubtitle ?? 'LOCKED'),
        emoji: emoji,
        flavor: flavor,
        isUnlocked: unlocked,
      );
    }

    return [
      make(
        id: 'seven_day_warrior',
        title: '7 Day Warrior',
        emoji: '🔥',
        flavor: 'Maintained a 7-day study streak',
        unlocked: streak >= 7,
        unlockedSubtitle: 'STREAK MASTER',
        lockedSubtitle: 'STREAK MASTER',
      ),
      make(
        id: 'first_100_xp',
        title: 'First 100 XP',
        emoji: '⚡',
        flavor: 'Earned your first 100 XP',
        unlocked: xp >= 100,
        unlockedSubtitle: 'BORN TO LEARN',
        lockedSubtitle: 'BORN TO LEARN',
      ),
      make(
        id: 'kanji_master',
        title: 'Kanji Master',
        emoji: '🗝️',
        flavor: 'Master all N5 Kanji (coming soon)',
        unlocked: false,
      ),
      make(
        id: 'speed_learner',
        title: 'Speed Learner',
        emoji: '⏱️',
        flavor: 'Review 50 cards in total',
        unlocked: totalCardsReviewed >= 50,
      ),
      make(
        id: 'jlpt_n5_ready',
        title: 'JLPT N5 Ready',
        emoji: '⭐',
        flavor: 'Master all Hiragana',
        unlocked: totalKana > 0 && kanaMastered >= totalKana,
      ),
      make(
        id: 'calligrapher',
        title: 'Calligrapher',
        emoji: '🖌️',
        flavor: 'Complete stroke order for all characters',
        unlocked: false,
      ),
    ];
  }
}