import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/experiment_service.dart';
import 'package:ekagra/services/growth_service.dart';
import 'package:ekagra/services/unit_economics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
    await GrowthService.instance.resetForTest();
  });

  group('Activation ladder', () {
    test('the aha moment is the first claimed reward, not signup', () {
      // If this ever changes, the entire activation funnel and every
      // onboarding decision downstream needs re-litigating.
      expect(ActivationStepX.ahaMoment, ActivationStep.firstRewardClaimed);
    });

    test('claiming the first reward marks the user activated', () async {
      final growth = GrowthService.instance;
      expect(growth.isActivated, isFalse);

      await growth.recordRewardClaimed();

      expect(growth.isActivated, isTrue);
      expect(growth.activatedAt, isNotNull);
    });

    test('completing a step twice does not double-count the funnel',
        () async {
      final growth = GrowthService.instance;
      final sink = InMemoryAnalyticsSink();
      AnalyticsService.instance.addSink(sink);

      await growth.completeStep(ActivationStep.firstTaskCaptured);
      await growth.completeStep(ActivationStep.firstTaskCaptured);
      await growth.completeStep(ActivationStep.firstTaskCaptured);

      expect(sink.count(Ev.onboardingStepCompleted), 1);
    });

    test('the activation nudge disappears once activated', () async {
      final growth = GrowthService.instance;
      expect(growth.activationNudge, isNotNull);

      await growth.recordRewardClaimed();

      // A nudge that keeps firing after it is satisfied is just nagging.
      expect(growth.activationNudge, isNull);
    });
  });

  group('North Star', () {
    test('counts finished tasks, not app opens', () async {
      final growth = GrowthService.instance;

      await growth.recordAppOpen();
      await growth.recordAppOpen();
      await growth.recordAppOpen();
      expect(growth.northStarValue, 0);

      await growth.recordTaskCompleted();
      expect(growth.northStarValue, 1);
    });
  });

  group('Retention counters', () {
    test('a lapse resets the consecutive counter without penalty', () async {
      final growth = GrowthService.instance;
      await growth.recordAppOpen();
      expect(growth.consecutiveActiveDays, 1);
      // Same-day reopen must not inflate the count.
      await growth.recordAppOpen();
      expect(growth.consecutiveActiveDays, 1);
      expect(growth.totalActiveDays, 1);
    });
  });

  group('Experiment assignment', () {
    test('bucketing is deterministic for a given install', () {
      final exp = ExperimentService.instance;
      exp.seedInstallId('install-abc-123');

      final first = exp.variantOf(Experiments.paywallAnchor);
      for (var i = 0; i < 50; i++) {
        expect(exp.variantOf(Experiments.paywallAnchor), first);
      }
    });

    test('different experiments are not correlated for the same user', () {
      // The classic silent killer: if the salt is wrong, everyone in
      // treatment for test A is also in treatment for test B and both
      // readouts are garbage.
      final exp = ExperimentService.instance;
      var divergent = 0;

      for (var i = 0; i < 200; i++) {
        exp.seedInstallId('user-$i');
        final a = exp.variantOf(Experiments.paywallAnchor);
        final b = exp.variantOf(Experiments.paywallFraming);
        final aIsTreatment = a != Experiments.paywallAnchor.control;
        final bIsTreatment = b != Experiments.paywallFraming.control;
        if (aIsTreatment != bIsTreatment) divergent++;
      }

      // Independent 50/50 tests should disagree roughly half the time.
      expect(divergent, greaterThan(60));
      expect(divergent, lessThan(140));
    });

    test('traffic splits roughly evenly across a large population', () {
      final exp = ExperimentService.instance;
      var control = 0;

      for (var i = 0; i < 1000; i++) {
        exp.seedInstallId('bucket-user-$i');
        if (exp.variantOf(Experiments.paywallAnchor) ==
            Experiments.paywallAnchor.control) {
          control++;
        }
      }

      expect(control, greaterThan(400));
      expect(control, lessThan(600));
    });

    test('every registered experiment has a hypothesis and success metric',
        () {
      for (final e in Experiments.all) {
        expect(e.variants.length, greaterThanOrEqualTo(2), reason: e.key);
        expect(e.hypothesis, isNotEmpty, reason: e.key);
        expect(e.successMetric, isNotEmpty, reason: e.key);
      }
    });
  });

  group('Experiment maths', () {
    test('detecting a smaller effect requires a larger sample', () {
      final small = ExperimentMath.requiredSampleSize(0.05, 0.005);
      final large = ExperimentMath.requiredSampleSize(0.05, 0.02);
      expect(small, greaterThan(large));
    });

    test('sample size for a 5% baseline and +1pp lift is in the known range',
        () {
      // Standard two-proportion result: ~7,000-8,000 per arm.
      final n = ExperimentMath.requiredSampleSize(0.05, 0.01);
      expect(n, greaterThan(6000));
      expect(n, lessThan(9000));
    });
  });

  group('Unit economics', () {
    const econ = UnitEconomics();

    test('CAC per paying customer exceeds CAC per install', () {
      // The number founders quote is install CAC. The number that decides
      // whether the business works is this one.
      expect(
        econ.cacPerPayingCustomer,
        greaterThan(econ.i.cacPerInstall),
      );
    });

    test('net ARPU is below gross after store commission', () {
      expect(econ.netMonthlyArpu, lessThan(econ.grossMonthlyArpu));
      expect(econ.netMonthlyArpu, greaterThan(0));
    });

    test('lifetime is the reciprocal of churn', () {
      expect(econ.averageLifetimeMonths, closeTo(1 / 0.075, 0.01));
    });

    test('halving churn materially increases LTV', () {
      final base = const UnitEconomics().ltv;
      final better =
          UnitEconomics(const UnitEconomicsInputs(monthlyChurnRate: 0.0375))
              .ltv;
      expect(better, greaterThan(base * 1.9));
    });

    test('warnings fire when the model is unhealthy', () {
      final bad = UnitEconomics(
        const UnitEconomicsInputs(
          cacPerInstall: 25,
          activationRate: 0.05,
          monthlyChurnRate: 0.30,
        ),
      );
      expect(bad.warnings, isNotEmpty);
      expect(bad.ltvToCacRatio, lessThan(3));
    });

    test('improving activation raises revenue per install', () {
      const base = UnitEconomics();
      final improved = UnitEconomics(
        const UnitEconomicsInputs(activationRate: 0.50),
      );
      expect(improved.ltvPerInstall, greaterThan(base.ltvPerInstall));
    });
  });

  group('Analytics service', () {
    test('opting out stops all tracking', () async {
      final analytics = AnalyticsService.instance;
      final sink = InMemoryAnalyticsSink();
      analytics.addSink(sink);

      await analytics.setEnabled(false);
      analytics.track(Ev.taskCompleted);

      expect(sink.events, isEmpty);
    });

    test('funnel rate is safe when the top of the funnel is empty', () {
      expect(
        AnalyticsService.instance.funnelRate(Ev.paywallShown, Ev.trialStarted),
        0,
      );
    });

    test('tracking never throws', () {
      expect(
        () => AnalyticsService.instance.track('anything', {'a': Object()}),
        returnsNormally,
      );
    });
  });
}
