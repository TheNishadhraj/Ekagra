import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/experiment_service.dart';
import '../../services/growth_service.dart';
import '../../services/monetization_service.dart';
import '../../services/unit_economics.dart';

/// In-app growth console.
///
/// Most teams ship analytics they never look at because the dashboard lives
/// in a separate tool behind a login. Putting the North Star, the activation
/// funnel, live experiment assignments and the unit-economics model one tap
/// from Settings means the numbers get seen daily — and numbers that get seen
/// daily are the ones that get moved.
///
/// Debug/internal surface: it reads only local state, so it works offline and
/// leaks nothing.
class GrowthDashboardScreen extends StatefulWidget {
  const GrowthDashboardScreen({super.key});

  @override
  State<GrowthDashboardScreen> createState() => _GrowthDashboardScreenState();
}

class _GrowthDashboardScreenState extends State<GrowthDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final growth = GrowthService.instance;
    final money = MonetizationService.instance;
    final analytics = AnalyticsService.instance;
    const econ = UnitEconomics();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(title: const Text('Growth Console 📈')),
      body: ListView(
        padding: const EdgeInsets.all(EkagraSpacing.screen),
        children: [
          // ── North Star ─────────────────────────────────────────────────
          const _Section('North Star Metric'),
          _HeroCard(
            value: '${growth.northStarValue}',
            label: 'Focused Task Completions',
            caption:
                'The one number that only moves when the product genuinely '
                'works. Not DAU — a user who opens the app five times and '
                'finishes nothing got no value.',
          ),
          _StatRow(
            'Per active day',
            growth.northStarPerActiveDay.toStringAsFixed(2),
          ),
          _StatRow('Focus sessions', '${growth.totalFocusSessions}'),
          _StatRow('Focus minutes', '${growth.totalFocusMinutes}'),
          _StatRow('Rewards claimed', '${growth.totalRewardsClaimed}'),

          const SizedBox(height: EkagraSpacing.xl),

          // ── Activation ─────────────────────────────────────────────────
          const _Section('Activation Funnel'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  growth.isActivated
                      ? '✅ Activated'
                      : '${(growth.activationProgress * 100).round()}% through the ladder',
                  style: EkagraTypography.bodyBold,
                ),
                const SizedBox(height: EkagraSpacing.sm),
                ...ActivationStep.values.map((step) {
                  final done = growth.hasCompleted(step);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 16,
                          color: done
                              ? EkagraColors.success
                              : EkagraColors.textTertiary,
                        ),
                        const SizedBox(width: EkagraSpacing.sm),
                        Expanded(
                          child: Text(
                            step.label,
                            style: EkagraTypography.caption.copyWith(
                              color: done
                                  ? EkagraColors.textPrimary
                                  : EkagraColors.textTertiary,
                            ),
                          ),
                        ),
                        if (step == ActivationStepX.ahaMoment)
                          Text('AHA', style: EkagraTypography.tiny),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: EkagraSpacing.xl),

          // ── Retention ──────────────────────────────────────────────────
          const _Section('Retention'),
          _StatRow('Active days (total)', '${growth.totalActiveDays}'),
          _StatRow(
            'Consecutive active days',
            '${growth.consecutiveActiveDays}',
          ),
          _StatRow('Habit formed', growth.hasHabit ? 'Yes' : 'Not yet'),
          _StatRow('Days since install', '${growth.daysSinceInstall}'),

          const SizedBox(height: EkagraSpacing.xl),

          // ── Monetization ───────────────────────────────────────────────
          const _Section('Monetization'),
          _StatRow('Entitlement', money.statusLabel),
          _StatRow(
            'Paywalls shown',
            '${analytics.lifetimeCount(Ev.paywallShown)}',
          ),
          _StatRow(
            'Paywalls suppressed',
            '${analytics.lifetimeCount(Ev.paywallSuppressed)}',
          ),
          _StatRow(
            'Dismissals',
            '${analytics.lifetimeCount(Ev.paywallDismissed)}',
          ),
          _StatRow(
            'Gate hits',
            '${analytics.lifetimeCount(Ev.featureGateHit)}',
          ),
          _StatRow(
            'Paywall → trial',
            '${(analytics.funnelRate(Ev.paywallShown, Ev.trialStarted) * 100).toStringAsFixed(1)}%',
          ),
          _StatRow('Free task limit', '${money.freeTaskLimit}'),
          _StatRow('Trial length', '${money.trialDays} days'),

          const SizedBox(height: EkagraSpacing.xl),

          // ── Unit economics ─────────────────────────────────────────────
          const _Section('Unit Economics (modelled)'),
          _Card(
            child: Column(
              children: econ.summary.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(e.key, style: EkagraTypography.caption),
                          ),
                          Text(e.value, style: EkagraTypography.bodyBold),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (econ.warnings.isNotEmpty) ...[
            const SizedBox(height: EkagraSpacing.sm),
            ...econ.warnings.map(
              (w) => Container(
                margin: const EdgeInsets.only(bottom: EkagraSpacing.sm),
                padding: const EdgeInsets.all(EkagraSpacing.md),
                decoration: BoxDecoration(
                  color: EkagraColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EkagraRadius.md),
                ),
                child: Text(w, style: EkagraTypography.caption),
              ),
            ),
          ],

          const SizedBox(height: EkagraSpacing.xl),

          // ── Experiments ────────────────────────────────────────────────
          const _Section('Live Experiments'),
          ...Experiments.all.map((exp) {
            final assigned = ExperimentService.instance.variantOf(exp);
            return _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp.key, style: EkagraTypography.bodyBold),
                  const SizedBox(height: 2),
                  Text(exp.hypothesis, style: EkagraTypography.tiny),
                  const SizedBox(height: EkagraSpacing.sm),
                  Wrap(
                    spacing: 6,
                    children: exp.variants.map((v) {
                      final isActive = v == assigned;
                      return ChoiceChip(
                        label: Text(v, style: const TextStyle(fontSize: 11)),
                        selected: isActive,
                        selectedColor:
                            EkagraColors.primary.withValues(alpha: 0.2),
                        onSelected: (_) async {
                          await ExperimentService.instance
                              .setOverride(exp.key, v);
                          if (mounted) setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Success: ${exp.successMetric}',
                    style: EkagraTypography.tiny,
                  ),
                  if (exp.guardrailMetrics.isNotEmpty)
                    Text(
                      'Guardrails: ${exp.guardrailMetrics.join(', ')}',
                      style: EkagraTypography.tiny,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Needs ${ExperimentMath.requiredSampleSize(0.05, 0.01)} users '
                    'per arm to detect +1pp on a 5% baseline.',
                    style: EkagraTypography.tiny,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: EkagraSpacing.md),
          TextButton(
            onPressed: () async {
              await ExperimentService.instance.clearOverrides();
              if (mounted) setState(() {});
            },
            child: const Text('Clear experiment overrides'),
          ),

          const SizedBox(height: EkagraSpacing.xl),

          // ── Raw event stream ───────────────────────────────────────────
          const _Section('Recent Events'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: analytics.buffered.reversed
                  .take(25)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${e.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${e.timestamp.minute.toString().padLeft(2, '0')}  ${e.name}',
                        style: EkagraTypography.tiny,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: EkagraSpacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EkagraSpacing.sm),
      child: Text(title, style: EkagraTypography.h3),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: EkagraSpacing.sm),
      padding: const EdgeInsets.all(EkagraSpacing.lg),
      decoration: BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: child,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String value;
  final String label;
  final String caption;

  const _HeroCard({
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: EkagraSpacing.md),
      padding: const EdgeInsets.all(EkagraSpacing.xl),
      decoration: BoxDecoration(
        color: EkagraColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(EkagraRadius.xl),
        border: Border.all(color: EkagraColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: EkagraTypography.h1.copyWith(color: EkagraColors.primary),
          ),
          Text(label, style: EkagraTypography.bodyBold),
          const SizedBox(height: EkagraSpacing.sm),
          Text(caption, style: EkagraTypography.tiny),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: EkagraSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: EkagraTypography.caption)),
          Text(value, style: EkagraTypography.bodyBold),
        ],
      ),
    );
  }
}
