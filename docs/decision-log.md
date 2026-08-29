# Decision Log

Architecture and product decisions are recorded here so the *why* survives long after the people who made it have moved on. Each entry is dated, states the alternatives considered, and marks whether the decision is **reversible** (move fast, log it, move on) or **irreversible** (slow down, brief the human, get consent).

---

## ADR-001 — Persistence: quarantine-over-delete with per-record decoding

**Date:** 2026-08-10
**Status:** Accepted
**Reversible:** No (data format change)

### Context
All five state providers called `jsonDecode(raw) as List<dynamic>` with no error handling, inside `load()` methods that `main()` awaits *before* `runApp()`. One malformed record — a partial write from a force-quit, schema drift, an OS truncation — threw during startup and prevented the app from ever rendering. The user's only remedy was uninstalling, which destroyed everything.

For an app whose purpose is holding the thoughts an ADHD user cannot hold themselves, this was the most severe failure mode in the codebase.

### Decision
Introduced `SafeStore` (`lib/utils/safe_store.dart`):
- Decode element-by-element so one bad record does not discard the other 200 good ones.
- Quarantine unreadable payloads to a sidecar key (`__corrupt`) for recovery rather than silently deleting them.
- Report failures via `Ev.errorOccurred` instead of swallowing them.

### Alternatives considered
- **`try { } catch { return []; }`** — rejected. Silently discarding a user's tasks is the second-worst outcome after crashing.
- **Schema-versioned migrations** — deferred. Correct future work, but does not fix the immediate crash-on-corruption.

### Consequences
- App now boots with whatever it can parse; corrupt records are preserved for recovery.
- Adds a small amount of decode overhead (negligible at current data volumes).

---

## ADR-002 — Monetization: non-billable features stay free

**Date:** 2026-08-10
**Status:** Accepted
**Reversible:** Yes

### Context
Body doubling displayed *"127 people focusing right now"* — a hardcoded literal with no presence service. It was put behind a paywall. Selling a subscription whose advertised benefit is fabricated data engages App Review 3.1.2, Play subscriptions policy, FTC Act §5, and the EU UCPD. The downside is not a refund queue — it is removal from the stores.

### Decision
Introduced `FeatureFlags` (`lib/config/feature_flags.dart`) declaring real maturity (`live` / `simulated` / `unbuilt`). `ProFeature.isBillable` gates `hasAccess()`: non-billable features are free for everyone, so the paywall and the product cannot drift apart by construction rather than by discipline.

### Alternatives considered
- **Gate everything and label it "preview"** — rejected. A paywall on a preview is still selling something that does not exist.
- **Build the backend first** — correct long-term, but V1.0 needs a monetization path now.

### Consequences
- Body doubling and widgets are free and honestly labelled until their backends ship.
- The paywall sheet advertises only features that actually exist in V1.0.

---

## ADR-003 — Design rules: encode as executable tests

**Date:** 2026-08-10
**Status:** Accepted
**Reversible:** Yes

### Context
The spec asks each PR to self-certify rule compliance via a checkbox. Checkboxes get ticked at 6pm on Fridays. `RsdSafeCopy.isSafe()` existed and was called from nowhere.

### Decision
`test/design_rules_test.dart` enforces Rules 3, 4, 5, 6, 8, 13, 14, and 15 against real user-facing strings. The suite found two live violations on its first run (including one introduced the commit before).

### Consequences
- Breaking a rule breaks the build mechanically, impersonally, every commit.
- The string extractor is deliberately conservative: it inspects strings reaching `Text`/`label`/`title`-style parameters, not every literal, to avoid noise that trains the team to ignore the check.

---

## ADR-004 — Honest monetization governance

**Date:** 2026-08-10
**Status:** Accepted
**Reversible:** Yes

### Context
The Growth & Monetization audit found 19 P0 findings. The single most important: the paywall described a product the user would not receive. Six of seven Pro features on the paywall were either absent, fabricated, or already free. The code crossed Boundary 4 on every claim.

### Decision
- Purged vapourware from paywall copy. Paywalls now advertise only features that exist in V1.0.
- Wired the soft task cap (`TaskProvider.atFreeTaskLimit`) into the brain dump flow: free users can create up to 10 active tasks; attempting an 11th raises the soft paywall sheet as an inviting prompt without brickwalling, deleting, or locking existing data (conforming to Rules 10 and 14).
- Added honest local trial tracking: `trialStartedAt` on `UserModel`, recorded by `SettingsProvider.enablePro()`, with `isTrialActive` and `trialDaysRemaining` getters.

### Alternatives considered
- **Ship V1.0 free, monetize in V1.1** — valid path, deferred to the human owner.
- **Full monetized launch with RevenueCat** — requires API keys, cost controls, PII boundaries, and a privacy review. Correct next step, but not a commit.

### Consequences
- Paywall copy now matches the actual product.
- Trial state is tracked locally and can surface "X days left" without a billing SDK.
- The soft cap converts without punishing.

---

## ADR-005 — Persist the in-flight focus session; reconcile on boot

**Date:** 2026-08-26
**Status:** Accepted
**Reversible:** Yes (additive keys; no existing format changed)

### Context
The wall-clock design already made timer *display* drift impossible
(`FocusSession.remaining()` is `endsAt - now`, Spec H3). But the in-flight
session, the day's focus minutes and the session's reward existed only in
`FocusProvider` memory. ADHD usage patterns — force-quits, OS memory
pressure, dead batteries — made silent loss a routine event, not an edge
case (Gap Solutions defect K20, RISK-09). A user who focused for 24 of 25
minutes and got a phone call that killed the app lost everything.

### Decision
- Persist the session (`ekagra_focus_session`) and the day's minutes
  (`ekagra_focus_today_minutes` + day marker) on every state transition.
- Run `FocusProvider.reconcile()` once at boot, after providers load:
  - session **ended while dead** → retro-complete once: minutes recorded,
    reward fired behind a per-session-id idempotency marker
    (`ekagra_focus_reward_fired_for`), `Ev.focusSessionReconciled` emitted;
  - session **still running** → restore and tick against the wall clock
    (zero drift by construction);
  - **paused** → restore paused;
  - **corrupt payload** → SafeStore quarantine path; the app boots.
- Day rollover: stored minutes belong to the stored calendar day;
  yesterday's minutes never leak into today.
- The user sees a one-tap acknowledgement on Home ("Focus finished while
  you were away — N minutes kept, nothing lost."), never an error.

### Alternatives considered
- **Persist a full session history** — worthwhile later (stats, export
  parity), deliberately out of scope: this ADR fixes loss, not reporting.
- **Reconcile inside `load()`** — rejected; reconciliation needs task and
  reward providers, and `main()` sequencing keeps that coupling explicit.

### Consequences
- A process kill can no longer lose a session, minutes, or a reward.
- New analytics event `focus_session_reconciled` (separate from
  `focus_session_completed` so dashboards can tell them apart). This is the
  only new event; logged here per the work order's documentation duty.
- Reward idempotency is enforced for the reconcile path; the live path
  already fires rewards from UI completion exactly once.

---

## ADR-006 — Body doubling ("Focus Caves") stays unbuilt this phase

**Date:** 2026-08-26 · **Status:** accepted · **Work item:** Phase 4

### Context
The work order allows body doubling "at agent discretion, explicitly
reported." A real room product needs (a) presence infra (LiveKit self-host
~$60–200/mo at ~200 concurrent, or Cloud ~$50/mo — RISK-13), (b) a
moderation spec that lands **before** code (ToS, report flow to a human
queue, avatar mode, join rate limits, no DMs in V1 — RISK-12), and
(c) owner spending approval — which the standing constraints withhold
("no buying anything", no monetization moves without the owner).

### Decision
Cut from this phase; nothing ships, not even a "coming soon" surface
(K18 pattern is a release blocker). What Phase 4 ships instead is the
**asynchronous** body-doubling seam that already exists honestly:
focus sessions with visible elapsed progress, reward celebrations on
completion, and nudge copy that says "someone is cheering" only in the
generic sense. The rebuild checklist (pre-registered in RISK-12/13):
1. Moderation spec merged before any room code.
2. LiveKit self-host vs Cloud decision with a cost ceiling.
3. Avatar-first presence (camera optional, off by default).
4. Room cap + join rate limits; no DMs in V1.
5. Feature flag `bodyDoubling` at `unbuilt` until all of the above.

### Consequences
No social surface exists, so RISK-12/13 stay dormant by construction.
If the owner wants Caves, the checklist above is the entry fee — not a
weekend build. This ADR exists so the risk register's references to
"the Phase-4 cut" resolve to a real decision record.


---

## ADR-007 — Task decomposition: additive schema + one-step execution

**Date:** 2026-08-26 · **Status:** accepted · **Work items:** WI-3.1

### Context
WI-3.1 replaces the dishonest "AI breakdown" (canned templates dressed
as intelligence, `simulated`) with a real, local, honestly-labelled
decomposer: 32 template families × 3 spiciness tiers as **data**
(`assets/templates/task_breakdown_templates.json`, owner-tunable
without a release), generic 2-minute-rule fallback, and a one-step-
at-a-time execution mode fused with the reward engine.

### Decision
1. **Schema (the persistence change this ADR covers):** `TaskModel`
   gains two **additive, optional** fields — `stepStates:
   List<String>` (`'done'`/`'skipped'`, parallel to `subtasks`) and
   `spiciness: String?`. Old payloads decode with defaults (missing →
   empty → "no progress recorded"); `toJson` writes them harmlessly
   for older readers to ignore. No key is renamed or removed; the
   SafeStore per-record decode/quarantine path is untouched.
2. **Execution mode:** task detail shows exactly ONE current step
   ("Done with this step" / "Skip step" / "See all steps" — the
   three-choice budget). Full list is a deliberate toggle away.
3. **Reward fusion:** a done step fires `rollQuick` (quick-tier only,
   excluded from the variable-ratio roll — scarcity stays reserved for
   whole-task completion). `completeTask` is now idempotent so the
   completion reward can never double-fire.
4. **Honesty:** label is "Break it down 🌶️" + "built from patterns,
   runs on your phone — no cloud, no account." Every template step
   string is shame-scanned by `design_rules_test` like any UI copy.
   `FeatureFlags.aiTaskBreakdown` moves `simulated → live` (it now
   fronts the real local decomposer; name kept for the paywall matrix).

### Alternatives considered
- **On-device LLM (Gemini Nano / whisper-style local model):** real AI,
  but a multi-hundred-MB model or new native deps — outside this
  sandbox's toolchain and unjustified for list generation. The template
  approach is deterministic, auditable, and editable by the owner.
- **Extending `AiService.breakdownTask`:** keeping the fake seam would
  preserve the dishonest name; the decomposer is a separate, honest
  service instead.

### Consequences
- Risk: template data drift (bounds, tone) — mitigated by two tests
  (`decomposition_test` bounds check; `design_rules_test` shame scan).
- Risk: step/reward double-fire — mitigated by idempotent
  `completeTask` + exactly-once assertion in tests.
- Registered as RISK-17.

---

## ADR-008 — Onboarding reflow: 3 effective steps, real notifications, no paywall route

**Date:** 2026-08-26
**Status:** Accepted
**Reversible:** Yes

### Context
Research (Goblin Tools: "most productivity apps lose ADHD users during
onboarding"; Finch billing-trap reviews) plus defects K18/K19 made the old
4-step onboarding indefensible: a dopamine-menu questionnaire the user had
no stake in yet, a notifications screen promising nudges that did not
exist, and a full-screen paywall before the user had felt any value —
contradicting the no-pressure brand while the soft task cap
(`TaskProvider.atFreeTaskLimit`) already converts at the moment of value.

### Decision
1. **Dopamine Menu is one tap by default.** Pre-filled from
   `DopamineMenu.defaults`; tuning is an optional disclosure on the same
   screen and remains reachable in Settings. Effective steps: ADHD type
   (feeds the scorer), dopamine (one tap), notifications (real).
2. **Notifications step is real** (requires WI-1.4): it requests the OS
   permission, arms the daily brief, and its "later" path leaves
   notifications fully off (Rule 11).
3. **The onboarding paywall route is removed**
   (`paywall_screen.dart` deleted; `AppRoutes.paywall` no longer exists).
   Conversion remains with the contextual soft cap + `EkagraPaywallSheet`.
   `PaywallTrigger.onboarding` stays in the enum (append-only event/enum
   discipline) but is no longer reachable from the UI.
4. **Welcome-back state:** after a ≥3-day gap with content, one gentle
   screen — "Nothing was lost." — shown at most once per gap, measured
   against the previous active day captured before today's touch.
5. `Experiments.paywallTiming` ('onboarding' vs 'post_first_value') is
   retired in effect: its treatment arm is now the only behaviour. The
   registration is kept for history; do not re-arm it without revisiting
   this ADR.

### Alternatives considered
- **Keep the paywall behind an experiment flag** — rejected: a paywall
  reachable during onboarding contradicts Rule 8's spirit even at 50%
  traffic, and the experiment's premise (ask before value) is what the
  evidence refutes.
- **Ask for notifications pre-permission at first launch** — rejected:
  consent before explanation is the dark-pattern flavour of permission
  requests.

### Consequences
- Onboarding completes in ~2 minutes with every step skippable.
- "Gentle nudges" copy in onboarding is finally true (WI-1.4 engine).
- One conversion moment is deliberately given up (onboarding paywall) in
  exchange for brand coherence; the soft cap is the surviving conversion
  surface and is measured by the existing paywall analytics.

---

## ADR-009 — Observability: dependency-free HTTP sink + seam-level crash capture

**Date:** 2026-08-26
**Status:** Accepted (vendor key pending owner — see the brief)
**Reversible:** Yes

### Context
RISK-05/08: no analytics sink and no crash reporting. The bus
(`AnalyticsService`, append-only `Ev.*` registry, opt-out, crash-safe local
buffer) was built deliberately vendor-free with an `addSink()` seam. The
work order asks for a real sink + crash reporting; the vendor choice is an
owner decision and the implementation sandbox had no pub.dev access anyway.

### Decision
- `RemoteAnalyticsSink`: one-file HTTP implementation of the PostHog batch
  capture API. Config in `lib/config/observability_config.dart`; **empty
  key = inert = fully offline build**. Batches ≤40 events / 30 s; failures
  are silent drops (the local buffer is the durable record).
- `CrashReporter`: `FlutterError.onError`, `PlatformDispatcher.onError`
  and a `runZonedGuarded` boundary in `main()` all convert to
  `Ev.errorOccurred` — inheriting consent, scrubbing and buffering.
- PII scrubbing at the sink (key-pattern drop) and consent gating at the
  bus are test-enforced, not aspirational.
- No new events were added by this ADR (it only consumes existing ones).

### Alternatives considered
- **Vendor SDKs now (posthog_dart / sentry_flutter)** — deferred to the
  owner brief: adds dependencies that could not be resolved or honestly
  verified in the authoring environment, and the seam makes the swap a
  one-file change later.
- **Firebase Analytics** — rejected for now: pulls the Firebase init
  surface into an offline-first app before any user exists.

### Consequences
- With a key configured, funnels/retention dashboards work day one of the
  pilot; without one, everything still lands in the local buffer.
- Native-crash symbolication remains open (RISK-10 residue) until the
  Sentry/Crashlytics decision.

---

## ADR-010 — Retention program: active-day milestones (additive growth key)

**Date:** 2026-08-26 · **Status:** accepted · **Work items:** WI-5.3
**Reversible:** Yes (drop the key; nothing else reads it)

### Context
Anti-novelty-decay (WI-5.3) needs fire-once milestone celebrations at
7/30/100 active days. "Days showing up" is a **total**, never a
consecutive streak (Spec Rule 4) — a gap must never cost progress.

### Decision
`GrowthService`'s existing SharedPreferences JSON gains one additive
key, `celebratedMilestones: List<int>` (default `[]` when absent —
legacy payloads decode unchanged). `recordAppOpen` arms
`pendingMilestone` at most once per milestone; `MainShell` shows
`MilestoneSheet` post-frame once and clears it either way (celebrated
or dismissed — the day is marked either way, so it can never nag).
Celebrating rolls a **forced-rare** reward (`RewardEngine.rollRare`,
added WI-3.1) and routes to the existing reveal screen.

Also in WI-5.3 (no persistence impact): hyperfocus celebration copy on
the focus-complete screen (≥120 min, celebration never scolding);
`MenuRefreshService` (pure, deterministic monthly suggestions — the
saved menu is the only state); weekly nudge-copy rotation shipped with
WI-1.4; experiments `milestone_tone_v1` and `menu_refresh_count_v1`
registered in `Experiments`. All gated by
`FeatureFlags.retentionProgram = live` (local, real, honest).

### Consequences
- One more JSON key in a prefs blob the app already owns; SafeStore
  per-record quarantine does not apply (plain prefs), legacy-decode is
  test-enforced.
- Failure mode: a milestone armed but the app killed before the sheet —
  it simply shows on the next open (pending survives via in-memory +
  celebrated-set persistence only after clearing; acceptable).
- Registered as RISK-18.
