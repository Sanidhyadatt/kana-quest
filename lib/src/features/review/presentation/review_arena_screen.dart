import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../../core/storage/isar_database.dart';
import '../../lessons/data/models/kana_card.dart';
import '../../lessons/domain/services/srs_service.dart';

class ReviewArenaScreen extends StatefulWidget {
  const ReviewArenaScreen({super.key});

  @override
  State<ReviewArenaScreen> createState() => _ReviewArenaScreenState();
}

class _ReviewArenaScreenState extends State<ReviewArenaScreen> {
  final SrsService _srsService = const SrsService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  Isar? _isar;
  List<KanaCard> _dueCards = <KanaCard>[];
  bool _isLoading = true;
  bool _isBackVisible = false;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final isar = await IsarDatabase.open();
    final now = DateTime.now();
    final cards = await isar.kanaCards.where().findAll();

    final due =
        cards.where((card) => !card.nextReviewDate.isAfter(now)).toList()
          ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

    if (!mounted) {
      return;
    }

    setState(() {
      _isar = isar;
      _dueCards = due;
      _isLoading = false;
      _isBackVisible = false;
      _reviewedCount = 0;
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
    });

    if (_dueCards.isEmpty) {
      _confettiController.play();
    }
  }

  void _playAudioHint(String character) {
    SystemSound.play(SystemSoundType.click);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio for "$character" will be added in a later phase.'),
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
                  ? _SessionCompleteView(reviewedCount: _reviewedCount)
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
          _SessionMeta(
            reviewedCount: _reviewedCount,
            remainingCount: _dueCards.length,
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
                      Text(
                        card.character,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card.script == KanaScript.hiragana
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

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({
    required this.reviewedCount,
    required this.remainingCount,
  });

  final int reviewedCount;
  final int remainingCount;

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
            child: Text(
              '$remainingCount card${remainingCount == 1 ? '' : 's'} left',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Reviewed: $reviewedCount',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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

class _SessionCompleteView extends StatelessWidget {
  const _SessionCompleteView({required this.reviewedCount});

  final int reviewedCount;

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
                  'You reviewed $reviewedCount cards. Great work.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
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
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _rotation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

  bool _isBackVisible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    HapticFeedback.lightImpact();

    if (_isBackVisible) {
      await _controller.reverse();
    } else {
      await _controller.forward();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isBackVisible = !_isBackVisible;
    });
    widget.onFlipChanged(_isBackVisible);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          final angle = _rotation.value * math.pi;
          final isFront = angle <= math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            child: Transform(
              alignment: Alignment.center,
              transform: isFront ? Matrix4.identity() : Matrix4.identity()
                ..rotateY(math.pi),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                  minHeight: 280,
                  maxHeight: 520,
                ),
                child: isFront ? widget.front : widget.back,
              ),
            ),
          );
        },
      ),
    );
  }
}
