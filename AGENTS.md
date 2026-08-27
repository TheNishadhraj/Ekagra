# Ekagra Agent Working Agreement

## 1. The team

| Agent | Spec | Role |
|---|---|---|
| Elite Lean-Code Engineer | [`docs/agents/elite-lean-code-engineer.md`](docs/agents/elite-lean-code-engineer.md) | Parent reviewer: minimum justified complexity, deletion pass, dependency gate |
| Elite Flutter Principal Engineer | [`docs/agents/elite-flutter-principal-engineer.md`](docs/agents/elite-flutter-principal-engineer.md) | Flutter-stack child of the above: architecture/state, native integration, lifecycle, testing, build & release (deploys only with explicit owner approval) |

**Standing rule (owner instruction):** every proposed change or new code
in this repository passes the Lean-Code review discipline **before** it
is written, and Flutter-specific work additionally follows the Flutter
principal spec (conflict priority: security/platform policy → owner
requirements → repo compatibility → correctness → Flutter spec →
lean minimization). Use the parent's §24 template when starting
non-trivial work and its §23 contract when finishing.

The numbered agents (`docs/agents/01`–`04`) predate this agreement and
keep their original charters.

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
