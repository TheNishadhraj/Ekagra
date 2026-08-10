import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/analytics_service.dart';
import '../services/monetization_service.dart';
import '../screens/shared/ekagra_paywall_sheet.dart';

/// The single entry point for every Pro-gated action in the app.
///
/// Screens never check `isPro` themselves. They call [ProGate.guard] and get
/// back a bool. That keeps the gating policy, the analytics and the paywall
/// governor in one place — and makes it impossible to ship a gate that
/// forgets to log why it fired.
class ProGate {
  ProGate._();

  /// Returns true when the action may proceed.
  ///
  /// When it returns false, the appropriate paywall has already been shown
  /// (or deliberately suppressed by the governor) and the caller should
  /// simply abort.
  static Future<bool> guard(
    BuildContext context, {
    required ProFeature feature,
    required PaywallTrigger trigger,
  }) async {
    final money = MonetizationService.instance;

    if (money.hasAccess(feature)) return true;

    await money.recordFeatureGateHit(feature);

    if (!money.shouldShowPaywall(trigger)) {
      // Governor said no. We stay silent rather than nagging, and the caller
      // still cannot proceed — but the user is not punished with a popup.
      if (context.mounted) {
        _showGentleNotice(context, feature);
      }
      return false;
    }

    if (!context.mounted) return false;
    await EkagraPaywallSheet.show(context, trigger: trigger, feature: feature);

    // The user may have converted inside the sheet.
    return money.hasAccess(feature);
  }

  /// Quiet, non-blocking explanation when the governor suppresses a paywall.
  /// The user still learns why the thing did not happen, without being sold to.
  static void _showGentleNotice(BuildContext context, ProFeature feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${feature.label} is part of Pro. It will be here when you want it.'),
        backgroundColor: EkagraColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// A small, honest "Pro" affordance.
///
/// Deliberately understated: a soft lock icon, not a flashing upsell. For an
/// audience with rejection sensitivity, an aggressive badge on every locked
/// control reads as constant exclusion and drives uninstalls.
class ProBadge extends StatelessWidget {
  final bool compact;

  const ProBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: EkagraColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EkagraRadius.full),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: EkagraColors.primary,
        ),
      ),
    );
  }
}

/// Shows how much of the free allowance is left.
///
/// Progress-effect framing: "3 of 10 used" reads as headroom, while
/// "7 remaining" reads as a countdown to being cut off. For this audience the
/// first framing keeps people calm; the second creates anxiety about a tool
/// whose entire job is reducing anxiety.
class FreeAllowanceMeter extends StatelessWidget {
  final int used;
  final int limit;
  final String label;

  const FreeAllowanceMeter({
    super.key,
    required this.used,
    required this.limit,
    this.label = 'tasks',
  });

  @override
  Widget build(BuildContext context) {
    if (MonetizationService.instance.isPro) return const SizedBox.shrink();

    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    // Only surface the meter when it is close to relevant. Showing it at
    // 1/10 is pure friction with zero conversion value.
    if (ratio < 0.6) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EkagraSpacing.screen,
        vertical: EkagraSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$used of $limit free $label used',
                style: EkagraTypography.tiny,
              ),
              const Spacer(),
              const ProBadge(compact: true),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(EkagraRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: EkagraColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                // Warm coral at the ceiling — never red (Spec Rule 3).
                ratio >= 1.0 ? EkagraColors.error : EkagraColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trial countdown banner.
///
/// Loss aversion done honestly: we remind the user what they will lose access
/// to, we never fake urgency, and we always offer the one-tap exit.
class TrialStatusBanner extends StatelessWidget {
  const TrialStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final money = MonetizationService.instance;
    if (!money.isTrialing) return const SizedBox.shrink();

    final days = money.trialDaysRemaining;
    // Only speak up in the last stretch. A permanent banner is wallpaper.
    if (days > 3) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: EkagraSpacing.screen,
        vertical: EkagraSpacing.sm,
      ),
      padding: const EdgeInsets.all(EkagraSpacing.md),
      decoration: BoxDecoration(
        color: EkagraColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(color: EkagraColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: EkagraSpacing.md),
          Expanded(
            child: Text(
              days <= 0
                  ? 'Your Pro trial has ended. Free plan still works.'
                  : 'Pro trial: $days ${days == 1 ? 'day' : 'days'} left.',
              style: EkagraTypography.caption.copyWith(
                color: EkagraColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              track(Ev.paywallShown, {'trigger': 'trial_banner'});
              EkagraPaywallSheet.show(
                context,
                trigger: PaywallTrigger.trialExpired,
              );
            },
            child: const Text('Keep Pro'),
          ),
        ],
      ),
    );
  }
}
