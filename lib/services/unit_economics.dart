import 'package:flutter/foundation.dart';

import '../config/constants.dart';

/// Unit economics for Ekagra, expressed as code so the business model is
/// testable and version-controlled rather than trapped in a spreadsheet
/// nobody opens.
///
/// Every default below is a stated assumption, not a fact. They are the
/// starting priors for a consumer subscription app in the ADHD/productivity
/// category; replace them with measured values as soon as real data exists,
/// and the whole model re-derives.
@immutable
class UnitEconomicsInputs {
  /// Blended cost to acquire one install, across paid and organic.
  final double cacPerInstall;

  /// Share of installs that reach the aha moment (first claimed reward).
  final double activationRate;

  /// Share of activated users who start a trial.
  final double trialStartRate;

  /// Share of trial starters who convert to paid.
  final double trialConversionRate;

  /// Monthly logo churn among paying subscribers.
  final double monthlyChurnRate;

  /// Share of paying subscribers on the annual plan.
  final double annualMix;

  /// Payment processor + store commission (Apple/Google year-one rate).
  final double storeCommission;

  /// Variable cost to serve one active user per month: AI inference,
  /// storage, push, crash reporting.
  final double monthlyCostToServe;

  const UnitEconomicsInputs({
    this.cacPerInstall = 2.40,
    this.activationRate = 0.35,
    this.trialStartRate = 0.22,
    this.trialConversionRate = 0.45,
    this.monthlyChurnRate = 0.075,
    this.annualMix = 0.40,
    this.storeCommission = 0.30,
    this.monthlyCostToServe = 0.35,
  });

  UnitEconomicsInputs copyWith({
    double? cacPerInstall,
    double? activationRate,
    double? trialStartRate,
    double? trialConversionRate,
    double? monthlyChurnRate,
    double? annualMix,
    double? storeCommission,
    double? monthlyCostToServe,
  }) {
    return UnitEconomicsInputs(
      cacPerInstall: cacPerInstall ?? this.cacPerInstall,
      activationRate: activationRate ?? this.activationRate,
      trialStartRate: trialStartRate ?? this.trialStartRate,
      trialConversionRate: trialConversionRate ?? this.trialConversionRate,
      monthlyChurnRate: monthlyChurnRate ?? this.monthlyChurnRate,
      annualMix: annualMix ?? this.annualMix,
      storeCommission: storeCommission ?? this.storeCommission,
      monthlyCostToServe: monthlyCostToServe ?? this.monthlyCostToServe,
    );
  }
}

/// Derived economics. All outputs are pure functions of the inputs — no
/// hidden state, so every number here can be unit-tested.
class UnitEconomics {
  final UnitEconomicsInputs i;

  const UnitEconomics([this.i = const UnitEconomicsInputs()]);

  /// Probability an install ever becomes a paying subscriber.
  double get installToPaidRate =>
      i.activationRate * i.trialStartRate * i.trialConversionRate;

  /// Effective CAC per *paying customer*, which is the only CAC that matters.
  /// Install CAC flatters the model; this is the honest number.
  double get cacPerPayingCustomer {
    if (installToPaidRate <= 0) return double.infinity;
    return i.cacPerInstall / installToPaidRate;
  }

  /// Blended monthly revenue per subscriber before store fees.
  double get grossMonthlyArpu {
    final monthlyRevenue =
        EkagraConstants.proMonthlyPrice * (1 - i.annualMix);
    final annualRevenue =
        (EkagraConstants.proYearlyPrice / 12) * i.annualMix;
    return monthlyRevenue + annualRevenue;
  }

  /// What we actually keep each month per subscriber.
  double get netMonthlyArpu =>
      grossMonthlyArpu * (1 - i.storeCommission) - i.monthlyCostToServe;

  /// Expected subscriber lifetime in months = 1 / churn.
  double get averageLifetimeMonths {
    if (i.monthlyChurnRate <= 0) return double.infinity;
    return 1 / i.monthlyChurnRate;
  }

  /// Lifetime value, net of store commission and cost to serve.
  double get ltv => netMonthlyArpu * averageLifetimeMonths;

  /// The ratio that decides whether this is a business. Target > 3.0.
  double get ltvToCacRatio {
    final cac = cacPerPayingCustomer;
    if (cac <= 0 || cac.isInfinite) return 0;
    return ltv / cac;
  }

  /// Months of subscription revenue needed to repay acquisition cost.
  /// Target < 12.
  double get paybackPeriodMonths {
    if (netMonthlyArpu <= 0) return double.infinity;
    return cacPerPayingCustomer / netMonthlyArpu;
  }

  /// Contribution margin per subscriber per month, as a fraction of gross.
  double get contributionMarginPercent {
    if (grossMonthlyArpu <= 0) return 0;
    return netMonthlyArpu / grossMonthlyArpu;
  }

  /// Revenue per install — the number to compare directly against install CAC
  /// when evaluating a paid acquisition channel.
  double get ltvPerInstall => ltv * installToPaidRate;

  /// Is this channel profitable at the current install CAC?
  bool get isChannelProfitable => ltvPerInstall > i.cacPerInstall;

  /// Projected annual recurring revenue for a given paying subscriber base.
  double arrAt(int payingSubscribers) =>
      netMonthlyArpu * 12 * payingSubscribers;

  /// Monthly recurring revenue for a given paying subscriber base.
  double mrrAt(int payingSubscribers) => netMonthlyArpu * payingSubscribers;

  /// Paying subscribers implied by an install volume.
  int payingFromInstalls(int installs) => (installs * installToPaidRate).round();

  /// Sensitivity helper: what does ARR look like if one lever moves?
  /// This is how you decide what to work on next — the lever with the
  /// steepest slope wins the sprint.
  double arrDeltaFrom({
    required int installs,
    required UnitEconomicsInputs changed,
  }) {
    final baseline = arrAt(payingFromInstalls(installs));
    final variant = UnitEconomics(changed);
    final improved = variant.arrAt(variant.payingFromInstalls(installs));
    return improved - baseline;
  }

  /// Human-readable model summary. Used by the in-app growth dashboard.
  Map<String, String> get summary => {
        'Install → paid': '${(installToPaidRate * 100).toStringAsFixed(2)}%',
        'CAC (paying)': '\$${cacPerPayingCustomer.toStringAsFixed(2)}',
        'Net ARPU / mo': '\$${netMonthlyArpu.toStringAsFixed(2)}',
        'Avg lifetime': '${averageLifetimeMonths.toStringAsFixed(1)} mo',
        'LTV': '\$${ltv.toStringAsFixed(2)}',
        'LTV:CAC': '${ltvToCacRatio.toStringAsFixed(2)}:1',
        'Payback': '${paybackPeriodMonths.toStringAsFixed(1)} mo',
        'Contribution margin':
            '${(contributionMarginPercent * 100).toStringAsFixed(0)}%',
      };

  /// Health verdict against the standard consumer-subscription bars.
  List<String> get warnings {
    final out = <String>[];
    if (ltvToCacRatio < 3) {
      out.add(
        'LTV:CAC is ${ltvToCacRatio.toStringAsFixed(2)}:1 — below the 3:1 bar. '
        'Do not scale paid acquisition yet.',
      );
    }
    if (paybackPeriodMonths > 12) {
      out.add(
        'Payback is ${paybackPeriodMonths.toStringAsFixed(1)} months — over the '
        '12-month bar. Cash burn will outrun growth.',
      );
    }
    if (i.monthlyChurnRate > 0.08) {
      out.add(
        'Monthly churn of ${(i.monthlyChurnRate * 100).toStringAsFixed(1)}% caps '
        'lifetime at ${averageLifetimeMonths.toStringAsFixed(1)} months. '
        'Retention work beats acquisition work here.',
      );
    }
    if (i.activationRate < 0.30) {
      out.add(
        'Activation of ${(i.activationRate * 100).toStringAsFixed(0)}% means most '
        'acquisition spend never reaches the aha moment. Fix onboarding first.',
      );
    }
    return out;
  }
}
