import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/growth_service.dart';

class FocusCompleteScreen extends StatefulWidget {
  final int minutes;
  final String? taskTitle;

  const FocusCompleteScreen({
    super.key,
    required this.minutes,
    this.taskTitle,
  });

  @override
  State<FocusCompleteScreen> createState() => _FocusCompleteScreenState();
}

class _FocusCompleteScreenState extends State<FocusCompleteScreen> {
  bool _hyperfocus = false;

  @override
  void initState() {
    super.initState();
    // Record once, on arrival — this screen is the definitive signal that a
    // session actually finished rather than being abandoned.
    final minutes = widget.minutes;
    track(Ev.focusSessionCompleted, {
      'actual_minutes': minutes,
      'had_task': widget.taskTitle != null,
    });
    GrowthService.instance.recordFocusSession(minutes);

    // Spec H10: a very long session is a hyperfocus episode worth knowing
    // about — it predicts both high value and burnout risk.
    if (minutes >= 120) {
      track(Ev.hyperfocusDetected, {'duration_minutes': minutes});
      _hyperfocus = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.minutes;
    final taskTitle = widget.taskTitle;
    return Scaffold(
      backgroundColor: EkagraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // Celebration Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: EkagraColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 48)),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

              const SizedBox(height: EkagraSpacing.xl),

              Text(
                'Focus Session Complete! 🎉',
                style: EkagraTypography.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.md),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EkagraSpacing.xl),
                decoration: BoxDecoration(
                  color: EkagraColors.surface,
                  borderRadius: BorderRadius.circular(EkagraRadius.xl),
                  border: Border.all(
                    color: EkagraColors.success.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$minutes minutes of focus',
                      style: EkagraTypography.h2.copyWith(
                        color: EkagraColors.success,
                      ),
                    ),
                    if (taskTitle != null) ...[
                      const SizedBox(height: EkagraSpacing.xs),
                      Text(
                        'Task: $taskTitle',
                        style: EkagraTypography.body.copyWith(
                          color: EkagraColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_hyperfocus) ...[
                      const SizedBox(height: EkagraSpacing.sm),
                      Text(
                        'That was a deep dive — $minutes minutes. That is the brain you are building 💛',
                        style: EkagraTypography.caption.copyWith(
                          color: EkagraColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              const Spacer(),

              // Options
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.rewardReveal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                  ),
                  child: const Text(
                    'Reward time! 🎁',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.focus);
                      },
                      child: const Text('Keep going ⏱️'),
                    ),
                  ),
                  const SizedBox(width: EkagraSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.main);
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: EkagraSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
