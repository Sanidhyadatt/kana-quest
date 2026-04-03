import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app.dart';
import '../../review/presentation/review_arena_screen.dart';
import '../domain/world_map_progress.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(worldMapProgressProvider);

    return Scaffold(
      body: DecoratedBox(
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
            error: (error, stackTrace) =>
                _ErrorState(message: error.toString()),
            data: (progress) {
              return Stack(
                children: [
                  const _WorldBackdrop(),
                  Positioned.fill(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 152, 20, 48),
                      physics: const BouncingScrollPhysics(),
                      itemCount: progress.shrines.length,
                      itemBuilder: (context, index) {
                        final shrine = progress.shrines[index];
                        return Shrine(
                          progress: shrine,
                          isLeftAligned: index.isEven,
                          onTap: shrine.isLocked
                              ? null
                              : () async {
                                  if (shrine.row.row == 0) {
                                    await Navigator.of(context).pushNamed(
                                      AppRoutes.baseCamp,
                                    );
                                    ref.invalidate(worldMapProgressProvider);
                                    return;
                                  }

                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => ReviewArenaScreen(
                                        initialRow: shrine.row.row,
                                      ),
                                    ),
                                  );
                                  ref.invalidate(worldMapProgressProvider);
                                },
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
                        if (progress.shrines.isEmpty) {
                          return;
                        }

                        final firstOpenShrine = progress.shrines.firstWhere(
                          (shrine) => !shrine.isLocked,
                          orElse: () => progress.shrines.first,
                        );

                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ReviewArenaScreen(
                              initialRow: firstOpenShrine.row.row,
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
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
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
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: scheme.secondary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mountain of Mastery Map',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            progress.rank.label,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${progress.dueCount} cards due today · ${progress.masteredCount} learned',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StreakChip(days: progress.streakDays),
                  ],
                ),
                const SizedBox(height: 14),
                _XpBar(progress: progress.rank),
                const SizedBox(height: 14),
                _QuestPanel(progress: progress),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartReview,
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: Text(
                      progress.dueCount == 0
                          ? 'Continue Training'
                          : 'Enter Review Arena',
                    ),
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

class _QuestPanel extends StatelessWidget {
  const _QuestPanel({required this.progress});

  final WorldMapProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeShrine = progress.shrines.firstWhere(
      (shrine) => !shrine.isLocked,
      orElse: () => progress.shrines.first,
    );
    final progressFraction = activeShrine.totalCount == 0
        ? 0.0
        : activeShrine.masteryFraction;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily Quest',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${(progressFraction * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              activeShrine.isMastered
                  ? 'Section ${activeShrine.row.label} is cleared. Start the next row to keep the chain going.'
                  : 'Finish ${activeShrine.row.label} row to unlock the next section.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 10,
                backgroundColor: scheme.onSecondaryContainer.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: scheme.onPrimaryContainer,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '$days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});

  final RankProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${progress.currentXp} XP',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              progress.nextThreshold == progress.currentThreshold
                  ? 'Max rank'
                  : '${progress.remainingXp} to next',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const segmentCount = 10;
            final activeSegments = (progress.fraction * segmentCount).round();

            return Row(
              children: List.generate(segmentCount, (index) {
                final isActive = index < activeSegments;
                final segmentWidth =
                    (constraints.maxWidth - (segmentCount - 1) * 6) /
                    segmentCount;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == segmentCount - 1 ? 0 : 6,
                  ),
                  child: SizedBox(
                    width: segmentWidth,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isActive ? scheme.primary : scheme.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class Shrine extends StatelessWidget {
  const Shrine({
    super.key,
    required this.progress,
    required this.isLeftAligned,
    this.onTap,
  });

  final ShrineProgress progress;
  final bool isLeftAligned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = progress.isLocked
        ? scheme.surfaceContainerHigh
        : progress.isMastered
        ? scheme.primaryContainer.withValues(alpha: 0.66)
        : scheme.surfaceContainerLow;
    final textColor = progress.isLocked
        ? scheme.onSurfaceVariant
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: isLeftAligned
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: _ShrineCard(
                    progress: progress,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _PathNode(progress: progress),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
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
    final lineColor = progress.isLocked
        ? scheme.outlineVariant.withValues(alpha: 0.65)
        : scheme.primary.withValues(alpha: 0.38);
    final nodeColor = progress.isLocked
        ? scheme.surfaceContainerHighest
        : progress.isMastered
        ? scheme.tertiary
        : scheme.primary;

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
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
                ? Icon(
                    Icons.lock_rounded,
                    size: 10,
                    color: scheme.onSurfaceVariant,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShrineCard extends StatelessWidget {
  const _ShrineCard({
    required this.progress,
    required this.cardColor,
    required this.textColor,
  });

  final ShrineProgress progress;
  final Color cardColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.secondary.withValues(
                alpha: progress.isLocked ? 0.05 : 0.10,
              ),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${progress.row.label} Row',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    progress.isLocked
                        ? Icons.lock_rounded
                        : progress.isMastered
                        ? Icons.verified_rounded
                        : Icons.park_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                progress.row.kana,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                progress.row.focus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: progress.isLocked ? 'Locked' : 'Open',
                    background: progress.isLocked
                        ? scheme.surfaceContainerHighest
                        : scheme.primaryFixed,
                    foreground: progress.isLocked
                        ? scheme.onSurfaceVariant
                        : scheme.onPrimaryFixed,
                  ),
                  _Pill(
                    label: progress.totalCount == 0
                        ? 'No cards yet'
                        : '${(progress.masteryFraction * 100).round()}% learned',
                    background: scheme.surfaceContainerHighest,
                    foreground: scheme.onSurface,
                  ),
                  _Pill(
                    label: '${progress.dueCount} due',
                    background: scheme.tertiaryContainer,
                    foreground: scheme.onTertiaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
