class VocabularyWord {
  const VocabularyWord({
    required this.japanese,
    required this.furigana,
    required this.romaji,
    required this.english,
    required this.category,
  });

  final String japanese;
  final String furigana;  // hiragana reading
  final String romaji;
  final String english;
  final String category;
}
