import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/settings_provider.dart';

class AdhdTypeScreen extends StatefulWidget {
  const AdhdTypeScreen({super.key});

  @override
  State<AdhdTypeScreen> createState() => _AdhdTypeScreenState();
}

class _AdhdTypeScreenState extends State<AdhdTypeScreen> {
  final Set<AdhdTrait> _selected = {AdhdTrait.taskParalysis};

  final _options = const [
    _TraitOption(
      trait: AdhdTrait.taskParalysis,
      emoji: '🧊',
      quote: '"I freeze and can\'t start anything"',
      label: 'Task Paralysis',
    ),
    _TraitOption(
      trait: AdhdTrait.timeBlindness,
      emoji: '⏰',
      quote: '"Time just... vanishes"',
      label: 'Time Blindness',
    ),
    _TraitOption(
      trait: AdhdTrait.taskSwitching,
      emoji: '🦋',
      quote: '"I start 10 things and finish none"',
      label: 'Task Switching',
    ),
    _TraitOption(
      trait: AdhdTrait.energyFluctuation,
      emoji: '🎢',
      quote: '"My energy is a rollercoaster"',
      label: 'Energy Fluctuation',
    ),
  ];

  void _toggle(AdhdTrait trait) {
    setState(() {
      if (_selected.contains(trait)) {
        if (_selected.length > 1) _selected.remove(trait);
      } else {
        _selected.add(trait);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selected.addAll(AdhdTrait.values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Step 1 of 3'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What does ADHD look like for you?',
                      style: EkagraTypography.h2,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: EkagraSpacing.xs),
                    Text(
                      'This helps us personalize Ekagra. Change anytime in Settings.',
                      style: EkagraTypography.caption,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: EkagraSpacing.xl),

                    ...List.generate(_options.length, (index) {
                      final item = _options[index];
                      final isSel = _selected.contains(item.trait);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: EkagraSpacing.md),
                        child: InkWell(
                          onTap: () => _toggle(item.trait),
                          borderRadius: BorderRadius.circular(EkagraRadius.lg),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(EkagraSpacing.lg),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? EkagraColors.primary.withValues(alpha: 0.08)
                                  : EkagraColors.surface,
                              borderRadius: BorderRadius.circular(EkagraRadius.lg),
                              border: Border.all(
                                color: isSel
                                    ? EkagraColors.primary
                                    : EkagraColors.primaryLight.withValues(alpha: 0.3),
                                width: isSel ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(item.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: EkagraSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.quote,
                                        style: EkagraTypography.bodyBold.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label,
                                        style: EkagraTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSel ? 1 : 0,
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: EkagraColors.primary,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 150 + index * 80),
                            duration: 400.ms,
                          )
                          .slideX(begin: 0.1, end: 0);
                    }),

                    // All of above option
                    InkWell(
                      onTap: _selectAll,
                      borderRadius: BorderRadius.circular(EkagraRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(EkagraSpacing.lg),
                        decoration: BoxDecoration(
                          color: _selected.length == AdhdTrait.values.length
                              ? EkagraColors.primary.withValues(alpha: 0.08)
                              : EkagraColors.surface,
                          borderRadius: BorderRadius.circular(EkagraRadius.lg),
                          border: Border.all(
                            color: _selected.length == AdhdTrait.values.length
                                ? EkagraColors.primary
                                : EkagraColors.primaryLight.withValues(alpha: 0.3),
                            width: _selected.length == AdhdTrait.values.length ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🌈', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: EkagraSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '"A bit of everything"',
                                    style: EkagraTypography.bodyBold,
                                  ),
                                  Text(
                                    'All of the above',
                                    style: EkagraTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(EkagraSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        settings.setAdhdTraits(_selected.toList());
                        Navigator.pushNamed(context, AppRoutes.dopamineSetup);
                      },
                      child: const Text('Continue →'),
                    ),
                  ),
                  const SizedBox(height: EkagraSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_dot(true), _dot(false), _dot(false)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? EkagraColors.primary : EkagraColors.primaryLight.withValues(alpha: 0.4),
      ),
    );
  }
}

class _TraitOption {
  final AdhdTrait trait;
  final String emoji;
  final String quote;
  final String label;

  const _TraitOption({
    required this.trait,
    required this.emoji,
    required this.quote,
    required this.label,
  });
}
