import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/reward_provider.dart';

class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final history = rewardProvider.history;
    final rareDrops = history.where((r) => r.isRare).toList();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Your Rewards 🎁'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EkagraSpacing.lg),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(EkagraSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EkagraColors.primary, EkagraColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(EkagraRadius.xl),
              ),
              child: Column(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: EkagraSpacing.xs),
                  Text(
                    '${history.length} Rewards Unlocked',
                    style: EkagraTypography.h2.copyWith(color: Colors.white),
                  ),
                  Text(
                    '${rareDrops.length} Rare Drops Earned',
                    style: EkagraTypography.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: EkagraSpacing.xl),

            if (rareDrops.isNotEmpty) ...[
              Text('── Rare Drops ──', style: EkagraTypography.tiny),
              const SizedBox(height: EkagraSpacing.sm),
              ...rareDrops.map((r) => _rewardTile(r, isRare: true)),
              const SizedBox(height: EkagraSpacing.xl),
            ],

            Text('── History ──', style: EkagraTypography.tiny),
            const SizedBox(height: EkagraSpacing.sm),

            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: EkagraSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🍫', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: EkagraSpacing.sm),
                      Text('No rewards claimed yet!', style: EkagraTypography.bodyBold),
                      Text(
                        'Complete focus sessions to unlock surprises.',
                        style: EkagraTypography.caption,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...history.map((r) => _rewardTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _rewardTile(dynamic r, {bool isRare = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: EkagraSpacing.sm),
      child: ListTile(
        leading: Text(r.emoji ?? '🎁', style: const TextStyle(fontSize: 26)),
        title: Text(r.title ?? 'Reward', style: EkagraTypography.bodyBold),
        subtitle: r.description != null ? Text(r.description!, style: EkagraTypography.caption) : null,
        trailing: isRare
            ? const Text('⚡ Rare', style: TextStyle(color: EkagraColors.primary, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }
}
