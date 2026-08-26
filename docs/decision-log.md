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
