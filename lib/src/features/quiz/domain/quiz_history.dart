import 'quiz_question.dart';

class QuizAnswerRecord {
  const QuizAnswerRecord({
    required this.questionType,
    required this.prompt,
    required this.promptSubtitle,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  factory QuizAnswerRecord.fromQuestion(
    QuizQuestion question,
    String selectedAnswer,
  ) {
    return QuizAnswerRecord(
      questionType: question.type,
      prompt: question.prompt,
      promptSubtitle: question.promptSubtitle,
      correctAnswer: question.correctAnswer,
      selectedAnswer: selectedAnswer,
      isCorrect: selectedAnswer == question.correctAnswer,
    );
  }

  factory QuizAnswerRecord.fromJson(Map<String, dynamic> json) {
    return QuizAnswerRecord(
      questionType: QuizQuestionType.values.firstWhere(
        (type) => type.name == (json['questionType'] as String? ?? ''),
        orElse: () => QuizQuestionType.kanaToRomaji,
      ),
      prompt: json['prompt'] as String? ?? '',
      promptSubtitle: json['promptSubtitle'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      selectedAnswer: json['selectedAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  final QuizQuestionType questionType;
  final String prompt;
  final String promptSubtitle;
  final String correctAnswer;
  final String selectedAnswer;
  final bool isCorrect;

  String get questionTypeLabel {
    return switch (questionType) {
      QuizQuestionType.kanaToRomaji => 'Kana → Romaji',
      QuizQuestionType.englishToJapanese => 'English → Japanese',
      QuizQuestionType.japaneseToEnglish => 'Japanese → English',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'questionType': questionType.name,
      'prompt': prompt,
      'promptSubtitle': promptSubtitle,
      'correctAnswer': correctAnswer,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
    };
  }
}

class QuizSessionRecord {
  const QuizSessionRecord({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.answers,
  });

  factory QuizSessionRecord.fromJson(Map<String, dynamic> json) {
    final rawAnswers = (json['answers'] as List<dynamic>? ?? const []);

    return QuizSessionRecord(
      id: json['id'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      answers: rawAnswers
          .whereType<Map<String, dynamic>>()
          .map(QuizAnswerRecord.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<QuizAnswerRecord> answers;

  int get totalQuestions => answers.length;

  int get correctAnswers => answers.where((answer) => answer.isCorrect).length;

  int get wrongAnswers => totalQuestions - correctAnswers;

  double get accuracy {
    if (totalQuestions <= 0) {
      return 0;
    }

    return correctAnswers / totalQuestions;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'answers': answers
          .map((answer) => answer.toJson())
          .toList(growable: false),
    };
  }
}
