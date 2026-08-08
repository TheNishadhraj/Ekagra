import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/dopamine_reward_model.dart';
import '../../providers/reward_provider.dart';

class RewardRevealScreen extends StatefulWidget {
  final DopamineReward? reward;

  const RewardRevealScreen({super.key, this.reward});

  @override
  State<RewardRevealScreen> createState() => _RewardRevealScreenState();
}

class _RewardRevealScreenState extends State<RewardRevealScreen> {
  int _stage = 1; // 1: Box idle, 2: Opening, 3: Revealed
  DopamineReward? _currentReward;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rewardProvider = context.read<RewardProvider>();
      setState(() {
        _currentReward = widget.reward ?? rewardProvider.generateRandomReward();
      });
    });
  }

  void _openBox() {
    if (_stage != 1) return;
    setState(() {
      _stage = 2;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _stage = 3;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reward = _currentReward;

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Dopamine Reward 🎁'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              if (_stage == 1) ...[
                // Stage 1: Mystery Box bouncing
                GestureDetector(
                  onTap: _openBox,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: EkagraColors.rewardQuick.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(EkagraRadius.xl),
                      border: Border.all(
                        color: EkagraColors.rewardQuick,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EkagraColors.rewardQuick.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎁', style: TextStyle(fontSize: 64)),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.08, 1.08),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(height: EkagraSpacing.xxl),
                Text('Tap to open your surprise! 🎁', style: EkagraTypography.h2),
                const SizedBox(height: EkagraSpacing.xs),
                Text(
                  'Variable ratio rewards keep ADHD brains motivated.',
                  style: EkagraTypography.caption,
                ),
              ] else if (_stage == 2) ...[
                // Stage 2: Light Rays & Opening
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 72)),
                  ),
                ).animate().scale(end: const Offset(1.3, 1.3), duration: 600.ms),
                const SizedBox(height: EkagraSpacing.xl),
                Text('Opening...', style: EkagraTypography.h2),
              ] else ...[
                // Stage 3: Revealed Reward
                if (reward != null) ...[
                  if (reward.isRare)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: EkagraColors.primary,
                        borderRadius: BorderRadius.circular(EkagraRadius.full),
                      ),
                      child: Text(
                        '⚡ RARE DROP!',
                        style: EkagraTypography.tiny.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).scale(),

                  const SizedBox(height: EkagraSpacing.md),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(EkagraSpacing.xl),
                    decoration: BoxDecoration(
                      color: EkagraColors.surface,
                      borderRadius: BorderRadius.circular(EkagraRadius.xl),
                      border: Border.all(
                        color: reward.isRare
                            ? EkagraColors.primary
                            : EkagraColors.rewardQuick,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EkagraColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(reward.emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: EkagraSpacing.md),
                        Text(
                          reward.title,
                          style: EkagraTypography.h2,
                          textAlign: TextAlign.center,
                        ),
                        if (reward.description != null) ...[
                          const SizedBox(height: EkagraSpacing.xs),
                          Text(
                            '"${reward.description}"',
                            style: EkagraTypography.encouragement.copyWith(
                              fontSize: 15,
                              color: EkagraColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                ],
              ],

              const Spacer(),

              if (_stage == 3) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (reward != null) {
                        context.read<RewardProvider>().claimReward(reward);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EkagraColors.primary,
                    ),
                    child: const Text(
                      'Claim Reward 🎉',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: EkagraSpacing.md),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save for later',
                    style: EkagraTypography.caption,
                  ),
                ),
              ],

              const SizedBox(height: EkagraSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
