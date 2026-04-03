import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_mode_controller.dart';
import '../../quiz/domain/quiz_history.dart';
import '../domain/dojo_stats.dart';
import 'dojo_providers.dart';
import '../../quiz/presentation/quiz_history_providers.dart';
import '../../quiz/presentation/quiz_review_view.dart';

class DojoScreen extends ConsumerWidget {
  const DojoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dojoStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.surface, scheme.surfaceContainerLow, scheme.surface],
        ),
      ),
      child: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load Dojo stats: $e')),
          data: (stats) => _DojoBody(stats: stats),
        ),
      ),
    );
  }
}

class _DojoBody extends StatelessWidget {
  const _DojoBody({required this.stats});
  final DojoStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _DojoHeader(stats: stats),
        const SizedBox(height: 18),
        _StreakSection(stats: stats),
        const SizedBox(height: 18),
        _ProgressOverviewSection(stats: stats),
        const SizedBox(height: 18),
        _QuizProgressSection(stats: stats),
        const SizedBox(height: 18),
        const _QuizHistorySection(),
        const SizedBox(height: 18),
        const _AppearanceSection(),
      ],
    );
  }
}

class _DojoHeader extends ConsumerWidget {
  const _DojoHeader({required this.stats});
  final DojoStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: const Text('🦊', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Dojo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Okaeri, ${stats.userName}!',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            SystemSound.play(SystemSoundType.click);
                            _showEditNameDialog(context, ref);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _LevelBadge(level: stats.level, xp: stats.xp),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'True wisdom is not just in learning, but in the steady rhythm of the practice.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: stats.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Your Name'),
          autofocus: true,
          maxLength: 15,
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              SystemSound.play(SystemSoundType.click);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                HapticFeedback.mediumImpact();
                SystemSound.play(SystemSoundType.click);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', name);
                ref.invalidate(dojoStatsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.xp});
  final int level;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LVL $level',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '$xp XP',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.stats});
  final DojoStats stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.local_fire_department_rounded,
            label: 'Study Activity',
          ),
          const SizedBox(height: 16),
          _CalendarHeatmap(reviewDates: stats.reviewDates),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFFF6B35),
                  value: '${stats.currentStreak}',
                  label: 'Day Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  value: '${stats.totalCardsReviewed}',
                  label: 'Reviews',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  const _CalendarHeatmap({required this.reviewDates});
  final Set<String> reviewDates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    const columns = 16;

    final start = now.subtract(const Duration(days: columns * 7 - 1));
    final alignedStart = start.subtract(Duration(days: start.weekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 7 * 14.0,
          child: Row(
            children: List.generate(columns, (w) {
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Column(
                  children: List.generate(7, (d) {
                    final date = alignedStart.add(Duration(days: w * 7 + d));
                    final key =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final hasReview = reviewDates.contains(key);
                    final isFuture = date.isAfter(now);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? scheme.surfaceContainerLow
                              : hasReview
                              ? scheme.primary
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverviewSection extends StatelessWidget {
  const _ProgressOverviewSection({required this.stats});
  final DojoStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.bar_chart_rounded, label: 'Knowledge Map'),
          const SizedBox(height: 20),
          _ProgressBar(
            label: 'Hiragana',
            mastered: stats.hiraganaMastered,
            learning: stats.hiraganaLearning,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          _ProgressBar(
            label: 'Katakana',
            mastered: stats.katakanaMastered,
            learning: stats.katakanaLearning,
            color: scheme.secondary,
          ),
          const SizedBox(height: 16),
          _ProgressBar(
            label: 'Kanji (N5)',
            mastered: stats.kanjiMastered,
            learning: stats.kanjiLearning,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: scheme.primary,
                  value: '${stats.totalMastered}',
                  label: 'Total Completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.school_rounded,
                  iconColor: scheme.secondary,
                  value: '${stats.totalLearning}',
                  label: 'In Progress',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.mastered,
    required this.learning,
    required this.color,
  });

  final String label;
  final int mastered;
  final int learning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = (mastered + learning).clamp(1, 1000);
    final masteredPct = (mastered / total).clamp(0.0, 1.0);
    final learningPct = (learning / total).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$mastered completed · $learning in progress',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(color: scheme.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: learningPct,
                  child: Container(color: color.withValues(alpha: 0.3)),
                ),
                FractionallySizedBox(
                  widthFactor: masteredPct,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizProgressSection extends StatelessWidget {
  const _QuizProgressSection({required this.stats});
  final DojoStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accuracyPercent = (stats.quizAccuracy * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.quiz_rounded, label: 'Quiz Progress'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: scheme.primary,
                  value: '${stats.quizAttempts}',
                  label: 'Quizzes Attempted',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  value: '${stats.quizCorrectAnswers}',
                  label: 'Correct Answers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.help_rounded,
                  iconColor: scheme.secondary,
                  value: '${stats.quizQuestionsAnswered}',
                  label: 'Questions Seen',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.insights_rounded,
                  iconColor: scheme.tertiary,
                  value: '$accuracyPercent%',
                  label: 'Accuracy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizHistorySection extends ConsumerWidget {
  const _QuizHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(quizHistoryProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.history_rounded,
            label: 'Quiz History',
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Could not load quiz history: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Text(
                  'No quizzes completed yet. Finish a quiz and your score history will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              }

              final visibleSessions = sessions.take(5).toList(growable: false);

              return Column(
                children: [
                  ...visibleSessions.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == visibleSessions.length - 1
                            ? 0
                            : 12,
                      ),
                      child: QuizSessionSummaryCard(
                        session: entry.value,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          SystemSound.play(SystemSoundType.click);
                          _showQuizSessionDetails(context, entry.value);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQuizSessionDetails(
    BuildContext context,
    QuizSessionRecord session,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Quiz review',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: QuizSessionReviewView(session: session),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.palette_rounded, label: 'Appearance'),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              HapticFeedback.selectionClick();
              SystemSound.play(SystemSoundType.click);
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
