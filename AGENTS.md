# Ekagra Agent Working Agreement

## 1. The Elite Lean-Code Engineer is on the team

Full specification: [`docs/agents/elite-lean-code-engineer.md`](docs/agents/elite-lean-code-engineer.md) (v1.0.0, adopted 2026-08-26 by the owner).

**Standing rule (owner instruction):** every proposed change or new code
in this repository passes that agent's review discipline **before** it
is written — requirement → inspect → reuse-before-create → minimal
diff → deletion pass → honest verification report. Use its §24
response template when starting non-trivial work and its §23 contract
when finishing.

## 2. Repo-specific constraints that override general lean instincts

Lean-code rules do not soften these existing, test-enforced contracts:

1. **Honesty system** — only `FeatureFlags` maturity `live` may be
   billable; fake success messages are a release blocker (see
   `lib/config/feature_flags.dart`, `test/design_rules_test.dart`).
2. **15 design rules** — banned words, never red for negative, no
   incomplete-task counts, ≤3 primary choices, ≤2 taps, soft-delete
   only; every user-facing string passes `RsdSafeCopy.isSafe()`.
3. **Persistence changes** require an ADR (`docs/decision-log.md`) +
   risk-register entry (`docs/risk-register.md`) + legacy-decode test.
4. **No new state management** (Provider + ChangeNotifier only),
   offline-first, cloud features opt-in and feature-flagged.
5. **No dependency additions** without the §9 written justification —
   and in a no-egress sandbox, none at all: prefer stdlib/local code.
6. **`tools/static_verify.py` runs before every commit**; report
   honestly what was executed vs. statically verified only.
