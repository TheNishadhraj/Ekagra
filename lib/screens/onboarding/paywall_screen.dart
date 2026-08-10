import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: EkagraSpacing.lg),

              Text('You\'re all set! 🎉', style: EkagraTypography.h1)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: EkagraSpacing.sm),

              Text(
                'Unlock the full Ekagra experience',
                style: EkagraTypography.encouragement.copyWith(
                  fontSize: 16,
                  color: EkagraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: EkagraSpacing.xl),

              // Comparison Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EkagraSpacing.xl),
                decoration: BoxDecoration(
                  color: EkagraColors.surface,
                  borderRadius: BorderRadius.circular(EkagraRadius.xl),
                  border: Border.all(
                    color: EkagraColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Forever:',
                      style: EkagraTypography.bodyBold.copyWith(
                        color: EkagraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: EkagraSpacing.xs),
                    _featureRow('✓ Brain dump (10 tasks)', false),
                    _featureRow('✓ Basic focus timer', false),
                    _featureRow('✓ 3 dopamine menu items', false),

                    const Divider(height: EkagraSpacing.xl),

                    Row(
                      children: [
                        Text(
                          'Ekagra Pro adds:',
                          style: EkagraTypography.h3.copyWith(
                            color: EkagraColors.primary,
                          ),
                        ),
                        const SizedBox(width: EkagraSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EkagraColors.primary,
                            borderRadius: BorderRadius.circular(EkagraRadius.full),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EkagraSpacing.sm),
                    _featureRow('⭐ Unlimited tasks + AI picks', true),
                    _featureRow('⭐ Full dopamine menu & rare drops', true),
                    _featureRow('⭐ Body doubling & ambient rooms', true),
                    _featureRow('⭐ Widgets & Dyslexia font options', true),
                    _featureRow('⭐ Custom themes & stats', true),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: EkagraSpacing.xl),

              // Pricing summary
              Text(
                'Try Pro free for 7 days\nThen \$7.99/month or \$49.99/year',
                style: EkagraTypography.bodyBold.copyWith(
                  color: EkagraColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: EkagraSpacing.xs),

              Text(
                'Cancel anytime in device Settings > Subscriptions. No tricks.',
                style: EkagraTypography.caption.copyWith(
                  color: EkagraColors.textTertiary,
                ),
              ),

              const SizedBox(height: EkagraSpacing.xl),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await settings.enablePro();
                    await settings.completeOnboarding();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.main);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EkagraRadius.xl),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Start 7-Day Free Trial ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              TextButton(
                onPressed: () async {
                  await settings.completeOnboarding();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  }
                },
                child: Text(
                  'Maybe later (Continue with Free)',
                  style: EkagraTypography.body.copyWith(
                    color: EkagraColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String text, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: EkagraTypography.body.copyWith(
          fontSize: 15,
          fontWeight: isPro ? FontWeight.w600 : FontWeight.w400,
          color: isPro ? EkagraColors.textPrimary : EkagraColors.textSecondary,
        ),
      ),
    );
  }
}
