import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/sensei_fox.dart';
import '../../base_camp/presentation/base_camp_screen.dart';
import '../../dojo/presentation/dojo_screen.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../../review/presentation/review_arena_screen.dart';
import '../../vocabulary/presentation/vocabulary_screen.dart';
import '../domain/world_map_progress.dart';
import 'home_providers.dart';

/// Root shell that owns the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map_rounded),
        label: 'Learn',
      ),
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Vocabulary',
      ),
      const NavigationDestination(
        icon: Icon(Icons.quiz_outlined),
        selectedIcon: Icon(Icons.quiz_rounded),
        label: 'Quiz',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _LearnTab(),
          VocabularyScreen(),
          QuizScreen(),
          DojoScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: destinations,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 2,
      ),
    );
  }
}

// ── Learn tab (the existing world map) ───────────────────────────────────────

class _LearnTab extends ConsumerWidget {
  const _LearnTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(worldMapProgressProvider);
    final scriptType = ref.watch(selectedScriptProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerLow,
            Theme.of(context).colorScheme.surface,
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
      child: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(message: error.toString()),
          data: (progress) {
            return Stack(
              children: [
                const _WorldBackdrop(),
                // Note: Zigzag path removed as requested
                Positioned.fill(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 180, 16, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: progress.shrines.length,
                    itemBuilder: (context, index) {
                      final shrine = progress.shrines[index];
                      return _AnimatedShrine(
                        index: index,
                        child: Shrine(
                          progress: shrine,
                          isLeftAligned: index.isEven,
                          scriptType: scriptType,
                          onTap: shrine.isLocked
                              ? null
                              : () async {
                                  if (shrine.row.row == 0) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) => BaseCampScreen(
                                          scriptType: scriptType,
                                        ),
                                      ),
                                    );
                                    ref.invalidate(worldMapProgressProvider);
                                    return;
                                  }
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => ReviewArenaScreen(
                                        initialRow: shrine.row.row,
                                        scriptType: scriptType,
                                      ),
                                    ),
                                  );
                                  ref.invalidate(worldMapProgressProvider);
                                },
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 10,
                  child: _FloatingHeader(
                    progress: progress,
                    onStartReview: () async {
                      if (progress.shrines.isEmpty) return;
                      final firstOpenShrine = progress.shrines.firstWhere(
                        (shrine) => !shrine.isLocked,
                        orElse: () => progress.shrines.first,
                      );
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ReviewArenaScreen(
                            initialRow: firstOpenShrine.row.row,
                            scriptType: scriptType,
                          ),
                        ),
                      );
                      ref.invalidate(worldMapProgressProvider);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class _AnimatedShrine extends StatefulWidget {
  const _AnimatedShrine({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedShrine> createState() => _AnimatedShrineState();
}

class _AnimatedShrineState extends State<_AnimatedShrine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: Curves.elasticOut,
  ));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _WorldBackdrop extends StatelessWidget {
  const _WorldBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -60,
            child: _GlowOrb(
              color: scheme.primaryContainer.withValues(alpha: 0.34),
              size: 220,
            ),
          ),
          Positioned(
            top: 200,
            left: -90,
            child: _GlowOrb(
              color: scheme.secondaryContainer.withValues(alpha: 0.24),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 160,
            right: -80,
            child: _GlowOrb(
              color: scheme.tertiaryContainer.withValues(alpha: 0.18),
              size: 240,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({required this.progress, required this.onStartReview});
  final WorldMapProgress progress;
  final VoidCallback onStartReview;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final scriptType = ref.watch(selectedScriptProvider);
        final scheme = Theme.of(context).colorScheme;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SenseiFox(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scriptType == 0
                              ? 'Hiragana'
                              : scriptType == 1
                                  ? 'Katakana'
                                  : 'Kanji',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Mountain of Mastery',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Review',
                    icon: const Icon(Icons.psychology_rounded),
                    onPressed: onStartReview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ScriptSwitcher(
              current: scriptType,
              onChanged: (v) =>
                  ref.read(selectedScriptProvider.notifier).state = v,
            ),
          ],
        );
      },
    );
  }
}

class _ScriptSwitcher extends StatelessWidget {
  const _ScriptSwitcher({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScriptItem(label: 'あ', active: current == 0, onTap: () => onChanged(0)),
          _ScriptItem(label: 'ア', active: current == 1, onTap: () => onChanged(1)),
          _ScriptItem(label: '山', active: current == 2, onTap: () => onChanged(2)),
        ],
      ),
    );
  }
}

class _ScriptItem extends StatelessWidget {
  const _ScriptItem({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class Shrine extends StatelessWidget {
  const Shrine({
    super.key,
    required this.progress,
    required this.isLeftAligned,
    required this.scriptType,
    this.onTap,
  });

  final ShrineProgress progress;
  final bool isLeftAligned;
  final int scriptType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Connector line (Removed as requested)

            // The main card and node row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                   if (isLeftAligned) ...[
                      Expanded(
                        flex: 5,
                        child: _ShrineCard(
                          progress: progress,
                          isLocked: progress.isLocked,
                        ),
                      ),
                      const Spacer(flex: 1),
                      _PathNode(progress: progress),
                      const Spacer(flex: 1),
                   ] else ...[
                      const Spacer(flex: 1),
                      _PathNode(progress: progress),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 5,
                        child: _ShrineCard(
                          progress: progress,
                          isLocked: progress.isLocked,
                        ),
                      ),
                   ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.progress});
  final ShrineProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nodeColor = progress.isLocked
        ? scheme.surfaceContainerHighest
        : progress.isMastered
            ? scheme.tertiary
            : scheme.primary;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nodeColor,
        boxShadow: [
          BoxShadow(
            color: nodeColor.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: progress.isLocked
          ? Icon(Icons.lock_rounded, size: 10, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}

class _ShrineCard extends StatelessWidget {
  const _ShrineCard({
    required this.progress,
    required this.isLocked,
  });

  final ShrineProgress progress;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mastered = progress.masteryFraction;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isLocked ? Colors.black : scheme.primary).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isLocked
                      ? scheme.surfaceContainerHigh
                      : progress.isMastered
                          ? scheme.primaryContainer.withValues(alpha: 0.7)
                          : scheme.surface.withValues(alpha: 0.85))
                  .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isLocked
                    ? scheme.outlineVariant.withValues(alpha: 0.5)
                    : scheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Opacity(
              opacity: isLocked ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.row.label} Row',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isLocked ? scheme.onSurfaceVariant : scheme.primary,
                            ),
                      ),
                      if (isLocked)
                        Icon(Icons.lock_rounded, size: 16, color: scheme.onSurfaceVariant)
                      else if (progress.isMastered)
                        Icon(Icons.stars_rounded, size: 20, color: scheme.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.row.kana,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          letterSpacing: 4,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  if (!isLocked) ...[
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: mastered,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.tertiary],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(mastered * 100).toInt()}% Mastered',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ] else
                    Text(
                      'Complete previous lessons to unlock',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
