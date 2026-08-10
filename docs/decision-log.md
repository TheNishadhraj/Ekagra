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
