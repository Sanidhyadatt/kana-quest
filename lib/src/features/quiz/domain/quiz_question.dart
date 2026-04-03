enum QuizQuestionType {
  /// Show a kana character → choose correct romaji
  kanaToRomaji,
  /// Show English meaning → choose correct Japanese word
  englishToJapanese,
  /// Show Japanese word → choose correct English meaning
  japaneseToEnglish,
}

class QuizQuestion {
  const QuizQuestion({
    required this.type,
    required this.prompt,
    required this.promptSubtitle,
    required this.correctAnswer,
    required this.choices,
  });

  final QuizQuestionType type;
  /// What is shown prominently (the character/word to identify)
  final String prompt;
  /// Optional subtitle shown under the prompt
  final String promptSubtitle;
  final String correctAnswer;
  final List<String> choices; // includes correctAnswer, shuffled
}
