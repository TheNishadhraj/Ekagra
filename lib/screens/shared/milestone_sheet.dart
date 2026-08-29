import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/feature_flags.dart';
import '../../config/theme.dart';
import '../../providers/reward_provider.dart';
import '../../config/routes.dart';
import '../../services/analytics_service.dart';
import '../../services/growth_service.dart';

/// WI-5.3 — active-days milestone celebration (7 / 30 / 100).
///
/// "30 days you showed up for yourself." The anti-streak: total days, not
/// consecutive, so a gap never costs progress and there is nothing to
/// "lose". Celebration, never scolding — the inverse of streak apps
/// (Spec Rule 4). One-shot per milestone (GrowthService arms it once).
class MilestoneSheet extends StatelessWidget {
  const MilestoneSheet({super.key, required this.days});

  final int days;

  static Future<void> maybeShow(BuildContext context) async {
    if (FeatureFlags.retentionProgram != FeatureMaturity.live) return;
    final growth = GrowthService.instance;
    final milestone = growth.pendingMilestone;
    if (milestone == null) return;

    await growth.clearPendingMilestone();
    if (!context.mounted) return;
    track(Ev.milestoneCelebrated, {'days': milestone, 'action': 'shown'});
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: EkagraColors.surface,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(EkagraRadius.xl)),
      ),
      builder: (_) => MilestoneSheet(days: milestone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursWord = days == 100 ? '💯' : '💛';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EkagraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hoursWord, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: EkagraSpacing.md),
            Text(
              '$days days you showed up for yourself.',
              style: EkagraTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EkagraSpacing.sm),
            Text(
              'Gaps included. They count too.',
              style: EkagraTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EkagraSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EkagraColors.primary,
                ),
                onPressed: () async {
                  await context
                      .read<RewardProvider>()
                      .recordMilestoneCelebration(days: days);
                  track(Ev.milestoneCelebrated,
                      {'days': days, 'action': 'claimed'});
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.rewardReveal);
                },
                icon: const Icon(Icons.card_giftcard_rounded,
                    color: Colors.white),
                label: const Text('Celebrate 🎁'),
              ),
            ),
            const SizedBox(height: EkagraSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Just warm feelings, thanks'),
            ),
          ],
        ),
      ),
    );
  }
}
