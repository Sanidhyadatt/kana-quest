import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.dart';
import '../../../core/services/streak_service.dart';
import '../../home/domain/world_map_progress.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/domain/services/srs_service.dart';
import '../domain/achievement.dart';
import '../domain/dojo_stats.dart';
import '../../quiz/data/quiz_history_repository.dart';

class DojoRepository {
  const DojoRepository({required this.isar});

  final Isar isar;

  Future<DojoStats> fetchStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(AppPrefsKeys.userName) ?? 'Scholar';
    final dailyGoal = prefs.getInt(AppPrefsKeys.dailyGoal) ?? 10;
    final quizHistory = await const QuizHistoryRepository().loadSessions();
    final quizAttempts = quizHistory.isNotEmpty
        ? quizHistory.length
        : (prefs.getInt(AppPrefsKeys.quizAttempts) ?? 0);
    final quizCorrectAnswers = quizHistory.isNotEmpty
        ? quizHistory.fold<int>(
            0,
            (sum, session) => sum + session.correctAnswers,
          )
        : (prefs.getInt(AppPrefsKeys.quizCorrectAnswers) ?? 0);
    final quizQuestionsAnswered = quizHistory.isNotEmpty
        ? quizHistory.fold<int>(
            0,
            (sum, session) => sum + session.totalQuestions,
          )
        : (prefs.getInt(AppPrefsKeys.quizQuestionsAnswered) ?? 0);

    const streakSvc = StreakService();
    final streak = await streakSvc.getStreak();
    final reviewDates = await streakSvc.getReviewDates();
    final weeklyReviewDays = await streakSvc.getWeeklyReviewCount();

    final cards = await isar.kanaCards.where().findAll();
    const srs = SrsService();

    final hCards = cards.where((c) => c.script == 0);
    final katCards = cards.where((c) => c.script == 1);
    final kanCards = cards.where((c) => c.script == 2);

    final hRowGroups = _groupByRow(hCards);
    final katRowGroups = _groupByRow(katCards);
    final kanRowGroups = _groupByRow(kanCards);

    final hMastered = _completedRowCount(hRowGroups, srs);
    final hLearning = _inProgressRowCount(hRowGroups, srs);

    final katMastered = _completedRowCount(katRowGroups, srs);
    final katLearning = _inProgressRowCount(katRowGroups, srs);

    final kanMastered = _completedRowCount(kanRowGroups, srs);
    final kanLearning = _inProgressRowCount(kanRowGroups, srs);

    final totalReviewed = cards.where(srs.isCardCompleted).length;
    final totalMastered = hMastered + katMastered + kanMastered;

    final now = DateTime.now();
    final xp =
        totalMastered * 20 +
        cards.where((c) => !c.nextReviewDate.isAfter(now)).length * 2;

    final level = (xp / 100).floor() + 1;
    final xpToNext = (level * 100) - xp;

    final rankProgress = rankFromXp(xp);

    final weeklyGoalDays = dailyGoal >= 15
        ? 6
        : dailyGoal >= 8
        ? 5
        : 3;

    return DojoStats(
      userName: userName,
      rank: rankProgress.label,
      level: level,
      xp: xp,
      xpToNextLevel: xpToNext < 0 ? 0 : xpToNext,
      currentStreak: streak,
      weeklyReviewDays: weeklyReviewDays,
      weeklyGoalDays: weeklyGoalDays,
      hiraganaMastered: hMastered,
      hiraganaLearning: hLearning,
      katakanaMastered: katMastered,
      katakanaLearning: katLearning,
      kanjiMastered: kanMastered,
      kanjiLearning: kanLearning,
      reviewDates: reviewDates,
      achievements: Achievement.compute(
        streak: streak,
        xp: xp,
        kanaMastered: hMastered,
        totalCardsReviewed: totalReviewed,
        totalKana: hRowGroups.length,
      ),
      totalCardsReviewed: totalReviewed,
      quizAttempts: quizAttempts,
      quizCorrectAnswers: quizCorrectAnswers,
      quizQuestionsAnswered: quizQuestionsAnswered,
    );
  }
}

Map<int, List<KanaCard>> _groupByRow(Iterable<KanaCard> cards) {
  final rows = <int, List<KanaCard>>{};
  for (final card in cards) {
    rows.putIfAbsent(card.row, () => <KanaCard>[]).add(card);
  }
  return rows;
}

int _completedRowCount(Map<int, List<KanaCard>> rows, SrsService srs) {
  return rows.values
      .where(
        (rowCards) =>
            rowCards.isNotEmpty && rowCards.every(srs.isCardCompleted),
      )
      .length;
}

int _inProgressRowCount(Map<int, List<KanaCard>> rows, SrsService srs) {
  return rows.values.where((rowCards) {
    if (rowCards.isEmpty) {
      return false;
    }

    final anyCompleted = rowCards.any(srs.isCardCompleted);
    final allCompleted = rowCards.every(srs.isCardCompleted);
    return anyCompleted && !allCompleted;
  }).length;
}
