import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/presentation/home_providers.dart';
import '../../../app/app.dart';
import '../domain/quiz_generator.dart';
import '../domain/quiz_question.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with TickerProviderStateMixin {
  static const _totalQuestions = 10;

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedChoice;
  bool _answered = false;
  int _correctCount = 0;
  bool _questionReady = false;
  bool _sessionRecorded = false;

  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
    _generateQuestions();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }


  Future<void> _generateQuestions() async {
    if (!mounted) return;

    final newQuestions = QuizGenerator().generate(count: _totalQuestions);
    
    setState(() {
      _questions = newQuestions;
      _currentIndex = 0;
      _selectedChoice = null;
      _answered = false;
      _correctCount = 0;
      _questionReady = false;
      _sessionRecorded = false;
    });
    if (newQuestions.isNotEmpty) {
      _progressController.animateTo(1 / _totalQuestions);
    }
  }

  void _onChoiceTap(String choice) {
    if (_answered || !_questionReady) return;
    final isCorrect = choice == _questions[_currentIndex].correctAnswer;

    setState(() {
      _selectedChoice = choice;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
      }
    });

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _bounceController.forward(from: 0);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex + 1 >= _questions.length) {
      await _recordQuizSession();
      // Go to results
      setState(() {
        _currentIndex = _questions.length; // signal "done"
      });
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _answered = false;
      // We keep _questionReady true so it doesn't ask again!
    });
    _progressController.animateTo((_currentIndex + 1) / _totalQuestions);
  }

  Future<void> _recordQuizSession() async {
    if (_sessionRecorded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(AppPrefsKeys.quizAttempts) ?? 0;
    final correctAnswers = prefs.getInt(AppPrefsKeys.quizCorrectAnswers) ?? 0;
    final questionsAnswered =
        prefs.getInt(AppPrefsKeys.quizQuestionsAnswered) ?? 0;

    await prefs.setInt(AppPrefsKeys.quizAttempts, attempts + 1);
    await prefs.setInt(
      AppPrefsKeys.quizCorrectAnswers,
      correctAnswers + _correctCount,
    );
    await prefs.setInt(
      AppPrefsKeys.quizQuestionsAnswered,
      questionsAnswered + _questions.length,
    );

    _sessionRecorded = true;
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Score screen
    if (_currentIndex >= _questions.length && _questions.isNotEmpty) {
      return _ScoreScreen(
        correct: _correctCount,
        total: _totalQuestions,
        onRestart: _generateQuestions,
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_rounded, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Initializing Quiz...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _generateQuestions,
                child: const Text('Still loading? Tap to Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.2),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    // Progress indicator
                    Text(
                      '${_currentIndex + 1} / $_totalQuestions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    // Score chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✓ $_correctCount',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) => LinearProgressIndicator(
                    value: _progressController.value,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primary,
                  ),
                ),
              ),

              // ── Question card ─────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Question type label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _questionTypeLabel(question.type),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Prompt
                      ScaleTransition(
                        scale: _bounceAnim,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      question.prompt,
                                      textAlign: TextAlign.center,
                                      style: _promptTextStyle(context, question.type),
                                    ),
                                    if (question.promptSubtitle.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        question.promptSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                                color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (!_questionReady)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Ready for this one?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    setState(() {
                                      _questionReady = true;
                                    });
                                  },
                                  child: const Text('I\'m Ready'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_questionReady)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.4,
                          ),
                          itemCount: question.choices.length,
                          itemBuilder: (context, i) {
                            final choice = question.choices[i];
                            return _ChoiceTile(
                              choice: choice,
                              selected: _selectedChoice == choice,
                              answered: _answered,
                              isCorrect: choice == question.correctAnswer,
                              onTap: () => _onChoiceTap(choice),
                            );
                          },
                        ),

                      const Spacer(),

                      // Continue / feedback
                      if (_questionReady && _answered) ...[
                        _FeedbackBanner(
                          isCorrect: _selectedChoice == question.correctAnswer,
                          correctAnswer: question.correctAnswer,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _nextQuestion,
                            child: Text(
                              _currentIndex + 1 >= _totalQuestions
                                  ? 'See Results'
                                  : 'Continue',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _questionTypeLabel(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.kanaToRomaji:
        return 'WHAT IS THE READING?';
      case QuizQuestionType.japaneseToEnglish:
        return 'WHAT DOES THIS MEAN?';
      case QuizQuestionType.englishToJapanese:
        return 'CHOOSE THE JAPANESE WORD';
    }
  }

  TextStyle? _promptTextStyle(BuildContext context, QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.kanaToRomaji:
        return Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
            );
      case QuizQuestionType.japaneseToEnglish:
        return Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
            );
      case QuizQuestionType.englishToJapanese:
        return Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            );
    }
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  final String choice;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (!answered) {
      bgColor = scheme.surfaceContainerLowest;
      textColor = scheme.onSurface;
      borderColor = scheme.outlineVariant;
    } else if (isCorrect) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green.shade700;
      borderColor = Colors.green;
    } else if (selected) {
      bgColor = Colors.red.withValues(alpha: 0.12);
      textColor = Colors.red.shade700;
      borderColor = Colors.red;
    } else {
      bgColor = scheme.surfaceContainerLowest.withValues(alpha: 0.5);
      textColor = scheme.onSurface.withValues(alpha: 0.4);
      borderColor = scheme.outlineVariant.withValues(alpha: 0.4);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: answered && isCorrect
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: answered ? null : onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              choice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.isCorrect, required this.correctAnswer});
  final bool isCorrect;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isCorrect ? Colors.green : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '🎉 Correct!' : '✗ Incorrect',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (!isCorrect)
                  Text(
                    'Correct answer: $correctAnswer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreScreen extends ConsumerWidget {
  const _ScoreScreen({
    required this.correct,
    required this.total,
    required this.onRestart,
  });

  final int correct;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (correct / total * 100).round();
    final emoji = pct == 100 ? '🏆' : pct >= 80 ? '🎉' : pct >= 60 ? '😊' : '📚';
    final message = pct == 100
        ? 'Perfect score!'
        : pct >= 80
            ? 'Great job!'
            : pct >= 60
                ? 'Good effort!'
                : 'Keep practising!';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.4),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correct / $total correct',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: correct / total,
                          strokeWidth: 12,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: pct >= 80 ? Colors.green : scheme.primary,
                        ),
                        Text(
                          '$pct%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Try Again',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Switch back to Learn tab and reset quiz state by generating new questions
                        ref.read(selectedTabProvider.notifier).state = 0;
                        onRestart(); 
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Back to Home',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
