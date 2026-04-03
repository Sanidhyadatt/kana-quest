import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/vocabulary_repository.dart';
import '../domain/vocabulary_word.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final _repo = const VocabularyRepository();
  final _searchController = TextEditingController();
  final _tts = FlutterTts();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tts.stop().catchError((_) {});
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      
      // Try to find a high-quality human-like voice if available
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final v in voices) {
          final voiceMap = v as Map;
          final name = voiceMap['name']?.toString().toLowerCase() ?? '';
          final locale = voiceMap['locale']?.toString().toLowerCase() ?? '';
          if (locale.contains('ja') && 
              (name.contains('network') || name.contains('jpf') || name.contains('jpi'))) {
            await _tts.setVoice(Map<String, String>.from(voiceMap));
            break; 
          }
        }
      }
      if (mounted) setState(() => _ttsReady = true);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    SystemSound.play(SystemSoundType.click);
    if (_ttsReady) {
      try {
        await _tts.stop();
        await _tts.setLanguage('ja-JP');
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        await _tts.speak(text);
        return;
      } catch (_) {}
    }
    if (!kIsWeb && Platform.isLinux) {
      try {
        // -r 0 for normal speed, -p 0 for normal pitch
        await Process.run('spd-say', ['-l', 'ja', '-r', '-10', text]);
      } catch (_) {}
    }
  }

  List<VocabularyWord> get _filteredWords {
    var words = _repo.searchWords(_searchQuery);
    if (_selectedCategory != 'All') {
      words = words.where((w) => w.category == _selectedCategory).toList();
    }
    return words;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = _repo.getCategories();
    final words = _filteredWords;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.primaryContainer.withValues(alpha: 0.15),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.menu_book_rounded,
                              color: scheme.onPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '単語帳',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                            Text(
                              'Vocabulary',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${words.length} words',
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Search Bar ─────────────────────────────────
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Search words, meanings, romaji...',
                      leading: Icon(Icons.search_rounded,
                          color: scheme.onSurfaceVariant),
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Category Chips ─────────────────────────────
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final selected = cat == _selectedCategory;
                          return FilterChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // ── Word List ───────────────────────────────────────
              Expanded(
                child: words.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No words found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: words.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _WordCard(word: words[i], onSpeak: _speak),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.onSpeak});
  final VocabularyWord word;
  final Future<void> Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Category color
    final catColors = <String, Color>{
      'Greetings': Colors.teal,
      'Numbers': Colors.indigo,
      'Time': Colors.orange,
      'Food': Colors.red,
      'Nature': Colors.green,
      'People': Colors.purple,
      'Verbs': Colors.blue,
      'Adjectives': Colors.pink,
      'Places': Colors.amber,
    };
    final catColor = catColors[word.category] ?? scheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: catColor.withValues(alpha: 0.2),
        ),
      ),
      color: scheme.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSpeak(word.furigana),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Japanese + furigana
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.japanese,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                height: 1.0,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      word.furigana,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      word.romaji,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 50,
                color: scheme.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              // English meaning
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.english,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        word.category,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              // Audio button
              IconButton(
                icon: Icon(Icons.volume_up_rounded,
                    color: catColor.withValues(alpha: 0.8)),
                onPressed: () => onSpeak(word.furigana),
                tooltip: 'Play audio',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
