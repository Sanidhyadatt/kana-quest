import 'dart:math';

import '../../../features/vocabulary/data/vocabulary_repository.dart';
import '../../../features/vocabulary/domain/vocabulary_word.dart';
import 'quiz_question.dart';

/// Generates a randomised quiz session.
class QuizGenerator {
  QuizGenerator({int? seed}) : _rng = Random(seed);

  final Random _rng;
  final _vocabRepo = const VocabularyRepository();

  /// Kana (hiragana A-row) character → romaji map
  static const _hiragana = <String, String>{
    'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
    'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
    'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
    'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
    'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
    'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
    'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
    'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
    'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
    'わ': 'wa', 'を': 'wo', 'ん': 'n',
  };

  static const _katakana = <String, String>{
    'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
    'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
    'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
    'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
    'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
    'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
    'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
    'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
    'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
    'ワ': 'wa', 'ヲ': 'wo', 'ン': 'n',
  };

  static const _kanji = <String, String>{
    '一': 'ichi', '二': 'ni', '三': 'san', '四': 'shi', '五': 'go',
    '六': 'roku', '七': 'nana', '八': 'hachi', '九': 'kyuu', '十': 'juu',
    '日': 'hi', '月': 'tsuki', '火': 'hi', '水': 'mizu', '木': 'ki',
    '金': 'kane', '土': 'tsuchi',
  };

  /// Generates [count] random quiz questions mixing all types.
  List<QuizQuestion> generate({int count = 10}) {
    final questions = <QuizQuestion>[];

    // Generate script questions (Hiragana/Katakana/Kanji)
    final scriptQuestions = _generateScriptQuestions();
    // Generate vocabulary questions
    final vocabQuestions = _generateVocabQuestions();

    final allPool = [...scriptQuestions, ...vocabQuestions];
    allPool.shuffle(_rng);

    for (int i = 0; i < count && i < allPool.length; i++) {
      questions.add(allPool[i]);
    }

    return questions;
  }

  List<QuizQuestion> _generateScriptQuestions() {
    final questions = <QuizQuestion>[];
    final allChars = <String, String>{..._hiragana, ..._katakana, ..._kanji};
    final entries = allChars.entries.toList()..shuffle(_rng);

    for (final entry in entries.take(30)) {
      final char = entry.key;
      final correctRomaji = entry.value;

      // Generate 3 wrong choices
      final wrongRomajis = allChars.values
          .where((v) => v != correctRomaji)
          .toSet() 
          .toList()
        ..shuffle(_rng);
      final choices = [correctRomaji, ...wrongRomajis.take(3)]..shuffle(_rng);

      String subtitle = 'Script';
      final code = char.codeUnitAt(0);
      if (code < 0x30A0 && _hiragana.containsKey(char)) {
        subtitle = 'Hiragana';
      } else if (code >= 0x30A0 && code < 0x3100) {
        subtitle = 'Katakana';
      } else if (_kanji.containsKey(char)) {
        subtitle = 'Kanji';
      }

      questions.add(QuizQuestion(
        type: QuizQuestionType.kanaToRomaji,
        prompt: char,
        promptSubtitle: subtitle,
        correctAnswer: correctRomaji,
        choices: choices,
      ));
    }
    return questions;
  }

  List<QuizQuestion> _generateVocabQuestions() {
    final questions = <QuizQuestion>[];
    final words = List<VocabularyWord>.from(_vocabRepo.getAllWords())..shuffle(_rng);

    for (final word in words.take(30)) {
      // Type A: show Japanese → choose English
      final wrongEnglish = _vocabRepo.getAllWords()
          .where((w) => w.english != word.english)
          .map((w) => w.english)
          .toList()
        ..shuffle(_rng);
      final choicesA = [word.english, ...wrongEnglish.take(3)]..shuffle(_rng);

      questions.add(QuizQuestion(
        type: QuizQuestionType.japaneseToEnglish,
        prompt: word.japanese,
        promptSubtitle: word.romaji,
        correctAnswer: word.english,
        choices: choicesA,
      ));

      // Type B: show English → choose Japanese
      final wrongJapanese = _vocabRepo.getAllWords()
          .where((w) => w.japanese != word.japanese)
          .map((w) => w.japanese)
          .toList()
        ..shuffle(_rng);
      final choicesB = [word.japanese, ...wrongJapanese.take(3)]..shuffle(_rng);

      questions.add(QuizQuestion(
        type: QuizQuestionType.englishToJapanese,
        prompt: word.english,
        promptSubtitle: 'Choose the Japanese word',
        correctAnswer: word.japanese,
        choices: choicesB,
      ));
    }

    return questions;
  }
}
