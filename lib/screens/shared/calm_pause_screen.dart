import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// WI-5.1 — the calm pause screen: a choice, never a wall.
///
/// UNREACHABLE until the Android detection layer exists
/// (`FeatureFlags.gentleBlock = unbuilt`; no route registered). Built
/// now, with its copy Rule-15 tested, so the native work lands onto a
/// finished, honest surface instead of a placeholder.
class CalmPauseScreen extends StatelessWidget {
  const CalmPauseScreen({
    super.key,
    required this.appName,
    required this.taskTitle,
    required this.onReturnToTask,
    required this.onTakeBreak,
    this.monkMode = false,
  });

  final String appName;
  final String taskTitle;
  final VoidCallback onReturnToTask;
  final VoidCallback onTakeBreak;

  /// When true (monk mode) no break option is offered — the user chose
  /// this for the session's duration before starting.
  final bool monkMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 44)),
              const SizedBox(height: EkagraSpacing.lg),
              Text(
                'You reached for $appName.',
                style: EkagraTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EkagraSpacing.sm),
              Text(
                monkMode
                    ? 'Monk mode is on. Your session ends at the time you set.'
                    : 'Return to "$taskTitle", or take a 10-min break — your call.',
                style: EkagraTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EkagraSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                  ),
                  onPressed: onReturnToTask,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  label: const Text('Back to my task'),
                ),
              ),
              if (!monkMode) ...[
                const SizedBox(height: EkagraSpacing.md),
                TextButton(
                  onPressed: onTakeBreak,
                  child: const Text('Take a 10-min break instead'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
