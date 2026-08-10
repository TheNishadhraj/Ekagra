# Ekagra — Product, Growth & Monetization Strategy

**Companion to:** `Ekagra_Unified_Final_Specification.md`
**Status:** Engine shipped. Numbers below are modelled priors, not measurements.
**Code:** `lib/services/{analytics,experiment,monetization,growth,unit_economics}_service.dart`

---

## 0. The finding that drove this work

Before this change, Ekagra had a 3,683-line specification describing a
subscription business, and no subscription business:

| What the spec promised | What the code did |
|---|---|
| Free tier capped at 10 tasks | `atFreeTaskLimit` was defined and **never called anywhere** |
| 15 Pro features gated | **Zero** features gated — `grep isPro` in feature screens returned nothing |
| RevenueCat purchase flow | `enablePro()` set a bool. No purchase, no validation, no trial clock |
| 50+ analytics events | **Zero** implemented. No funnel was observable |
| Paywall trigger matrix (6 triggers) | One sheet, shown only from Settings |

The app was well-built and unmonetizable. Every user was a Pro user who
hadn't been asked to pay. **ARR was structurally $0 regardless of scale** —
you could have put 10 million users through it and earned nothing.

That is what this work fixes. Not a plan to fix it: the enforcement,
measurement and experimentation layers now exist and run.

---

## 1. Product strategy

**Positioning.** Ekagra is not a to-do app. To-do apps assume the hard part
is remembering; for ADHD the hard part is *starting*. Todoist, Things and
TickTick all optimise capture and organisation — the two things this user is
least helped by. Ekagra optimises the transition from intention to action.

**Job-to-be-done.** *"It's 2pm, I have eleven things in my head, I've been
avoiding all of them for three hours, and I need something outside my own
executive function to tell me what to do next and make starting feel
survivable."*

**Why the wedge is defensible.** The competitors cannot follow without
breaking their own product. A shame-free, choice-limited, reward-driven
interface is actively worse for a neurotypical power user who wants filters,
tags and bulk edit. Todoist adding a dopamine slot machine would confuse its
core base. This is a genuine positioning moat, not a feature gap.

### North Star Metric

```
FOCUSED TASK COMPLETIONS
= tasks finished after a focus session
```

Implemented as `GrowthService.northStarValue`.

Why not DAU, session count, or time-in-app: every one of those rewards us for
making an anxious person open an anxiety-management app more often. They can
all be gamed by making the product *stickier* rather than *better*. Focused
task completions can only rise when the product genuinely does its job —
which makes it safe to optimise hard against.

| Layer | Metric | Target |
|---|---|---|
| **North Star** | Focused task completions / active user / week | 5+ |
| Acquisition | Installs/day, organic share | 60%+ organic |
| **Activation** | % reaching first claimed reward | 35% → 50% |
| Engagement | Focus sessions started / active day | 1.8 |
| Retention | D1 / D7 / D30 | 45% / 25% / 12% |
| Revenue | Trial start rate, trial→paid | 22% / 45% |

### Guardrails (a "win" that moves these is not a win)

| Guardrail | Bar | Why it's here |
|---|---|---|
| D30 retention | Must not fall | Any monetization change that lifts conversion while dropping D30 is destroying LTV to book MRR |
| Paywall impressions/user/day | ≤ 2 (enforced in code) | `MonetizationService.maxPaywallsPerDay` |
| Rule-15 compliance | 100% | No shame copy anywhere, including paywalls |
| Crash-free rate | > 99.9% | Instrumentation must never crash the app — `track()` cannot throw |
| Analytics opt-out honoured | Always | `setEnabled(false)` halts all collection |

---

## 2. The aha moment (and why it isn't signup)

```
Install → Brain dump → Energy check → ONE thing → Focus → ★ REWARD ★
                                                            ↑
                                                    THE AHA MOMENT
```

Activation is defined as **claiming the first dopamine reward**
(`ActivationStepX.ahaMoment`). Everything before it is setup cost.

The reasoning: the user's lived experience is that starting tasks is
punishing and finishing them produces nothing. The first claimed reward is the
first time the loop pays them back — the moment the brain files "this app
works" instead of "this is another productivity app I'll abandon."

**This is the highest-leverage number in the business.** Activation multiplies
through the entire funnel:

```
Install → Paid = activation × trial-start × trial-convert
        = 0.35 × 0.22 × 0.45 = 3.47%
```

Raising activation 35% → 50% raises install→paid to 4.95% — a **43% revenue
increase with zero additional acquisition spend and no pricing change**
(LTV:CAC 0.80 → 1.15).
That is why onboarding work outranks paid-channel work right now.

---

## 3. Growth loops

Funnels leak and need constant refilling. Loops compound. Three are live or
one step from live:

### Loop 1 — Reward → Share → Install (viral, spec I4)

```
Complete task → Variable-ratio reward → ~5% rare drop
      ↑                                        ↓
      └── New user activates ← Install ← Shareable card
```

Rare drops are already implemented (`RewardEngine`, 5% chance). The share card
is spec'd but not built — this is the single highest-ROI unbuilt growth
feature. Rare drops are intrinsically shareable because they're *earned and
uncommon*, which is exactly the psychology that made Duolingo's streak
freezes and Spotify Wrapped spread.

Viral coefficient maths: `k = shares/user × conversion/share`.
At 8% share rate and 12% conversion, k = 0.0096 — small, but it lowers blended
CAC by roughly 1% permanently, and it compounds with the install base.

### Loop 2 — Body doubling (network effect)

```
More users in rooms → rooms feel alive → higher session completion
        ↑                                          ↓
        └────────── retention & word of mouth ─────┘
```

This is the strongest defensible loop and the clearest Pro justification: the
value is literally proportional to how many people pay for it. It's gated
(`PaywallTrigger.bodyDoubling`) but the gate is soft and browsing stays free —
an empty room shown to a free user actively damages the loop.

### Loop 3 — Data → Personalisation

```
Energy/mood check-ins → better ONE-thing selection → better outcomes
        ↑                                                    ↓
        └───────────── user checks in more ──────────────────┘
```

Already collecting (`EnergyProvider`, `MoodProvider`, now both instrumented).
The scoring in `AiService._score` uses it. This loop makes switching costs
real: a competitor starts from zero knowledge of your energy patterns.

---

## 4. Monetization design

### Model: Freemium subscription, contextually gated

Hybrid/ads were rejected outright. An interstitial ad in a focus app for
people with attention regulation disorders is a product contradiction, and it
violates Rules 12 and 15. This audience is also unusually willing to pay for
something that genuinely works, having usually tried and abandoned several
things that didn't.

### Pricing

| Plan | Price | Effective | Notes |
|---|---|---|---|
| Free | $0 | — | Genuinely usable forever. Not a crippled demo |
| Pro monthly | $7.99 | $7.99/mo | |
| Pro annual | $49.99 | $4.17/mo | **47.9% saving — verified by test** |

`monetization_test.dart` asserts the advertised saving is arithmetically
true. If someone changes a price and forgets the marketing copy, the build
fails rather than the app lying to users.

### Paywall triggers — and the governor

The spec listed six triggers. Six triggers with no coordination is how you
build a nag machine. `MonetizationService.shouldShowPaywall()` enforces:

| Rule | Value | Rationale |
|---|---|---|
| Soft cooldown | 20 hours | Never twice in a day |
| Daily cap | 2 | Across *all* triggers |
| Backoff | Retire trigger after 3 dismissals | Three "no"s is an answer |
| Hard gates exempt | `taskLimit` only | A real metered ceiling must explain itself |
| Subscribers | Never shown anything | Obvious, frequently got wrong |

Every suppression is logged (`Ev.paywallSuppressed`) so we can measure the
revenue we're deliberately declining and confirm it's buying retention.

**Why this raises revenue rather than lowering it.** Conversion is a function
of relevance, not frequency. Showing a body-doubling paywall to someone who
just hit a task ceiling converts near zero and costs trust. The audience is
RSD-sensitive; a nagging paywall doesn't produce a grudging subscriber, it
produces an uninstall and a one-star review. App Store rating is itself an
acquisition input.

### Ethical lines held

| Common dark pattern | Lift | Our call |
|---|---|---|
| Hidden annual auto-renew | +15-20% trial starts | **No.** Exact date and amount shown |
| Cancellation maze | +10% short-term retention | **No.** One tap, Settings → Cancel |
| Instant access revocation on cancel | — | **No.** Access to period end |
| Fake "3 spots left" scarcity | +8-12% | **No.** It's a subscription; the claim is a lie |
| Pre-checked annual upsell | +5% | **No.** Selection is explicit |
| Blocking capture at the limit | — | **No.** We save what fits and say so plainly |

That last one matters most. When a free user dumps 25 tasks with 10 slots, we
save 10 and tell them honestly. Refusing to store someone's thoughts because
they crossed a billing threshold — in an app whose entire purpose is getting
thoughts out of their head — would be the most damaging possible choice.

---

## 5. Unit economics

Modelled in `unit_economics.dart` with tests. Current priors:

| Input | Value |
|---|---|
| CAC / install | $2.40 |
| Activation | 35% |
| Trial start | 22% |
| Trial → paid | 45% |
| Monthly churn | 7.5% |
| Annual mix | 40% |
| Store commission | 30% |
| Cost to serve | $0.35/mo |

**Derived:**

| Output | Value | Bar | Status |
|---|---|---|---|
| Install → paid | 3.46% | — | |
| **CAC per paying customer** | **$69.26** | — | The number that matters |
| Gross ARPU | $6.46/mo | — | blended monthly + annual |
| Net ARPU | $4.17/mo | — | after 30% store fee + $0.35 serving |
| Avg lifetime | 13.3 months | — | 1 / churn |
| **LTV** | **$55.63** | — | |
| **LTV:CAC** | **0.80:1** | > 3:1 | ❌ **Do not scale paid** |
| Payback | 16.6 months | < 12 | ❌ |

**Read that honestly: at these assumptions we lose $13.63 on every paying
customer acquired, and take 16.6 months to recover a cost we never fully
recover.** The model surfaces this automatically via
`UnitEconomics.warnings`, and the Growth Console shows it in-app.

Note the gap between the two CAC numbers — $2.40 per install versus $69 per
paying customer. Install CAC is the number that gets quoted in decks; the
second is the one that decides whether the business works.

### What actually fixes it

| Lever | Change | LTV:CAC | Why |
|---|---|---|---|
| Baseline | — | 0.80 | |
| Activation 35→50% | onboarding work | 1.15 | multiplies the whole funnel |
| Churn 7.5→5% | retention work | 1.20 | lifetime 13.3→20 months |
| Both | | 1.72 | |
| **Both + blended CAC $2.40→$1.30** | share loop, ASO, organic mix | **3.18** ✅ | the only combination that clears the bar |

**The conclusion is unambiguous and it is the opposite of what most teams do:
do not spend on acquisition yet.** Fix activation, then retention, then lean
on organic. The unit economics only work when the product works first.

---

## 6. Experiment roadmap

Five experiments registered in `Experiments.all`, each with a hypothesis,
success metric and guardrails encoded in the source.

| # | Experiment | Variants | Hypothesis | Priority |
|---|---|---|---|---|
| 1 | `paywall_timing_v1` | onboarding / post_first_value | Deferring until after first value raises trial→paid | **Highest** |
| 2 | `free_task_limit_v1` | 10 / 20 | Higher ceiling raises D7 enough to raise net conversion | High |
| 3 | `paywall_anchor_v1` | monthly_first / annual_first | Annual anchoring lifts annual mix and LTV | High |
| 4 | `trial_length_v1` | 7 / 14 days | Longer trial suits bursty ADHD usage | Medium |
| 5 | `paywall_framing_v1` | value / reciprocity | Reciprocity beats feature grids for this audience | Medium |

**Sample size discipline.** `ExperimentMath.requiredSampleSize(0.05, 0.01)`
returns 7,458 per arm to detect +1pp on a 5% baseline. At 500 eligible
users/day that's 30 days for one two-arm test. This is the most commonly
skipped step in consumer growth, and skipping it means shipping noise as
insight.

**Assignment correctness.** Bucketing is FNV-1a over `installId:experimentKey`.
The per-experiment salt is not cosmetic: without it, users in treatment for
test A are systematically in treatment for test B, and every concurrent
readout is confounded. `growth_test.dart` asserts independence across 200
simulated users and even splits across 1,000.

---

## 7. What to build next

Ordered by expected impact on the LTV:CAC gap, not by effort.

### Phase 1 — Activation (weeks 1-4) · target 35% → 50%
1. **Time-to-first-reward instrumentation** — infrastructure now exists; find the drop-off
2. **Guided first session** — carry the user to the aha moment in one unbroken flow
3. **Ship experiment #1** (paywall timing) — likely the single biggest conversion win
4. **Activation nudge on Home** — `GrowthService.activationNudge` is written and unused

### Phase 2 — Retention (weeks 5-8) · target churn 7.5% → 5%
5. **Notification engine** (Spec M) — biggest untapped retention lever, discipline rules already spec'd
6. **Widgets** (Spec L) — a Pro feature that *also* drives free-user retention
7. **Winback offer** — `PaywallTrigger.winbackOffer` exists, needs the 48h trial flow

### Phase 3 — Organic (weeks 9-12) · target 60% organic
8. **Shareable rare-drop cards** (Spec I4) — closes the viral loop
9. **ASO** — screenshots leading with the ONE-thing card, not a feature grid
10. **Referral** — `Ev.referralInviteSent` reserved

### Deliberately deferred
- Paid acquisition — economics don't support it yet, and scaling a leaky bucket burns cash faster
- Real RevenueCat — swap in at `MonetizationService.startTrial/purchase`; the state machine is already correct and tested
- Backend analytics sink — attach any vendor via `AnalyticsService.addSink()`; no screen changes needed

---

## 8. Verifying it works

```bash
flutter test                    # 40+ assertions across the growth stack
flutter test test/monetization_test.dart
```

The tests encode business rules, not implementation details:
- Corrupt entitlement state fails **closed to free**, never open to Pro
- Cancellation preserves access to period end
- The paywall governor cannot be made to nag
- Advertised annual savings are arithmetically true
- Experiment arms are independent and evenly split
- Free-tier truncation saves what fits rather than rejecting the batch

In-app: **Settings → Growth Console** shows the North Star, activation ladder,
funnel rates, live variant assignments (with QA overrides) and the unit
economics model with warnings. It reads local state only — works offline,
leaks nothing.

---

## 9. Honest risk register

| Risk | Assessment |
|---|---|
| **All economics inputs are priors, not measurements** | Every number in §5 is an assumption. The model is a decision framework, not a forecast. Replace inputs with real data before trusting any output |
| Free tier may be too generous | 10 tasks + full timeline may be enough for many users forever. Experiment #2 tests it. Watch for high retention with flat conversion |
| Body doubling is simulated | Room counts are hardcoded. Gating a fake feature is defensible only briefly — build it or ungate it |
| ADHD audience has above-average churn | Bursty usage is inherent, not a product failure. Annual mix and pause-don't-cancel matter more here than elsewhere |
| Analytics are local-only | No sink is attached in release. Nothing reaches a dashboard until one is wired |
| Governor may over-suppress | 2/day + 3-strike backoff is deliberately conservative. `Ev.paywallSuppressed` measures the cost — tune with data, not instinct |
```
