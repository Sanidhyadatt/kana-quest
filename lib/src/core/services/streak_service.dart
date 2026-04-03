import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the user's daily study streak and review calendar.
class StreakService {
  const StreakService();

  static const _streakKey = 'streak_count';
  static const _lastReviewKey = 'last_review_date';
  static const _reviewDatesKey = 'review_dates';

  /// Call once per review session. Increments streak when called on a new day.
  Future<void> recordReview() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastReview = prefs.getString(_lastReviewKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;

    await _addReviewDate(prefs, today);

    if (lastReview == today) return; // Already recorded today

    final int newStreak;
    if (lastReview == null) {
      newStreak = 1;
    } else {
      final yesterdayKey =
          _dateKey(DateTime.now().subtract(const Duration(days: 1)));
      newStreak = (lastReview == yesterdayKey) ? currentStreak + 1 : 1;
    }

    await prefs.setInt(_streakKey, newStreak);
    await prefs.setString(_lastReviewKey, today);
  }

  /// Returns current streak, resetting to 0 if the streak is broken.
  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReview = prefs.getString(_lastReviewKey);
    if (lastReview == null) return 0;

    final today = _dateKey(DateTime.now());
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    if (lastReview != today && lastReview != yesterday) {
      await prefs.setInt(_streakKey, 0);
      return 0;
    }

    return prefs.getInt(_streakKey) ?? 0;
  }

  /// Returns the set of date strings (yyyy-MM-dd) that had at least one review.
  Future<Set<String>> getReviewDates() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_reviewDatesKey);
    if (json == null) return {};
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  /// Returns how many distinct days in the last 7 days had a review.
  Future<int> getWeeklyReviewCount() async {
    final dates = await getReviewDates();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return dates.where((d) {
      try {
        return DateTime.parse(d).isAfter(weekAgo);
      } catch (_) {
        return false;
      }
    }).length;
  }

  Future<void> _addReviewDate(SharedPreferences prefs, String date) async {
    final json = prefs.getString(_reviewDatesKey);
    final Set<String> dates =
        json == null
            ? {}
            : (jsonDecode(json) as List).cast<String>().toSet();
    dates.add(date);

    // Keep only the last 120 days
    final cutoff = DateTime.now().subtract(const Duration(days: 120));
    dates.removeWhere((d) {
      try {
        return DateTime.parse(d).isBefore(cutoff);
      } catch (_) {
        return false;
      }
    });

    await prefs.setString(_reviewDatesKey, jsonEncode(dates.toList()));
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}