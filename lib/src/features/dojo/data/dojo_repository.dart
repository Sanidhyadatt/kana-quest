import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.dart';
import '../../../core/services/streak_service.dart';
import '../../home/domain/world_map_progress.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/domain/services/srs_service.dart';
import '../domain/achievement.dart';
import '../domain/dojo_stats.dart';

class DojoRepository {
  const DojoRepository({required this.isar});

  final Isar isar;

  Future<DojoStats> fetchStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(AppPrefsKeys.userName) ?? 'Scholar';
    final dailyGoal = prefs.getInt(AppPrefsKeys.dailyGoal) ?? 10;

    const streakSvc = StreakService();
    final streak = await streakSvc.getStreak();
    final reviewDates = await streakSvc.getReviewDates();
    final weeklyReviewDays = await streakSvc.getWeeklyReviewCount();

    final cards = await isar.kanaCards.where().findAll();
    const srs = SrsService();

    final hCards = cards.where((c) => c.script == 0);
    final katCards = cards.where((c) => c.script == 1);
    final kanCards = cards.where((c) => c.script == 2);

    final hMastered = hCards.where(srs.isCardMastered).length;
    final hLearning = hCards.where((c) => srs.isCardCompleted(c) && !srs.isCardMastered(c)).length;

    final katMastered = katCards.where(srs.isCardMastered).length;
    final katLearning = katCards.where((c) => srs.isCardCompleted(c) && !srs.isCardMastered(c)).length;

    final kanMastered = kanCards.where(srs.isCardMastered).length;
    final kanLearning = kanCards.where((c) => srs.isCardCompleted(c) && !srs.isCardMastered(c)).length;

    final totalReviewed = cards.where(srs.isCardCompleted).length;
    final totalMastered = hMastered + katMastered + kanMastered;

    final now = DateTime.now();
    final xp =
        totalMastered * 20 +
        cards.where((c) => !c.nextReviewDate.isAfter(now)).length * 2;

    final level = (xp / 100).floor() + 1;
    final xpToNext = (level * 100) - xp;

    final rankProgress = rankFromXp(xp);

    final weeklyGoalDays = dailyGoal >= 15 ? 6 : dailyGoal >= 8 ? 5 : 3;

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
        kanaMastered: totalMastered,
        totalCardsReviewed: totalReviewed,
        totalKana: cards.length,
      ),
      totalCardsReviewed: totalReviewed,
    );
  }
}