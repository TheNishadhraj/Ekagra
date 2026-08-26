import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/dopamine_menu_model.dart';
import '../../providers/reward_provider.dart';
import '../../services/analytics_service.dart';

/// Step 2 of 3 — one tap by default.
///
/// Research: most productivity apps lose ADHD users during onboarding, and
/// a reward menu the user has not felt yet is a setup question with no
/// stake. So the menu is pre-filled from `DopamineMenu.defaults` (the same
/// treats the app ships with), the primary button just continues, and
/// tuning is an optional disclosure. "Tune it later" also lives in
/// Settings — same screen, reachable any time.
class DopamineMenuSetupScreen extends StatefulWidget {
  const DopamineMenuSetupScreen({super.key});

  @override
  State<DopamineMenuSetupScreen> createState() =>
      _DopamineMenuSetupScreenState();
}

class _DopamineMenuSetupScreenState extends State<DopamineMenuSetupScreen> {
  bool _customizing = false;

  final Map<RewardTier, Set<String>> _selected = {
    RewardTier.quick: {
      '🎵 Listen to 1 hype song',
      '🍫 Eat a snack',
      '💃 60-second dance break',
    },
    RewardTier.medium: {
      '🚶 Take a short walk',
      '☕ Make a fancy coffee',
      '🐕 Pet/play with your pet',
    },
    RewardTier.big: {'📺 Watch an episode of your show', '🎮 Gaming session'},
  };

  void _toggle(RewardTier tier, String text) {
    setState(() {
      final set = _selected[tier]!;
      if (set.contains(text)) {
        if (set.length > 1) set.remove(text);
      } else {
        set.add(text);
      }
    });
  }

  void _addCustom(RewardTier tier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Reward'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 10 min window shopping',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _selected[tier]!.add(controller.text.trim());
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    if (_customizing) {
      await context.read<RewardProvider>().saveCustomMenu(
        quick: _selected[RewardTier.quick]!.toList(),
        medium: _selected[RewardTier.medium]!.toList(),
        big: _selected[RewardTier.big]!.toList(),
      );
      track(Ev.onboardingStepCompleted, {
        'step': 'dopamine_menu',
        'customized': true,
      });
    } else {
      track(Ev.onboardingStepCompleted, {
        'step': 'dopamine_menu',
        'customized': false,
      });
    }
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.notificationPermission);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(title: const Text('Step 2 of 3'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: EkagraSpacing.lg),
                    Text(
                      'Your rewards are ready 🍫',
                      style: EkagraTypography.h2,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: EkagraSpacing.xs),
                    Text(
                      'We pre-filled a menu of small treats. After you finish '
                      'things, Ekagra surprises you with one. Continue now — '
                      'tune it any time in Settings.',
                      style: EkagraTypography.caption,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    if (!_customizing) ...[
                      const SizedBox(height: EkagraSpacing.xl),
                      _defaultPreview(),
                    ] else ...[
                      const SizedBox(height: EkagraSpacing.lg),
                      _buildCategorySection(
                        'Quick Hits (2 min)',
                        RewardTier.quick,
                        DopamineMenuDefaults.pool['quick']!,
                      ),
                      const SizedBox(height: EkagraSpacing.lg),
                      _buildCategorySection(
                        'Medium Rewards (15 min)',
                        RewardTier.medium,
                        DopamineMenuDefaults.pool['medium']!,
                      ),
                      const SizedBox(height: EkagraSpacing.lg),
                      _buildCategorySection(
                        'Big Rewards (30+ min)',
                        RewardTier.big,
                        DopamineMenuDefaults.pool['big']!,
                      ),
                    ],
                    const SizedBox(height: EkagraSpacing.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EkagraSpacing.lg),
              child: Column(
                children: [
                  if (!_customizing)
                    TextButton(
                      onPressed: () => setState(() => _customizing = true),
                      child: Text(
                        'Tune my menu first →',
                        style: EkagraTypography.bodyBold.copyWith(
                          color: EkagraColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: EkagraSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: Text(
                        _customizing ? 'Save & Continue →' : 'Continue →',
                      ),
                    ),
                  ),
                  const SizedBox(height: EkagraSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_dot(true), _dot(true), _dot(false)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultPreview() {
    final defaults = DopamineMenu.defaults;
    final picks = [
      defaults.quick.first,
      defaults.medium.first,
      defaults.big.first,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EkagraSpacing.lg),
      decoration: BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: picks
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: EkagraSpacing.md),
                    Expanded(child: Text('${item.text} · ${item.durationMinutes} min')),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildCategorySection(
    String title,
    RewardTier tier,
    List<DopamineItem> options,
  ) {
    final selectedSet = _selected[tier]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: EkagraTypography.bodyBold.copyWith(color: EkagraColors.primary),
        ),
        const SizedBox(height: EkagraSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: EkagraColors.surface,
            borderRadius: BorderRadius.circular(EkagraRadius.lg),
            border: Border.all(
              color: EkagraColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              ...options.map((item) {
                final text = '${item.emoji} ${item.text}';
                final isSel = selectedSet.contains(text) ||
                    selectedSet.contains(item.text);
                return CheckboxListTile(
                  title: Text(
                    '${item.emoji} ${item.text}',
                    style: EkagraTypography.body.copyWith(fontSize: 15),
                  ),
                  value: isSel,
                  activeColor: EkagraColors.primary,
                  onChanged: (_) => _toggle(tier, text),
                  dense: true,
                );
              }),
              ...selectedSet
                  .where(
                    (s) => !options.any(
                      (o) => '${o.emoji} ${o.text}' == s || o.text == s,
                    ),
                  )
                  .map((customText) {
                return CheckboxListTile(
                  title: Text(
                    '✨ $customText',
                    style: EkagraTypography.body.copyWith(fontSize: 15),
                  ),
                  value: true,
                  activeColor: EkagraColors.primary,
                  onChanged: (_) => _toggle(tier, customText),
                  dense: true,
                );
              }),
              ListTile(
                title: Text(
                  '✨ + Add your own',
                  style: EkagraTypography.bodyBold.copyWith(
                    color: EkagraColors.primary,
                    fontSize: 14,
                  ),
                ),
                onTap: () => _addCustom(tier),
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? EkagraColors.primary
            : EkagraColors.primaryLight.withValues(alpha: 0.4),
      ),
    );
  }
}
