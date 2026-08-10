import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

class EkagraPaywallSheet extends StatelessWidget {
  const EkagraPaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EkagraPaywallSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EkagraRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: EkagraSpacing.lg,
        left: EkagraSpacing.xl,
        right: EkagraSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + EkagraSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EkagraColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: EkagraSpacing.lg),

          Text(
            '🚀 Unlock Ekagra Pro',
            style: EkagraTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EkagraSpacing.xs),
          Text(
            'Get unlimited tasks, AI task selection, body doubling & custom dopamine rewards.',
            style: EkagraTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EkagraSpacing.xl),

          Container(
            padding: const EdgeInsets.all(EkagraSpacing.md),
            decoration: BoxDecoration(
              color: EkagraColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(EkagraRadius.lg),
              border: Border.all(
                color: EkagraColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              children: [
                _FeatureBullet('⭐ Unlimited Brain Dump Tasks'),
                _FeatureBullet('⭐ AI Task Selection & Micro-commitments'),
                _FeatureBullet('⭐ Full Dopamine Menu & Rare Rewards'),
                _FeatureBullet('⭐ Body Doubling Co-working Rooms'),
                _FeatureBullet('⭐ Widgets & All Ambient Sounds'),
              ],
            ),
          ),
          const SizedBox(height: EkagraSpacing.xl),

          Text(
            'Try Pro free for 7 days\nThen \$7.99/mo or \$49.99/yr',
            style: EkagraTypography.bodyBold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EkagraSpacing.xs),
          Text(
            'Cancel anytime in device Settings > Subscriptions. No questions asked.',
            style: EkagraTypography.tiny,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EkagraSpacing.lg),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await settings.enablePro();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Welcome to Ekagra Pro! All features unlocked.'),
                      backgroundColor: EkagraColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Start 7-Day Free Trial ✨'),
            ),
          ),
          const SizedBox(height: EkagraSpacing.sm),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe later (Continue Free)',
              style: EkagraTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: EkagraTypography.body.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
