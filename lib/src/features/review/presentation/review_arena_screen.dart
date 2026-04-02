import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:isar/isar.dart';

import '../../../core/storage/isar_database.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/data/seed/kana_seed_data.dart';
import '../../lessons/domain/services/srs_service.dart';

class ReviewArenaScreen extends StatefulWidget {
  const ReviewArenaScreen({super.key, this.initialRow});

  final int? initialRow;

  @override
  State<ReviewArenaScreen> createState() => _ReviewArenaScreenState();
}

class _ReviewArenaScreenState extends State<ReviewArenaScreen> {
  final SrsService _srsService = const SrsService();
  final FlutterTts _tts = FlutterTts();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  Isar? _isar;
  List<KanaCard> _dueCards = <KanaCard>[];
  bool _isLoading = true;
  bool _isBackVisible = false;
  bool _isPracticeMode = false;
  bool _hasNextSection = false;
  int _activeRow = 0;
  int _reviewedCount = 0;
  int _comboStreak = 0;
  bool _ttsAvailable = false;

  static final Map<int, Map<String, int>> _rowCharacterOrder = () {
    final order = <int, Map<String, int>>{};
    for (var i = 0; i < seedKanaCards.length; i += 1) {
      final seed = seedKanaCards[i];
      final rowOrder = order.putIfAbsent(seed.row, () => <String, int>{});
      rowOrder[seed.character] = i;
    }
    return order;
  }();

  @override
  void initState() {
    super.initState();
    _configureTts();
    _loadSession();
  }

  @override
  void dispose() {
    if (_ttsAvailable) {
      _tts.stop().catchError((_) {});
    }
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _ttsAvailable = true;
    } catch (_) {
      _ttsAvailable = false;
    }
  }

  Future<void> _loadSession() async {
    final isar = await IsarDatabase.getInstance();
    final now = DateTime.now();
    final cards = await isar.kanaCards.where().findAll();

    final validCards = cards
        .where((card) => card.character.trim().runes.length == 1)
        .toList();

    final availableRows = validCards.map((card) => card.row).toSet().toList()
      ..sort();

    final requestedRow = widget.initialRow ?? 0;
    final baseRow = availableRows.contains(requestedRow)
        ? requestedRow
        : (availableRows.isEmpty ? requestedRow : availableRows.first);

    final currentRowCards = validCards
        .where((card) => card.row == baseRow)
        .toList();

    final dueCards = currentRowCards
        .where((card) => !card.nextReviewDate.isAfter(now))
        .toList();
    _sortCardsForRow(dueCards, baseRow);

    var sessionRow = baseRow;
    final currentRowFallback = List<KanaCard>.from(currentRowCards);
    _sortCardsForRow(currentRowFallback, baseRow);
    List<KanaCard> sessionCards = dueCards.isNotEmpty ? dueCards : currentRowFallback;

    if (!mounted) {
      return;
    }

    setState(() {
      _isar = isar;
      _dueCards = sessionCards;
      _isLoading = false;
      _isBackVisible = false;
      _isPracticeMode = dueCards.isEmpty && currentRowCards.isNotEmpty;
      _hasNextSection = availableRows.any((row) => row > sessionRow);
      _activeRow = sessionRow;
      _reviewedCount = 0;
      _comboStreak = 0;
    });
  }

  void _sortCardsForRow(List<KanaCard> cards, int row) {
    final rowOrder = _rowCharacterOrder[row] ?? const <String, int>{};
    cards.sort((left, right) {
      final leftKey = rowOrder[left.character] ?? 1 << 20;
      final rightKey = rowOrder[right.character] ?? 1 << 20;
      if (leftKey != rightKey) {
        return leftKey.compareTo(rightKey);
      }

      return left.nextReviewDate.compareTo(right.nextReviewDate);
    });
  }

  Future<void> _rateCurrentCard(int rating) async {
    if (_dueCards.isEmpty || _isar == null) {
      return;
    }

    final card = _dueCards.first;
    _srsService.applyReview(card: card, rating: rating);

    await _isar!.writeTxn(() async {
      await _isar!.kanaCards.put(card);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _dueCards = List<KanaCard>.from(_dueCards)..removeAt(0);
      _reviewedCount += 1;
      _isBackVisible = false;
      _comboStreak = rating >= 3 ? _comboStreak + 1 : 0;
    });

    if (_dueCards.isEmpty) {
      _confettiController.play();
    }
  }

  Future<void> _playAudioHint(String character) async {
    SystemSound.play(SystemSoundType.click);

    if (_ttsAvailable) {
      try {
        await _tts.stop();
        await _tts.speak(character);
        return;
      } catch (_) {
        _ttsAvailable = false;
      }
    }

    if (!kIsWeb && Platform.isLinux) {
      final worked = await _speakWithLinuxTts(character);
      if (worked) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback is unavailable on this device.')),
    );
  }

  Future<bool> _speakWithLinuxTts(String text) async {
    final attempts = <({String command, List<String> args})>[
      (command: 'spd-say', args: <String>['-l', 'ja', text]),
      (command: 'espeak', args: <String>['-v', 'ja', text]),
      (command: 'espeak-ng', args: <String>['-v', 'ja', text]),
    ];

    for (final attempt in attempts) {
      try {
        final result = await Process.run(attempt.command, attempt.args);
        if (result.exitCode == 0) {
          return true;
        }
      } catch (_) {
        // Try next command.
      }
    }

    return false;
  }

  void _continueToNextSection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => ReviewArenaScreen(initialRow: _activeRow + 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Arena'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface,
                  scheme.surfaceContainerLow,
                  scheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dueCards.isEmpty
                  ? _SessionCompleteView(
                      reviewedCount: _reviewedCount,
                      activeRow: _activeRow,
                      hasNextSection: _hasNextSection,
                      onContinue: _continueToNextSection,
                    )
                  : _buildActiveSession(context),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              maxBlastForce: 28,
              minBlastForce: 12,
              gravity: 0.28,
              colors: [
                scheme.primary,
                scheme.secondary,
                scheme.tertiary,
                scheme.primaryContainer,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSession(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = _dueCards.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          if (_isPracticeMode)
            _PracticeModeBanner(onExit: () => Navigator.of(context).pop()),
          if (_isPracticeMode) const SizedBox(height: 12),
          _SessionMeta(
            activeRow: _activeRow,
            reviewedCount: _reviewedCount,
            remainingCount: _dueCards.length,
            comboStreak: _comboStreak,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: FlipCard(
                key: ValueKey<int>(card.id),
                onFlipChanged: (isBackVisible) {
                  setState(() {
                    _isBackVisible = isBackVisible;
                  });
                },
                front: _CardFace(
                  title: 'Tap To Reveal',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CardKanaText(value: card.character),
                      const SizedBox(height: 12),
                      Text(
                        card.script == 0
                            ? 'Hiragana'
                            : 'Katakana',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                back: _CardFace(
                  title: 'Mnemonic',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.mnemonic,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card.romaji,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () => _playAudioHint(card.character),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Play Audio'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RatingBar(enabled: _isBackVisible, onRate: _rateCurrentCard),
        ],
      ),
    );
  }
}

class _PracticeModeBanner extends StatelessWidget {
  const _PracticeModeBanner({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No cards are due right now. Practice mode is showing up to 10 cards.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onExit,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({
    required this.activeRow,
    required this.reviewedCount,
    required this.remainingCount,
    required this.comboStreak,
  });

  final int activeRow;
  final int reviewedCount;
  final int remainingCount;
  final int comboStreak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section ${activeRow + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$remainingCount card${remainingCount == 1 ? '' : 's'} left',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Reviewed: $reviewedCount',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (comboStreak > 1) ...[
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Combo x$comboStreak',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardKanaText extends StatelessWidget {
  const _CardKanaText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textDirection: TextDirection.ltr,
      softWrap: false,
      textAlign: TextAlign.center,
      locale: const Locale('ja', 'JP'),
      strutStyle: const StrutStyle(forceStrutHeight: true),
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: 0,
          ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.enabled, required this.onRate});

  final bool enabled;
  final Future<void> Function(int rating) onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RateButton(
            label: 'Again',
            rating: 1,
            enabled: enabled,
            onRate: onRate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RateButton(
            label: 'Hard',
            rating: 2,
            enabled: enabled,
            onRate: onRate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RateButton(
            label: 'Good',
            rating: 3,
            enabled: enabled,
            onRate: onRate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RateButton(
            label: 'Easy',
            rating: 4,
            enabled: enabled,
            onRate: onRate,
          ),
        ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.rating,
    required this.enabled,
    required this.onRate,
  });

  final String label;
  final int rating;
  final bool enabled;
  final Future<void> Function(int rating) onRate;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? () => onRate(rating) : null,
      child: Text(label),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }
}

class _SessionCompleteView extends StatelessWidget {
  const _SessionCompleteView({
    required this.reviewedCount,
    required this.activeRow,
    required this.hasNextSection,
    required this.onContinue,
  });

  final int reviewedCount;
  final int activeRow;
  final bool hasNextSection;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: scheme.secondary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 44,
                  color: scheme.tertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Session Complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reviewedCount == 0
                      ? 'No cards left in this section right now.'
                      : 'You reviewed $reviewedCount cards. Section ${activeRow + 1} complete.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasNextSection)
                  FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Start Next Section'),
                  ),
                if (hasNextSection) const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Return To World Map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.onFlipChanged,
  });

  final Widget front;
  final Widget back;
  final ValueChanged<bool> onFlipChanged;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  bool _isBackVisible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    HapticFeedback.lightImpact();

    await _controller.reverse();

    if (!mounted) {
      return;
    }

    setState(() {
      _isBackVisible = !_isBackVisible;
    });
    widget.onFlipChanged(_isBackVisible);

    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: FadeTransition(
        opacity: _fade,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
            minHeight: 280,
            maxHeight: 520,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<bool>(_isBackVisible),
              child: _isBackVisible ? widget.back : widget.front,
            ),
          ),
        ),
      ),
    );
  }
}
