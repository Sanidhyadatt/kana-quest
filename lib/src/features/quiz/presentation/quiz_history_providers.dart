import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quiz_history_repository.dart';
import '../domain/quiz_history.dart';

final quizHistoryProvider = FutureProvider<List<QuizSessionRecord>>((
  ref,
) async {
  return const QuizHistoryRepository().loadSessions();
});
