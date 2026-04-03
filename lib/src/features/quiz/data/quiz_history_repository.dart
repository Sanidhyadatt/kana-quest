import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.dart';
import '../domain/quiz_history.dart';

class QuizHistoryRepository {
  const QuizHistoryRepository();

  static const int _maxSessions = 20;

  Future<List<QuizSessionRecord>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedSessions =
        prefs.getStringList(AppPrefsKeys.quizHistorySessions) ?? const [];

    final sessions = <QuizSessionRecord>[];
    for (final encoded in encodedSessions) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          sessions.add(QuizSessionRecord.fromJson(decoded));
        }
      } catch (_) {
        // Skip malformed records.
      }
    }

    sessions.sort(
      (left, right) => right.completedAt.compareTo(left.completedAt),
    );
    return sessions;
  }

  Future<void> saveSession(QuizSessionRecord session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();

    sessions.insert(0, session);
    if (sessions.length > _maxSessions) {
      sessions.removeRange(_maxSessions, sessions.length);
    }

    await prefs.setStringList(
      AppPrefsKeys.quizHistorySessions,
      sessions
          .map((record) => jsonEncode(record.toJson()))
          .toList(growable: false),
    );
  }
}
