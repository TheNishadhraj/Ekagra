import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/nudge_service.dart';

/// Step 3 of 3 — and since WI-1.4, an honest one.
///
/// This screen used to promise "gentle nudges" while the app had no
/// notification capability at all (K19). The engine is real now, so the
/// button actually requests the OS permission and arms the daily brief.
/// The "later" path is a real skip: notifications stay fully off.
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _finish(
    BuildContext context,
    SettingsProvider settings,
    bool requested,
  ) async {
    var granted = false;
    if (requested) {
      granted = await NudgeService.instance.requestPermission();
    }
    if (granted) {
      await settings.enableNotifications();
      await NudgeService.instance.enabledSet(true);
      await NudgeService.instance.scheduleDailyBrief(
        hour: settings.user.notifications.morning.hour,
      );
    }
    await settings.completeOnboarding();
    track(Ev.onboardingCompleted, {
      'notifications_granted': granted,
      'notifications_requested': requested,
    });
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(title: const Text('Step 3 of 3'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: EkagraColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 40)),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.8, 0.8),
                  ),

              const SizedBox(height: EkagraSpacing.xl),

              Text(
                'Gentle nudges, not alarms',
                style: EkagraTypography.h2,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.sm),

              Text(
                'A few soft reminders a day — and they give up after three tries.',
                style: EkagraTypography.body.copyWith(
                  color: EkagraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.xxl),

              // These are previews of notifications that genuinely exist
              // since WI-1.4 — no dead promises on this screen.
              _sampleCard(
                '💛 "Your one thing is still here when you are."',
              ).animate().fadeIn(
                    delay: 400.ms,
                    duration: 400.ms,
                  ).slideY(begin: 0.2, end: 0),
              const SizedBox(height: EkagraSpacing.md),
              _sampleCard(
                '🌱 "15 min left — still with it? Tap to continue."',
              ).animate().fadeIn(
                    delay: 500.ms,
                    duration: 400.ms,
                  ).slideY(begin: 0.2, end: 0),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _finish(context, settings, true),
                  child: const Text('Enable gentle nudges 🔔'),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              TextButton(
                onPressed: () => _finish(context, settings, false),
                child: Text(
                  'Not today',
                  style: EkagraTypography.caption.copyWith(
                    color: EkagraColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_dot(true), _dot(true), _dot(true)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sampleCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EkagraSpacing.lg),
      decoration: BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.primaryLight.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: EkagraTypography.body.copyWith(fontSize: 14, height: 1.4),
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
        color: active
            ? EkagraColors.primary
            : EkagraColors.primaryLight.withValues(alpha: 0.4),
      ),
    );
  }
}
