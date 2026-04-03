import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import '../../review/presentation/review_arena_screen.dart';

class BaseCampScreen extends ConsumerWidget {
  const BaseCampScreen({super.key, this.scriptType = 0});
  final int scriptType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the global script provider for consistency
    final activeScriptType = ref.watch(selectedScriptProvider);
    final scriptName = activeScriptType == 0 ? 'Hiragana' : activeScriptType == 1 ? 'Katakana' : 'Kanji';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Base Camp')),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.primaryContainer.withValues(alpha: 0.25),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base Camp is your starting point.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This is the first open path in Kana Quest. Use it to begin your $scriptName journey, review cards, and build momentum.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ReviewArenaScreen(
                          initialRow: 0,
                          scriptType: activeScriptType,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Start Base Camp'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back to Map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}