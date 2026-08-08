import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('4 of 4'),
        centerTitle: true,
      ),
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
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: EkagraSpacing.xl),

              Text(
                'Gentle nudges, not alarms',
                style: EkagraTypography.h2,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.sm),

              Text(
                'Soft reminders like a friend tapping your shoulder.',
                style: EkagraTypography.body.copyWith(
                  color: EkagraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.xxl),

              // Sample notification cards
              _sampleCard(
                '💛 "Hey, you\'ve got 15 min. Want to tackle that email?"',
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: EkagraSpacing.md),
              _sampleCard(
                '💛 "You haven\'t checked in today. No pressure — just saying hi."',
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<SettingsProvider>().enableNotifications();
                    if (context.mounted) {
                      Navigator.pushNamed(context, AppRoutes.paywall);
                    }
                  },
                  child: const Text('Enable gentle nudges 🔔'),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.paywall);
                },
                child: Text(
                  'I\'ll do this later',
                  style: EkagraTypography.caption.copyWith(
                    color: EkagraColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(true),
                  _dot(true),
                  _dot(true),
                  _dot(true),
                ],
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
        style: EkagraTypography.body.copyWith(
          fontSize: 14,
          height: 1.4,
        ),
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
        color: active ? EkagraColors.primary : EkagraColors.primaryLight.withValues(alpha: 0.4),
      ),
    );
  }
}
