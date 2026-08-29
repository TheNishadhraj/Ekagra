# Pre-Registered Pilot Protocol (WI-6.1)

**Version:** 1.0 · **Pre-registered:** 2026-08-26 · **Status:** ready to
recruit — no participant data collected yet.

This document is written BEFORE the pilot runs. That is the point: the
hypotheses, metrics, and analysis plan below are frozen now and cannot
be quietly changed after seeing the data. Any deviation gets logged as
an amendment with a reason.

## Purpose

No competitor in the shame-free/low-maintenance cluster has public
retention data. First with real numbers owns the narrative — and every
future DECISION gate gets data instead of taste.

## Design

- **N:** 20–50 ADHD adults (self-reported diagnosis or strong
  self-identification). Owner's network + a transparent r/ADHD launch
  post ("free for 4 weeks, we measure, you get feedback") + the ADHD
  Discord servers identified in research.
- **Duration:** 4 weeks per cohort.
- **Arms:** single-arm observational core + one embedded randomized
  nudge experiment (below). No placebo, no withheld core features:
  consent and honesty outrun experimental elegance (Spec Rule 14).
- **Compensation:** none (free Pro for the pilot window). No dark
  patterns at window end (Rule 8).

## Pre-registered hypotheses (frozen)

| # | Hypothesis | Metric | Success threshold |
|---|---|---|---|
| H1 | Nudges ON beat OFF for return | D7 return rate | ≥ +5 points |
| H2 | Decomposition users complete more | task completion rate, decomposition users vs non-users | ≥ +20% relative |
| H3 | Variable-ratio rewards drive return | D7 return of users with ≥1 claimed reward vs none | positive, report CI |
| H4 | Milestones lift week-4 return | D28 return, milestone-hit vs not | positive direction (exploratory, N small) |

Primary retention benchmarks (priors = category "strong performer",
NOT promises): **D1 ≥ 30% · D7 ≥ 15% · D30 ≥ 12%**.
Secondary: One-Thing adoption ≥ 50% of active days; focus completion
rate; reward claim rate.

## Embedded experiment

`nudge_on_vs_off` — 50/50 on installId hash (existing
`experiment_service.dart` bucketing; variant assignment already
deterministic and testable). Guardrails: opt-out rate, notification
permission grant rate. Minimum 30 participants/arm before any readout;
`Experiments.requiredSampleSize` is the calculator of record.

## Privacy (non-negotiable, test-enforced)

- Analytics opt-in on the existing opt-out architecture; local-only
  default.
- Zero PII in events: the sink's key-scrub + payload audit tests
  (`observability_test.dart`) are the gate, not a promise.
- The one qualitative question is asked in-app, answered anonymously,
  stored as free text without identifiers.

## Week-4 exit question (verbatim)

**"If you stopped using it, why — one word?"**
(Churn reasons = the next roadmap, in the users' own words.)

## Analysis plan

- Per-user unit; return = app_opened on/before day N since install.
- No peeking before full-cohort day 28 except a safety check at day 7
  (crash rate, opt-out spikes — harm monitoring, not efficacy).
- Report all four hypotheses regardless of outcome; nulls are results.
- Output document: `docs/audits/pilot-results.md` — methods, frozen
  hypotheses vs results, what we would change. Also the marketing
  asset.

## Dashboard (before first install)

Owner needs a read-out surface before recruiting. With no backend, the
honest V1 is an exported-events notebook: the WI-1.1 export (JSON) +
the PostHog project dashboard (free tier, configured per the
observability brief) cover cohort, retention, and funnel views without
new code. A in-app Growth Dashboard already exists for the user-side
view. Building a custom web dashboard would violate "no backend" —
explicitly out of scope.

## Remaining-work (needs owner/toolchain)

1. Recruit + post the launch copy (owner).
2. PostHog project creation + key entry (owner, 5 min — observability
  brief §setup).
3. CI activation so the suite actually gates (owner, 30 s —
  `ci/README.md`).
4. First green CI run retires `Engineering_Assessment.md` §6 caveat.
