import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';

/// The welcome-back state (WI-1.3, research: stability is the #5 want and
/// Finch/Tiimo churn on data-loss stories).
///
/// Shown at most once per ≥3-day gap, and only when there is something to
/// come back to. The claim "Nothing was lost" is only ever made because it
/// is structurally true: SafeStore (ADR-001) quarantines instead of
/// dropping, and nothing is ever hard-deleted (Rule 13).
class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({super.key, this.oneThing});

  final TaskModel? oneThing;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    // Used as an initial route there are no arguments, so fall back to the
    // provider's current pick.
    final thing = oneThing ?? context.read<TaskProvider>().oneThing;

    return Scaffold(
      backgroundColor: EkagraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: EkagraColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💛', style: TextStyle(fontSize: 44)),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),

              const SizedBox(height: EkagraSpacing.xl),

              Text(
                'Nothing was lost.',
                style: EkagraTypography.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.md),

              Text(
                'Everything you saved is still here, safe on your phone. '
                'No catch-up, no homework — just whatever feels doable today.',
                style: EkagraTypography.body.copyWith(
                  color: EkagraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.xl),

              if (thing != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EkagraSpacing.lg),
                  decoration: BoxDecoration(
                    color: EkagraColors.surface,
                    borderRadius: BorderRadius.circular(EkagraRadius.lg),
                    border: Border.all(
                      color: EkagraColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('YOUR ONE THING', style: EkagraTypography.tiny),
                      const SizedBox(height: EkagraSpacing.xs),
                      Text(
                        '${thing.emoji ?? '✨'}  ${thing.title}',
                        style: EkagraTypography.h3,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await settings.markWelcomeBackShown();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.main);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                  ),
                  child: const Text(
                    'Show me my one thing →',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: EkagraSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
