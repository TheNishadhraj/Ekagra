import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/dopamine_menu_model.dart';
import '../../providers/reward_provider.dart';

class DopamineMenuSetupScreen extends StatefulWidget {
  const DopamineMenuSetupScreen({super.key});

  @override
  State<DopamineMenuSetupScreen> createState() => _DopamineMenuSetupScreenState();
}

class _DopamineMenuSetupScreenState extends State<DopamineMenuSetupScreen> {
  final Map<RewardTier, Set<String>> _selected = {
    RewardTier.quick: {'🎵 Listen to 1 hype song', '🍫 Eat a snack', '💃 60-sec dance break'},
    RewardTier.medium: {'🚶 Take a short walk', '☕ Make a fancy coffee', '🐕 Pet the dog/cat'},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('3 of 4'),
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
                      'Set up your Dopamine Menu 🍫',
                      style: EkagraTypography.h2,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: EkagraSpacing.xs),
                    Text(
                      'Your rewards. We pick a surprise after you complete tasks.',
                      style: EkagraTypography.caption,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
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
                    const SizedBox(height: EkagraSpacing.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EkagraSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rewardsProvider = context.read<RewardProvider>();
                        // Save menu
                        await rewardsProvider.saveCustomMenu(
                          quick: _selected[RewardTier.quick]!.toList(),
                          medium: _selected[RewardTier.medium]!.toList(),
                          big: _selected[RewardTier.big]!.toList(),
                        );
                        if (context.mounted) {
                          Navigator.pushNamed(context, AppRoutes.notificationPermission);
                        }
                      },
                      child: const Text('Continue →'),
                    ),
                  ),
                  const SizedBox(height: EkagraSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(true),
                      _dot(true),
                      _dot(true),
                      _dot(false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          style: EkagraTypography.bodyBold.copyWith(
            color: EkagraColors.primary,
          ),
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
                final isSel = selectedSet.contains(text) || selectedSet.contains(item.text);
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

              // Custom added items
              ...selectedSet
                  .where((s) => !options.any((o) => '${o.emoji} ${o.text}' == s || o.text == s))
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
        color: active ? EkagraColors.primary : EkagraColors.primaryLight.withValues(alpha: 0.4),
      ),
    );
  }
}
