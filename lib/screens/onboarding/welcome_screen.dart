import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/settings_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // Animated Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [EkagraColors.primary, EkagraColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(EkagraRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: EkagraColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🧠',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

              const SizedBox(height: EkagraSpacing.xxl),

              // Title
              Text(
                'Hey there 👋',
                style: EkagraTypography.h1,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: EkagraSpacing.md),

              // Subtitle
              Text(
                'Ready to dump what\'s swirling in your head?',
                style: EkagraTypography.encouragement.copyWith(
                  color: EkagraColors.textSecondary,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: EkagraSpacing.sm),

              Text(
                'Ekagra works instantly with zero setup. We pick ONE thing to start.',
                style: EkagraTypography.caption.copyWith(
                  color: EkagraColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms),

              const Spacer(),

              // Primary CTA: Dump now
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.brainDump);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EkagraRadius.xl),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Let\'s go →',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: EkagraSpacing.md),

              // Secondary: Customize first
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.adhdType);
                },
                child: Text(
                  'Want to customize first? →',
                  style: EkagraTypography.bodyBold.copyWith(
                    color: EkagraColors.primary,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.xs),

              TextButton(
                onPressed: () async {
                  await context.read<SettingsProvider>().completeOnboarding();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  }
                },
                child: Text(
                  'Skip setup & open home',
                  style: EkagraTypography.caption.copyWith(
                    color: EkagraColors.textTertiary,
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
