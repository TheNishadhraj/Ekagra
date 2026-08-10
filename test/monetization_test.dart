import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MonetizationService money;
  late InMemoryAnalyticsSink sink;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    money = MonetizationService.instance;
    await money.resetForTest();
    await AnalyticsService.instance.resetForTest();
    sink = InMemoryAnalyticsSink();
    AnalyticsService.instance.addSink(sink);
  });

  group('Entitlement state machine', () {
    test('a new user is free and has no Pro access', () {
      expect(money.isPro, isFalse);
      expect(money.status, EntitlementStatus.free);
      // Only *billable* features are gated. Simulated features stay open
      // to everyone, because we do not sell them.
      for (final f in ProFeature.values.where((f) => f.isBillable)) {
        expect(money.hasAccess(f), isFalse, reason: '${f.name} must be gated');
      }
    });

    test('starting a trial grants access to every Pro feature', () async {
      await money.startTrial(trigger: PaywallTrigger.onboarding);

      expect(money.isPro, isTrue);
      expect(money.isTrialing, isTrue);
      for (final f in ProFeature.values) {
        expect(money.hasAccess(f), isTrue);
      }
      expect(sink.sawEvent(Ev.trialStarted), isTrue);
      expect(sink.sawEvent(Ev.paywallConverted), isTrue);
    });

    test('an expired trial revokes access', () async {
      await money.startTrial(trigger: PaywallTrigger.onboarding);
      money.debugSetTrialEnd(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(money.isTrialExpired, isTrue);
      expect(money.isPro, isFalse);
      expect(money.hasAccess(ProFeature.unlimitedTasks), isFalse);
    });

    test('purchasing from a trial emits trial_converted', () async {
      await money.startTrial(trigger: PaywallTrigger.onboarding);
      await money.purchase(
        plan: SubscriptionPlan.annual,
        trigger: PaywallTrigger.onboarding,
      );

      expect(money.status, EntitlementStatus.pro);
      expect(money.isPro, isTrue);
      expect(sink.sawEvent(Ev.trialConverted), isTrue);
    });

    test('cancelling keeps access until the paid period ends', () async {
      await money.purchase(
        plan: SubscriptionPlan.monthly,
        trigger: PaywallTrigger.settings,
      );
      await money.cancel();

      // The user paid for this month. Yanking access instantly is punitive
      // and guarantees they never return.
      expect(money.status, EntitlementStatus.cancelled);
      expect(money.isPro, isTrue);
      expect(sink.sawEvent(Ev.subscriptionCancelled), isTrue);
    });

    test('corrupt persisted state fails closed to free, never to Pro',
        () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_monetization_state': '{{{ not json',
      });
      await money.resetForTest();
      await money.load();

      expect(money.isPro, isFalse);
      expect(money.status, EntitlementStatus.free);
    });
  });

  group('Paywall governor — the anti-nag system', () {
    test('a hard gate always shows', () async {
      expect(money.shouldShowPaywall(PaywallTrigger.taskLimit), isTrue);
      await money.recordPaywallShown(PaywallTrigger.taskLimit);
      // Even immediately afterwards, because it protects a real ceiling.
      expect(money.shouldShowPaywall(PaywallTrigger.taskLimit), isTrue);
    });

    test('a soft gate respects the cooldown window', () async {
      // ambientSounds is billable + soft, so it exercises the governor
      // rather than the not-billable short circuit.
      expect(money.shouldShowPaywall(PaywallTrigger.ambientSounds), isTrue);
      await money.recordPaywallShown(PaywallTrigger.ambientSounds);

      expect(money.shouldShowPaywall(PaywallTrigger.insights), isFalse);
      expect(sink.sawEvent(Ev.paywallSuppressed), isTrue);
    });

    test('never exceeds the daily cap', () async {
      await money.recordPaywallShown(PaywallTrigger.ambientSounds);
      await money.recordPaywallShown(PaywallTrigger.insights);

      expect(
        AnalyticsService.instance.lifetimeCount(Ev.paywallShown),
        MonetizationService.maxPaywallsPerDay,
      );
      expect(money.shouldShowPaywall(PaywallTrigger.insights), isFalse);
    });

    test('retires a trigger after repeated dismissals', () async {
      const trigger = PaywallTrigger.ambientSounds;
      for (var i = 0; i < MonetizationService.dismissalsBeforeBackoff; i++) {
        await money.recordPaywallDismissed(trigger);
      }

      // Three "no"s is an answer. We stop asking permanently.
      expect(money.shouldShowPaywall(trigger), isFalse);
      final suppressed = sink
          .named(Ev.paywallSuppressed)
          .where((e) => e.props['reason'] == 'trigger_retired');
      expect(suppressed, isNotEmpty);
    });

    test('shows nothing at all to an existing subscriber', () async {
      await money.purchase(
        plan: SubscriptionPlan.annual,
        trigger: PaywallTrigger.settings,
      );
      for (final t in PaywallTrigger.values) {
        expect(money.shouldShowPaywall(t), isFalse);
      }
    });
  });

  group('Pricing integrity', () {
    test('annual is genuinely cheaper per month than monthly', () {
      expect(
        SubscriptionPlan.annual.effectiveMonthly,
        lessThan(SubscriptionPlan.monthly.effectiveMonthly),
      );
    });

    test('the advertised annual saving is arithmetically true', () {
      // If this ever fails we are lying to users on the paywall.
      final claimed = SubscriptionPlan.annual.annualSavingsPercent;
      final yearOfMonthly = SubscriptionPlan.monthly.price * 12;
      final actual =
          ((yearOfMonthly - SubscriptionPlan.annual.price) / yearOfMonthly) *
              100;
      expect(claimed, closeTo(actual, 1.0));
      expect(claimed, greaterThan(0));
    });
  });
}
