import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _step = 0;
  int _dailyGoal = 10;
  String _startingPath = 'Hiragana Explorer';
  bool _isSaving = false;

  static const _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell us your name to begin.')),
      );
      return;
    }

    if (_step < _totalSteps - 1) {
      setState(() {
        _step += 1;
      });
      await _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _completeOnboarding();
  }

  Future<void> _previousStep() async {
    if (_step == 0) {
      return;
    }

    setState(() {
      _step -= 1;
    });
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefsKeys.userName, _nameController.text.trim());
    await prefs.setInt(AppPrefsKeys.dailyGoal, _dailyGoal);
    await prefs.setString(AppPrefsKeys.startingPath, _startingPath);
    await prefs.setBool(AppPrefsKeys.onboardingComplete, true);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            SenseiIntroScreen(userName: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Hero(
                      tag: 'sensei-mascot',
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.primaryContainer,
                        child: const Text('🦊', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Zero-to-Hero Setup',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_step + 1}/$_totalSteps',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    minHeight: 8,
                    backgroundColor: scheme.primaryFixed,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepCard(
                      title: 'What should Sensei call you?',
                      subtitle:
                          'Your name personalizes guidance and progress messages.',
                      child: TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                    ),
                    _StepCard(
                      title: 'Set your daily goal',
                      subtitle: 'Choose a realistic number of reviews per day.',
                      child: Column(
                        children: [
                          Slider(
                            value: _dailyGoal.toDouble(),
                            min: 5,
                            max: 40,
                            divisions: 7,
                            label: '$_dailyGoal cards/day',
                            onChanged: (value) {
                              setState(() {
                                _dailyGoal = value.round();
                              });
                            },
                          ),
                          Text(
                            '$_dailyGoal cards/day',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    _StepCard(
                      title: 'Pick your starting path',
                      subtitle:
                          'You can change this later in profile settings.',
                      child: Column(
                        children: [
                          _PathOption(
                            title: 'Hiragana Explorer',
                            description: 'Start with the core 46 Hiragana.',
                            isSelected: _startingPath == 'Hiragana Explorer',
                            onTap: () {
                              setState(() {
                                _startingPath = 'Hiragana Explorer';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _PathOption(
                            title: 'Balanced Journey',
                            description:
                                'Mix Hiragana and basic katakana early.',
                            isSelected: _startingPath == 'Balanced Journey',
                            onTap: () {
                              setState(() {
                                _startingPath = 'Balanced Journey';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _PathOption(
                            title: 'Speed Runner',
                            description: 'Fast pace with more daily reviews.',
                            isSelected: _startingPath == 'Speed Runner',
                            onTap: () {
                              setState(() {
                                _startingPath = 'Speed Runner';
                                _dailyGoal = _dailyGoal < 20 ? 20 : _dailyGoal;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _step == 0 || _isSaving
                            ? null
                            : _previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _nextStep,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _step == _totalSteps - 1
                                    ? 'Meet Sensei'
                                    : 'Next',
                              ),
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: scheme.secondary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathOption extends StatelessWidget {
  const _PathOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.64)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SenseiIntroScreen extends StatelessWidget {
  const SenseiIntroScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerLow,
              scheme.primaryContainer.withValues(alpha: 0.34),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
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
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'sensei-mascot',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: scheme.primaryContainer,
                          child: const Text(
                            '🦊',
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sensei says hello, $userName!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your first five Hiragana companions are ready:',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: const [
                          _KanaBadge(character: 'あ', romaji: 'A'),
                          _KanaBadge(character: 'い', romaji: 'I'),
                          _KanaBadge(character: 'う', romaji: 'U'),
                          _KanaBadge(character: 'え', romaji: 'E'),
                          _KanaBadge(character: 'お', romaji: 'O'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tap each card in Review Arena, flip for mnemonics, and rate your recall to train the SRS engine.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (_) => false,
                            );
                          },
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('Begin Your Journey'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanaBadge extends StatelessWidget {
  const _KanaBadge({required this.character, required this.romaji});

  final String character;
  final String romaji;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              character,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              romaji,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
