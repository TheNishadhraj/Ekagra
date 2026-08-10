import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/experiment_service.dart';
import '../../services/growth_service.dart';
import '../../services/monetization_service.dart';

/// The conversion surface.
///
/// Three principles drive every choice here:
///
/// 1. CONTEXTUAL — the headline names the exact thing the user just tried to
///    do. A generic feature grid converts a fraction of what "you hit your
///    10-task ceiling" converts, because the second one answers the question
///    the user is actually asking.
/// 2. ANCHORED — annual is presented first and priced per-month, so the
///    monthly option is judged against it rather than against zero.
/// 3. HONEST — real savings maths, the exact charge date, a visible free
///    path, and no fake countdowns. Spec Rule 8 is non-negotiable, and for an
///    RSD-sensitive audience a manipulative paywall is an uninstall.
class EkagraPaywallSheet extends StatefulWidget {
  final PaywallTrigger trigger;
  final ProFeature? feature;

  const EkagraPaywallSheet({
    super.key,
    this.trigger = PaywallTrigger.settings,
    this.feature,
  });

  static Future<void> show(
    BuildContext context, {
    PaywallTrigger trigger = PaywallTrigger.settings,
    ProFeature? feature,
  }) async {
    await MonetizationService.instance.recordPaywallShown(trigger);

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EkagraPaywallSheet(trigger: trigger, feature: feature),
    );
  }

  @override
  State<EkagraPaywallSheet> createState() => _EkagraPaywallSheetState();
}

class _EkagraPaywallSheetState extends State<EkagraPaywallSheet> {
  late SubscriptionPlan _selected;
  bool _converted = false;

  @override
  void initState() {
    super.initState();
    // Anchoring experiment: which plan is pre-selected and shown first.
    final annualFirst = ExperimentService.instance
        .isIn(Experiments.paywallAnchor, 'annual_first');
    _selected = annualFirst ? SubscriptionPlan.annual : SubscriptionPlan.monthly;
  }

  /// Contextual headline. This is the single highest-leverage string in the
  /// whole monetization system.
  String get _headline {
    switch (widget.trigger) {
      case PaywallTrigger.taskLimit:
        return 'Your head has more in it than 10 things';
      case PaywallTrigger.aiSelection:
        return 'Let Ekagra choose, so you don\'t have to';
      case PaywallTrigger.bodyDoubling:
        return 'Work alongside someone else';
      case PaywallTrigger.widgets:
        return 'Your ONE thing, right on your home screen';
      case PaywallTrigger.focusDuration:
        return 'Focus for as long as today allows';
      case PaywallTrigger.ambientSounds:
        return 'Find the sound that starts your engine';
      case PaywallTrigger.taskBreakdown:
        return 'Make the scary task into three small ones';
      case PaywallTrigger.insights:
        return 'Learn when your good hours actually are';
      case PaywallTrigger.dataExport:
        return 'Your data, wherever you want it';
      case PaywallTrigger.trialExpired:
        return 'Keep the version that\'s been working';
      case PaywallTrigger.winbackOffer:
        return 'Pick up where you left off';
      case PaywallTrigger.onboarding:
        return 'Try everything free for ${MonetizationService.instance.trialDays} days';
      case PaywallTrigger.settings:
        return 'Ekagra Pro';
    }
  }

  /// Reciprocity framing: lead with what the user has already accomplished
  /// before asking for anything. Give value, then ask — in that order.
  String? get _reciprocityLine {
    final useReciprocity = ExperimentService.instance
        .isIn(Experiments.paywallFraming, 'reciprocity_framing');
    if (!useReciprocity) return null;

    final growth = GrowthService.instance;
    if (growth.totalTasksCompleted >= 3) {
      return 'You\'ve finished ${growth.totalTasksCompleted} things with Ekagra so far. '
          'Pro removes the ceilings.';
    }
    if (growth.totalFocusMinutes >= 25) {
      return 'You\'ve focused for ${growth.totalFocusMinutes} minutes here already.';
    }
    return null;
  }

  /// Only the features relevant to what the user just hit, plus the two
  /// universal ones. A 12-row feature grid is cognitive load, and this
  /// audience is the least equipped to absorb it.
  /// Every feature listed here must be billable. Advertising a simulated
  /// feature on a payment screen is the misrepresentation — listing it is
  /// the act, not charging for it.
  List<ProFeature> get _relevantFeatures {
    final primary = widget.feature;
    final base = <ProFeature>[
      ProFeature.unlimitedTasks,
      ProFeature.allFocusDurations,
      ProFeature.unlimitedDopamineMenu,
      ProFeature.detailedStats,
    ];
    final candidates =
        primary == null ? base : [primary, ...base.where((f) => f != primary)];
    return candidates.where((f) => f.isBillable).take(3).toList();
  }

  Future<void> _startTrial() async {
    final money = MonetizationService.instance;
    await money.startTrial(trigger: widget.trigger, plan: _selected);

    // Keep the legacy user flag in sync so existing UI stays correct.
    if (mounted) {
      await context.read<SettingsProvider>().enablePro();
    }

    _converted = true;
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pro unlocked for ${money.trialDays} days. Cancel anytime in Settings.',
        ),
        backgroundColor: EkagraColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    // A dismissal is signal. It feeds the governor's backoff logic so we
    // stop asking users who have already said no.
    if (!_converted) {
      MonetizationService.instance.recordPaywallDismissed(widget.trigger);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final money = MonetizationService.instance;
    final reciprocity = _reciprocityLine;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(EkagraRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                _headline,
                style: EkagraTypography.h2,
                textAlign: TextAlign.center,
              ),

              if (reciprocity != null) ...[
                const SizedBox(height: EkagraSpacing.sm),
                Text(
                  reciprocity,
                  style: EkagraTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: EkagraSpacing.xl),

              // Only what matters right now.
              ..._relevantFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: EkagraSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✦ ', style: TextStyle(fontSize: 15)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label, style: EkagraTypography.bodyBold),
                            Text(f.benefit, style: EkagraTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.md),

              // Plan choice. Annual carries the visible savings maths so the
              // monthly price is judged against a reference point.
              _PlanTile(
                plan: SubscriptionPlan.annual,
                selected: _selected == SubscriptionPlan.annual,
                onTap: () => setState(() => _selected = SubscriptionPlan.annual),
              ),
              const SizedBox(height: EkagraSpacing.sm),
              _PlanTile(
                plan: SubscriptionPlan.monthly,
                selected: _selected == SubscriptionPlan.monthly,
                onTap: () => setState(() => _selected = SubscriptionPlan.monthly),
              ),

              const SizedBox(height: EkagraSpacing.lg),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _startTrial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EkagraRadius.xl),
                    ),
                  ),
                  child: Text(
                    money.hasEverTrialed
                        ? 'Unlock Pro — ${_selected.label}'
                        : 'Start ${money.trialDays}-day free trial',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.sm),

              // Full transparency about what happens and when.
              Text(
                money.hasEverTrialed
                    ? 'Billed \$${_selected.price.toStringAsFixed(2)} ${_selected == SubscriptionPlan.annual ? 'per year' : 'per month'}. Cancel in one tap.'
                    : 'Free for ${money.trialDays} days, then \$${_selected.price.toStringAsFixed(2)}'
                        '${_selected == SubscriptionPlan.annual ? '/year' : '/month'}. '
                        'Cancel in one tap before then and you pay nothing.',
                style: EkagraTypography.tiny,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: EkagraSpacing.md),

              // The free path stays visible and unpunished (Spec Rule 8).
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.trigger.isHard
                      ? 'Not now — I\'ll tidy up my list instead'
                      : 'Not now — Free works fine',
                  style: EkagraTypography.caption.copyWith(
                    color: EkagraColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAnnual = plan == SubscriptionPlan.annual;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(EkagraSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? EkagraColors.primary.withValues(alpha: 0.06)
              : EkagraColors.surface,
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
          border: Border.all(
            color: selected
                ? EkagraColors.primary
                : EkagraColors.textTertiary.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? EkagraColors.primary
                  : EkagraColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: EkagraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: EkagraTypography.bodyBold),
                      if (isAnnual) ...[
                        const SizedBox(width: EkagraSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EkagraColors.success.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(EkagraRadius.full),
                          ),
                          child: Text(
                            'Save ${plan.annualSavingsPercent}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: EkagraColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    isAnnual
                        ? '\$${plan.effectiveMonthly.toStringAsFixed(2)}/mo, billed yearly'
                        : 'Billed monthly',
                    style: EkagraTypography.tiny,
                  ),
                ],
              ),
            ),
            Text(
              '\$${plan.price.toStringAsFixed(2)}',
              style: EkagraTypography.bodyBold.copyWith(
                color: selected
                    ? EkagraColors.primary
                    : EkagraColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
