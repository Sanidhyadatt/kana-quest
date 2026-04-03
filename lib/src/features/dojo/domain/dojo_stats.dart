import 'achievement.dart';

/// Aggregated statistics for The Dojo progress screen.
class DojoStats {
  const DojoStats({
    required this.userName,
    required this.rank,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.currentStreak,
    required this.weeklyReviewDays,
    required this.weeklyGoalDays,
    required this.hiraganaMastered,
    required this.hiraganaLearning,
    required this.katakanaMastered,
    required this.katakanaLearning,
    required this.kanjiMastered,
    required this.kanjiLearning,
    required this.reviewDates,
    required this.achievements,
    required this.totalCardsReviewed,
    required this.quizAttempts,
    required this.quizCorrectAnswers,
    required this.quizQuestionsAnswered,
  });

  final String userName;
  final String rank;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int currentStreak;
  final int weeklyReviewDays;
  final int weeklyGoalDays;
  
  final int hiraganaMastered;
  final int hiraganaLearning;
  final int katakanaMastered;
  final int katakanaLearning;
  final int kanjiMastered;
  final int kanjiLearning;

  final Set<String> reviewDates;
  final List<Achievement> achievements;
  final int totalCardsReviewed;
  final int quizAttempts;
  final int quizCorrectAnswers;
  final int quizQuestionsAnswered;

  double get weeklyGoalProgress {
    if (weeklyGoalDays <= 0) return 0;
    return (weeklyReviewDays / weeklyGoalDays).clamp(0.0, 1.0);
  }

  // Backwards compatibility for now or deprecated
  int get kanaMastered => hiraganaMastered;
  int get kanaLearning => hiraganaLearning;

  int get totalMastered =>
      hiraganaMastered + katakanaMastered + kanjiMastered;

  int get totalLearning =>
      hiraganaLearning + katakanaLearning + kanjiLearning;

  double get quizAccuracy {
    if (quizQuestionsAnswered <= 0) {
      return 0;
    }
    return (quizCorrectAnswers / quizQuestionsAnswered).clamp(0.0, 1.0);
  }
}