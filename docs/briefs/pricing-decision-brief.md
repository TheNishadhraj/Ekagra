# Pricing Decision Brief (WI-3.2) — owner decision, pricing NOT changed

**Status:** brief only. Per the owner's instruction (`defer_pricing`), no
price, product, or store constant was modified in this phase.
`lib/config/constants.dart` is untouched; RevenueCat is NOT added yet.

## Recommendation (research-synthesized, one decision to make)

| Item | Recommendation | Why |
|---|---|---|
| Monthly | **$5.99/mo** | Inside the $3–10 ADHD-app band; below Sunsama ($16–20); far below Inflow ($47.99/mo — an outlier positioned against human coaching, not apps) |
| Annual | **$49/yr** (~$4.08/mo, 32% off) | Standard anchor; makes monthly look like the impulse option and annual like the calm one |
| Trial | **7 days** | Category norm (~70% of productivity apps offer trials) |
| Parity | **Same price both stores** | The unexplained iOS/Android price gap is a named Finch complaint |
| Free tier | Unchanged | One Thing + timers + dopamine menu stay free (ADR-002: only `live` features may ever be billable — test-enforced) |

## The three marketing lines (direct answers to documented horror stories)

Publish verbatim on the paywall and store listing:

1. **"Trial ends {date} — we tell you in-app, not just by email."**
   (Finch Trustpilot 2.4: "a full year charged to my card… moved onto Plus
   without understanding".)
2. **"Cancel in-app, one tap."**
   (Tiimo: "accidentally ended up buying a subscription".)
3. **"One price, both stores."**

These are only publishable once true: in-app cancel link + trial-end
in-app notification must ship **with** the billing work, not after.

## Implementation order when the owner greenlights (est. 3–4 days + sandbox)

1. Add `revenuecat` package; wire ONLY `startTrial` / `purchase` seams in
   `monetization_service.dart` (the state machine is already right —
   assessment: "swapping RevenueCat in touches startTrial/purchase and
   nothing else").
2. Trial-end reminder: local notification at D-1 (reuse WI-1.4 nudge
   infra, ids ≥ 3000 to avoid collision) + paywall banner line 1.
3. In-app cancel: deep-link to platform subscription center.
4. Tests to extend in `test/monetization_test.dart`:
   - trial → active → expired → grace transitions;
   - non-billable-features-stay-free invariant (already exists — keep);
   - paywall renders **only `FeatureFlags … live`** features.
5. Store submission checklist: price parity, the three lines, screenshot
   of the in-app trial-end notice.

## Acceptance (unchanged from the work order)

Full purchase + cancel + trial-expiry flows work in sandbox; zero users
can be charged for a non-`live` feature (test-enforced).

## Why deferred

The owner chose to defer pricing this phase. Nothing in the current build
charges anyone (no store integration exists), so deferral has zero user
risk; the risk would be shipping prices without sandbox-tested flows —
exactly the trust failure this work item exists to prevent.
