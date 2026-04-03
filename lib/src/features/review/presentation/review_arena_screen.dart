import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/isar_database.dart';
import '../../dojo/presentation/dojo_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/data/seed/kana_seed_data.dart';
import '../../lessons/data/seed/stroke_order_data.dart';
import '../../lessons/presentation/mnemonic_discovery_screen.dart';
import '../../lessons/domain/services/srs_service.dart';
import '../../../core/services/streak_service.dart';

class ReviewArenaScreen extends StatefulWidget {
  const ReviewArenaScreen({super.key, this.initialRow, this.scriptType = 0});

  final int? initialRow;
  final int scriptType;

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
    final allSeeds = [
      ...seedKanaCards,
      ...seedKatakanaCards,
      ...seedKanjiCards,
    ];
    for (var i = 0; i < allSeeds.length; i += 1) {
      final seed = allSeeds[i];
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
        .where(
          (card) =>
              card.character.trim().isNotEmpty &&
              card.script == widget.scriptType,
        )
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
    List<KanaCard> sessionCards = dueCards.isNotEmpty
        ? dueCards
        : currentRowFallback;

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

    final card = _dueCards.removeAt(0);

    // If "Don't Know" (Rating 1), put it at the end of the queue for re-practice
    if (rating == 1) {
      _dueCards.add(card);
    }

    _srsService.applyReview(card: card, rating: rating);

    await _isar!.writeTxn(() async {
      await _isar!.kanaCards.put(card);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _isBackVisible = false;
      _comboStreak = rating >= 3 ? _comboStreak + 1 : 0;
      if (rating >= 3) {
        _reviewedCount += 1;
      }
    });

    await const StreakService().recordReview();

    if (mounted) {
      final container = ProviderScope.containerOf(context, listen: false);
      container.invalidate(dojoStatsProvider);
      container.invalidate(worldMapProgressProvider);
    }

    if (_dueCards.isEmpty) {
      _confettiController.play();
    }
  }

  Future<void> _playAudioHint(String character) async {
    SystemSound.play(SystemSoundType.click);

    // Robust lookup for Kanji readings
    final char = character.trim();
    final info = kanaCharacterInfo[char];
    final toSpeak = info?.reading ?? char;

    if (_ttsAvailable) {
      try {
        await _tts.stop();
        await _tts.setLanguage('ja-JP');
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        await _tts.speak(toSpeak);
        return;
      } catch (_) {
        _ttsAvailable = false;
      }
    }

    if (!kIsWeb && Platform.isLinux) {
      final worked = await _speakWithLinuxTts(toSpeak);
      if (worked) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio playback is unavailable on this device.'),
      ),
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
        final result = await Process.run(attempt.command, [
          ...attempt.args.sublist(0, attempt.args.length - 1),
          '-r',
          '-10',
          text,
        ]);
        if (result.exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }

  void _continueToNextSection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => ReviewArenaScreen(
          initialRow: _activeRow + 1,
          scriptType: widget.scriptType,
        ),
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
    final scriptLabel = card.script == 0
        ? 'Hiragana'
        : card.script == 1
        ? 'Katakana'
        : 'Kanji';

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
                        scriptLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                back: _CardFace(
                  title: 'Result',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pronunciation: ${card.romaji.toUpperCase()}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        card.mnemonic,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _playAudioHint(card.character),
                            icon: const Icon(Icons.volume_up_rounded),
                            label: const Text('Audio'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.85,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(32),
                                    ),
                                  ),
                                  child: MnemonicDiscoveryScreen(
                                    character: card.character,
                                    romaji: card.romaji,
                                    mnemonic: card.mnemonic,
                                    relatedWords: card.relatedWords,
                                    scriptType: card.script,
                                    cardId: card.id,
                                    showGotIt: false,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.lightbulb_outline_rounded),
                            label: const Text('Guide'),
                          ),
                        ],
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
          TextButton(onPressed: onExit, child: const Text('Back')),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _RatingButton(
              label: "Don't Know",
              icon: Icons.close_rounded,
              color: Theme.of(context).colorScheme.error,
              enabled: enabled,
              onTap: () => onRate(1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _RatingButton(
              label: "Know",
              icon: Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
              enabled: enabled,
              onTap: () => onRate(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? color : color.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeColor.withValues(alpha: 0.1),
                  activeColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: activeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                  scale: Tween<double>(
                    begin: 0.98,
                    end: 1.0,
                  ).animate(animation),
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
