import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../core/services/streak_service.dart';
import '../../../core/storage/isar_database.dart';
import '../../../core/widgets/sensei_fox.dart';
import '../../../core/utils/path_validator.dart';
import '../../dojo/presentation/dojo_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../data/models/kana_card.dart';
import '../data/seed/stroke_order_data.dart';
import '../data/repositories/stroke_path_repository.dart';
import '../domain/services/srs_service.dart';
import 'widgets/stroke_order_painter.dart';

class MnemonicDiscoveryScreen extends StatefulWidget {
  const MnemonicDiscoveryScreen({
    super.key,
    required this.character,
    required this.romaji,
    required this.mnemonic,
    this.relatedWords,
    this.scriptType = 0,
    this.cardId,
    this.showGotIt = true,
  });

  final String character;
  final String romaji;
  final String mnemonic;
  final String? relatedWords;
  final int scriptType;
  final int? cardId;
  final bool showGotIt;

  @override
  State<MnemonicDiscoveryScreen> createState() =>
      _MnemonicDiscoveryScreenState();
}

class _MnemonicDiscoveryScreenState extends State<MnemonicDiscoveryScreen> {
  final _tts = FlutterTts();
  bool _ttsAvailable = false;
  bool _practiceMode = false;
  bool _marking = false;
  bool _showStrokeGuide = false;
  bool _isDrawing = false;
  List<String>? _strokePaths;
  int _strokeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStrokeData();
    _initTts();
  }

  @override
  void dispose() {
    if (_ttsAvailable) _tts.stop().catchError((_) {});
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      if (mounted) setState(() => _ttsAvailable = true);
    } catch (_) {}
  }

  Future<void> _loadStrokeData() async {
    final fallbackData = StrokePathRepository().getStrokeData(
      widget.character.trim(),
    );

    if (widget.cardId == null) {
      if (!mounted) return;
      setState(() {
        _strokePaths = fallbackData?.paths;
        _strokeCount =
            fallbackData?.strokeCount ??
            kanaCharacterInfo[widget.character]?.strokeCount ??
            2;
      });
      return;
    }

    try {
      final isar = await IsarDatabase.getInstance();
      final card = await isar.kanaCards.get(widget.cardId!);
      final storedPaths = card?.strokePaths;
      final storedStrokeCount = card?.strokeCount ?? 0;
      final paths = storedPaths != null && storedPaths.isNotEmpty
          ? List<String>.from(storedPaths)
          : fallbackData?.paths;

      if (!mounted) return;
      setState(() {
        _strokePaths = paths;
        _strokeCount = storedStrokeCount > 0
            ? storedStrokeCount
            : (paths?.length ??
                  fallbackData?.strokeCount ??
                  kanaCharacterInfo[widget.character]?.strokeCount ??
                  2);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _strokePaths = fallbackData?.paths;
        _strokeCount =
            fallbackData?.strokeCount ??
            kanaCharacterInfo[widget.character]?.strokeCount ??
            2;
      });
    }
  }

  Future<void> _playAudio() async {
    SystemSound.play(SystemSoundType.click);

    // Robust lookup: trim character to handle accidental spaces
    final char = widget.character.trim();
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
        if (mounted) setState(() => _ttsAvailable = false);
      }
    }
    if (!kIsWeb && Platform.isLinux) {
      for (final cmd in [
        ['spd-say', '-l', 'ja', '-r', '-10', toSpeak],
        ['espeak', '-v', 'ja', '-s', '140', toSpeak],
      ]) {
        try {
          final r = await Process.run(cmd[0], cmd.sublist(1));
          if (r.exitCode == 0) return;
        } catch (_) {}
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio unavailable on this device.')),
      );
    }
  }

  Future<void> _gotIt() async {
    setState(() => _marking = true);
    try {
      if (widget.cardId != null) {
        final isar = await IsarDatabase.getInstance();
        final card = await isar.kanaCards.get(widget.cardId!);
        if (card != null) {
          const SrsService().applyReview(card: card, rating: 3);
          await isar.writeTxn(() => isar.kanaCards.put(card));
          await const StreakService().recordReview();
          final container = ProviderScope.containerOf(context, listen: false);
          container.invalidate(dojoStatsProvider);
          container.invalidate(worldMapProgressProvider);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _marking = false);
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = kanaCharacterInfo[widget.character];
    final strokePaths =
        _strokePaths ??
        StrokePathRepository().getStrokeData(widget.character.trim())?.paths;
    final strokeCount = _strokeCount > 0
        ? _strokeCount
        : (strokePaths?.length ?? info?.strokeCount ?? 2);
    final scriptName = widget.scriptType == 0
        ? 'Hiragana'
        : widget.scriptType == 1
        ? 'Katakana'
        : 'Kanji';

    return Scaffold(
      body: DecoratedBox(
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
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.character} — $scriptName',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: _isDrawing
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // ── Character hero ───────────────────────────
                    _SurfaceCard(
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availWidth = constraints.maxWidth;
                              final charSize = (availWidth * 0.45).clamp(
                                60.0,
                                110.0,
                              );
                              final imgSize = (availWidth * 0.38).clamp(
                                50.0,
                                120.0,
                              );
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.character,
                                    locale: const Locale('ja', 'JP'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: charSize,
                                          height: 1.0,
                                        ),
                                  ),
                                  if (widget.scriptType != 2) ...[
                                    SizedBox(width: availWidth * 0.06),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        'assets/mnemonics/${widget.romaji.toLowerCase()}.png',
                                        width: imgSize,
                                        height: imgSize,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => SizedBox(
                                          width: imgSize,
                                          height: imgSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.romaji.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonalIcon(
                            onPressed: _playAudio,
                            icon: const Icon(Icons.waves_rounded),
                            label: const Text('Play Audio'),
                          ),
                          const SizedBox(height: 24),
                          SenseiFox(
                            size: 70,
                            showSpeechBubble: true,
                            speechText:
                                "It sounds like '${widget.romaji.toUpperCase()}'! Look at the image to help you remember.",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Mnemonic ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '❝',
                            style: TextStyle(
                              fontSize: 24,
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.mnemonic,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    height: 1.55,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Related Words ─────────────────────────────
                    if (widget.relatedWords != null &&
                        widget.relatedWords!.isNotEmpty) ...[
                      _VocabularySection(relatedWords: widget.relatedWords!),
                      const SizedBox(height: 14),
                    ],

                    // ── Stroke Order Guide ─────────────────────────
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gesture_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Stroke Order Guide',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              Switch(
                                value: _showStrokeGuide,
                                onChanged: (v) =>
                                    setState(() => _showStrokeGuide = v),
                              ),
                            ],
                          ),
                          if (_showStrokeGuide) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sequence',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$strokeCount strokes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _StrokeOrderDisplay(
                              character: widget.character,
                              strokeCount: strokeCount,
                              strokePaths: strokePaths,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.front_hand_rounded,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tracing Practice',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('Trace Mode'),
                                  selected: _practiceMode,
                                  onSelected: (v) =>
                                      setState(() => _practiceMode = v),
                                ),
                              ],
                            ),
                            if (_practiceMode) ...[
                              const SizedBox(height: 12),
                              _TracingCanvas(
                                character: widget.character,
                                strokeCount: strokeCount,
                                strokePaths: strokePaths,
                                onDrawingStateChanged: (drawing) {
                                  if (mounted)
                                    setState(() => _isDrawing = drawing);
                                },
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Learn how to write this character step-by-step.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Got It button ─────────────────────────────
                    if (widget.showGotIt)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _marking ? null : _gotIt,
                          icon: _marking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.done_all_rounded),
                          label: const Text('Got it!'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Vocabulary Section
// ──────────────────────────────────────────────────────────────────────────────

class _VocabularySection extends StatelessWidget {
  const _VocabularySection({required this.relatedWords});
  final String relatedWords;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = relatedWords.split(';').map((s) {
      final parts = s.split('|');
      return (word: parts[0], meaning: parts.length > 1 ? parts[1] : '');
    }).toList();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                'Related Vocabulary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...words.map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.word,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          w.meaning,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Surface Card
// ──────────────────────────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stroke Order Display  (the "Sequence" grid)
// ──────────────────────────────────────────────────────────────────────────────

class _StrokeOrderDisplay extends StatelessWidget {
  const _StrokeOrderDisplay({
    required this.character,
    required this.strokeCount,
    this.strokePaths,
  });
  final String character;
  final int strokeCount;
  final List<String>? strokePaths;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paths =
        strokePaths ??
        StrokePathRepository().getStrokeData(character.trim())?.paths;
    final displayStrokeCount = paths?.length ?? strokeCount;

    // ── Fallback: no vector data  ─────────────────────────────
    if (paths == null || paths.isEmpty) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(displayStrokeCount, (i) {
          return _StrokeBox(
            color: scheme.primaryContainer.withValues(alpha: 0.4),
            label: '${i + 1}',
            child: Text(
              character,
              locale: const Locale('ja', 'JP'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: scheme.onSurface),
            ),
          );
        }),
      );
    }

    // ── Vector data available: Duolingo-style incremental boxes ──
    // Box k shows strokes 1..k with stroke k highlighted.
    final boxes = List.generate(displayStrokeCount, (i) {
      return _StrokeBox(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        label: '${i + 1}',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              character,
              locale: const Locale('ja', 'JP'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.10),
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            CustomPaint(
              size: const Size(52, 52),
              painter: StrokeOrderPainter(
                paths: paths,
                showUpTo: i + 1, // show strokes 0..i
                brushColor: scheme.primary,
                strokeWidth: 4.0,
                hintColor: scheme.primary.withValues(alpha: 0.4),
                showArrow: true,
              ),
            ),
          ],
        ),
      );
    });

    return Wrap(spacing: 10, runSpacing: 10, children: boxes);
  }
}

class _StrokeBox extends StatelessWidget {
  const _StrokeBox({
    required this.color,
    required this.child,
    required this.label,
  });
  final Color color;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: 72,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tracing Canvas  (the practice widget)
// ──────────────────────────────────────────────────────────────────────────────

class _TracingCanvas extends StatefulWidget {
  const _TracingCanvas({
    required this.character,
    required this.strokeCount,
    this.strokePaths,
    this.onDrawingStateChanged,
  });
  final String character;
  final int strokeCount;
  final List<String>? strokePaths;
  final ValueChanged<bool>? onDrawingStateChanged;

  @override
  State<_TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<_TracingCanvas>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────
  final _completedUserStrokes =
      <List<Offset>>[]; // screen-space strokes the user drew
  List<Offset> _currentStrokePoints = [];
  int _activeStrokeIndex = 0; // which stroke are we asking the user to draw?
  bool _completed = false;

  // Feedback state for the last committed stroke
  bool? _lastStrokeWasValid; // null → no result yet; true/false after release

  // Cached target points in canonical 109×109 space
  List<Offset>? _targetPoints;

  // canvas layout size (set in LayoutBuilder)
  Size _canvasSize = const Size(300, 260);

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _loadTargetPoints();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────

  void _loadTargetPoints() {
    final paths =
        widget.strokePaths ??
        StrokePathRepository().getStrokeData(widget.character.trim())?.paths;
    if (paths != null && _activeStrokeIndex < paths.length) {
      final svgPath = paths[_activeStrokeIndex];
      if (svgPath.isNotEmpty) {
        final path = parseSvgPathData(svgPath);
        _targetPoints = PathValidator.samplePath(path, interval: 2.0);
        return;
      }
    }
    _targetPoints = null;
  }

  int _totalStrokeCount() {
    final paths =
        widget.strokePaths ??
        StrokePathRepository().getStrokeData(widget.character.trim())?.paths;
    return paths?.length ?? widget.strokeCount;
  }

  void _reset() {
    setState(() {
      _completedUserStrokes.clear();
      _currentStrokePoints.clear();
      _activeStrokeIndex = 0;
      _completed = false;
      _lastStrokeWasValid = null;
    });
    _loadTargetPoints();
  }

  /// Converts a screen-space offset to canonical 109×109 KanjiVG space.
  Offset _toCanonical(Offset screenPoint) {
    final scale = 109.0 / math.min(_canvasSize.width, _canvasSize.height);
    return screenPoint * scale;
  }

  // ── gesture callbacks ───────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_completed) return;
    widget.onDrawingStateChanged?.call(true);
    setState(() {
      _currentStrokePoints = [d.localPosition];
      _lastStrokeWasValid = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_completed) return;
    setState(() => _currentStrokePoints.add(d.localPosition));
  }

  void _onPanDown(DragDownDetails d) {
    if (_completed) return;
    widget.onDrawingStateChanged?.call(true);
  }

  void _onPanCancel() {
    widget.onDrawingStateChanged?.call(false);
  }

  void _onPanEnd(DragEndDetails _) {
    widget.onDrawingStateChanged?.call(false);
    if (_completed) return;
    if (_currentStrokePoints.length < 5) {
      // too short — ignore
      setState(() => _currentStrokePoints.clear());
      return;
    }

    // Convert user stroke to canonical space
    final canonicalPoints = _currentStrokePoints.map(_toCanonical).toList();

    // Validate against target
    final result = PathValidator.validateCompletedStroke(
      userPoints: canonicalPoints,
      targetPoints: _targetPoints ?? [],
    );

    if (result.isValid) {
      // ── Accept stroke ───────────────────────────────────────
      setState(() {
        _completedUserStrokes.add(List.from(_currentStrokePoints));
        _currentStrokePoints.clear();
        _lastStrokeWasValid = true;
        _activeStrokeIndex++;
        if (_activeStrokeIndex >= _totalStrokeCount()) {
          _completed = true;
        } else {
          _loadTargetPoints();
        }
      });
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } else {
      // ── Reject stroke ───────────────────────────────────────
      setState(() {
        _lastStrokeWasValid = false;
        _currentStrokePoints.clear();
      });
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
    }
  }

  // ── build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paths =
        widget.strokePaths ??
        StrokePathRepository().getStrokeData(widget.character.trim())?.paths;
    final totalStrokeCount = paths?.length ?? widget.strokeCount;

    // Header colour / message
    final Color headerBg;
    final Color headerFg;
    final String headerText;
    if (_completed) {
      headerBg = Colors.green.withValues(alpha: 0.12);
      headerFg = Colors.green.shade700;
      headerText = '🎉 Perfect! All strokes complete!';
    } else if (_lastStrokeWasValid == false) {
      headerBg = Colors.red.withValues(alpha: 0.10);
      headerFg = Colors.red.shade700;
      headerText = 'Try again — watch the arrow for direction!';
    } else {
      headerBg = scheme.primary.withValues(alpha: 0.08);
      headerFg = scheme.primary;
      headerText = 'Draw Stroke ${_activeStrokeIndex + 1} of $totalStrokeCount';
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _lastStrokeWasValid == false ? _shakeAnimation.value : 0,
            0,
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // ── Header bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  _completed
                      ? Icons.workspace_premium_rounded
                      : Icons.brush_rounded,
                  size: 16,
                  color: headerFg,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: headerFg,
                    ),
                  ),
                ),
                if (_completed)
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Redo'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // ── Drawing canvas ────────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanDown: _onPanDown,
            onPanCancel: _onPanCancel,
            // Absorbs vertical drag to prevent ListView scroll on Android
            // Map to pan handlers so strokes are still recorded during vertical moves
            onVerticalDragStart: _onPanStart,
            onVerticalDragUpdate: _onPanUpdate,
            onVerticalDragEnd: _onPanEnd,
            onVerticalDragCancel: _onPanCancel,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.maxWidth;
                _canvasSize = Size(side, side);
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: scheme.outlineVariant,
                          width: 1.5,
                        ),
                        right: BorderSide(
                          color: scheme.outlineVariant,
                          width: 1.5,
                        ),
                        bottom: BorderSide(
                          color: scheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Layer 1: Ghost of entire character (very faint)
                          if (paths != null && !_completed)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: CustomPaint(
                                  painter: StrokeOrderPainter(
                                    paths: paths,
                                    showUpTo: 0,
                                    brushColor: scheme.onSurface.withValues(
                                      alpha: 0.08,
                                    ),
                                    strokeWidth: 8,
                                    showArrow: false,
                                  ),
                                ),
                              ),
                            ),

                          // Layer 2: Completed SVG strokes in green
                          if (paths != null &&
                              _activeStrokeIndex > 0 &&
                              !_completed)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: CustomPaint(
                                  painter: StrokeOrderPainter(
                                    paths: paths,
                                    showUpTo: _activeStrokeIndex,
                                    brushColor: Colors.green.shade600,
                                    strokeWidth: 7,
                                    showArrow: false,
                                  ),
                                ),
                              ),
                            ),

                          // Layer 3: Active stroke ghost guide with arrow
                          if (paths != null &&
                              !_completed &&
                              _activeStrokeIndex < paths.length)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: CustomPaint(
                                  painter: StrokeOrderPainter(
                                    paths: [paths[_activeStrokeIndex]],
                                    showUpTo: 1,
                                    brushColor: scheme.primary.withValues(
                                      alpha: 0.30,
                                    ),
                                    strokeWidth: 9,
                                    showArrow: true,
                                  ),
                                ),
                              ),
                            ),

                          // Layer 4: User's finger strokes
                          CustomPaint(
                            painter: _UserStrokePainter(
                              completedStrokes: _completedUserStrokes,
                              activeStroke: _currentStrokePoints,
                              completedColor: Colors.green.withValues(
                                alpha: 0.7,
                              ),
                              activeColor: scheme.primary,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Reset button ─────────────────────────────────────
          if (!_completed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// User Stroke Painter
// ──────────────────────────────────────────────────────────────────────────────

class _UserStrokePainter extends CustomPainter {
  const _UserStrokePainter({
    required this.completedStrokes,
    required this.activeStroke,
    required this.completedColor,
    required this.activeColor,
  });

  final List<List<Offset>> completedStrokes;
  final List<Offset> activeStroke;
  final Color completedColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Previously validated strokes
    paint.color = completedColor;
    for (final stroke in completedStrokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Current in-progress stroke
    if (activeStroke.length >= 2) {
      paint.color = activeColor;
      final path = Path()..moveTo(activeStroke.first.dx, activeStroke.first.dy);
      for (int i = 1; i < activeStroke.length; i++) {
        path.lineTo(activeStroke[i].dx, activeStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UserStrokePainter old) => true;
}
