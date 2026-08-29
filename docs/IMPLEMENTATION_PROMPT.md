# Ekagra — Gap Solutions Implementation Prompt

**How to use:** paste this entire document to your coding agent (or save it as `docs/IMPLEMENTATION_PROMPT.md` in the repo and reference it). It is self-contained: an agent with repo access + this prompt should need no other context. Research artifacts it references live in `/home/user/research-ekagra/` if available: `ekagra-deep-research-report.md`, `ekagra-sentiment-competitor-fit.md`, `ekagra-gap-solutions.md`, `evidence-ledger-v4.md`.

---

## 0. You, your role, and your mission

You are the implementation agent for **Ekagra**, a pre-launch, offline-first Flutter app (iOS + Android) for adults with ADHD. It has been through three levels of external research (L1 code verification, L2 deep research, L3 sentiment + competitor + solution design). This document is the **complete, evidence-backed work order** that turns those findings into shippable product.

Your mission, in one line: **make Ekagra honest, make it come to the user, and make the user come back — without breaking the design system that is its entire brand.**

Non-negotiables (violation = failed work, regardless of how good the code is):

1. **Boundary 4 (honest monetization):** never advertise, simulate, or imply a feature that does not exist. The FeatureFlags maturity model (`live` / `simulated` / `unbuilt`) in `lib/config/feature_flags.dart` is the single source of truth; only `live` features may be billable. A fake success message is a ship-blocker, same class as a security bug.
2. **The 15 Non-Negotiable Design Rules** (spec: `docs/Ekagra_Unified_Final_Specification.md`, Section A1 — read it first; `lib/config/design_rules.dart` is the partial machine-enforced subset): shame-free copy. Forbidden words: `streak`, `overdue`, `failed`, `missed` (and anything the spec bans). No red for negative states (warm coral `0xFFFF8C6B` is the only "error" color). No task counts displayed. ≤3 primary choices per screen. Primary actions complete in ≤2 taps. Soft-delete/quarantine only, never destructive. **Every new user-facing string must pass `RsdSafeCopy.isSafe()` and be added to `test/design_rules_test.dart` coverage.**
3. **Offline-first:** core features work with zero network. Any cloud capability (LLM, billing verification, analytics) is opt-in, has a local fallback or honest "offline" state, and is gated by FeatureFlags.
4. **No new state-management paradigm.** Stay on Provider + ChangeNotifier. No Riverpod/BLoC migration. No new global store.
5. **Persistence changes require an ADR** in `docs/decision-log.md` (their format: Context / Decision / Alternatives / Consequences) and a risk-register entry where applicable.
6. **Tests before "done":** `flutter analyze --fatal-infos` clean, `flutter test` green, `dart format` clean. The CI gates in `ci/github-workflow-ci.yml` are the acceptance bar.

If you hit a decision this prompt marks **DECISION (owner)** — stop, write the brief in the requested format, and wait. Do not guess on: billing prices, body-doubling build/cut, any feature that would cost money, any schema change to persisted user data.

---

## 1. Product context (verified facts — do not re-litigate)

- **What it is:** a daily companion for adults with ADHD. Core loop: Brain Dump (capture) → "Pick One Thing" (offline deterministic scorer, `AiService` — genuinely NOT an LLM, and the app says so) → Focus Mode (wall-clock timer, `FocusSession.remaining()` is clock-based) → Dopamine Menu rewards (`RewardEngine`: 70/25/5 tier roll + independent 5% rare overlay) → Energy/Mood check-ins.
- **The differentiator:** the 15-rule shame-free system + honest monetization. The market research found **no competitor codifies this** (even Finch's 4.9★ users publicly ask for no-streak behavior). Protect it religiously.
- **Architecture:** Flutter, Provider/ChangeNotifier (6 providers in `lib/providers/`), `SharedPreferences` JSON persistence via `SafeStore` (`lib/utils/safe_store.dart` — per-record decode, quarantine to `__corrupt` sidecar, never destructive). 8 runtime deps. 16 test files. ~11.2k LOC.
- **Maturity (verified 2026-08):** pre-launch; no store presence of THIS app; no billing SDK; no notifications; no crash reporting; no analytics sink; CI unactivated (only stock `dart.yml`; real pipeline sits in `ci/` awaiting move to `.github/workflows/`).
- **Known defects this work order fixes:**
  - **K18 (P0-brand):** `lib/screens/settings/settings_screen.dart` (~lines 152–166) "Export My Data" shows "File saved locally" while writing nothing. Flagged `simulated` internally, no notice.
  - **K19 (P1):** `lib/screens/onboarding/notification_permission_screen.dart` promises "gentle nudges" with sample cards; the app has no notification capability; the button only sets a local flag.
  - **K20 (P2, unregistered):** in-flight `FocusSession` + `_todayFocusMinutes` are in-memory only; process kill silently loses session, minutes, and reward.
  - **Stale risk register:** RISK-02 (timer drift) describes an unimplemented fix that actually exists (wall-clock `remaining()`); the real gap is K20.
- **Repo conventions (follow exactly):** ADRs in `docs/decision-log.md` (ADR-00N format); risks in `docs/risk-register.md` (RISK-0N, P0–P3 severity); audits in `docs/audits/`; PR template asks humans to self-certify only rules 1, 2, 9, 10, 12 (CI proves the rest).

---

## 2. Why these gaps exist (the evidence, compressed)

Research across app-store reviews, 12+ Reddit threads, YouTube, TikTok, and press (full citations in the evidence ledger) established what ADHD users actually want, ranked: (1) break task paralysis, (2) frictionless capture (voice included), (3) make time visible, (4) **no guilt/no shame** (your strongest asset — even Finch users petition for it), (5) **stability / never lose my data / no logins** (Finch: "corrupts the app and loses all your data"; Tiimo: "things have disappeared from my schedule", "constantly logged out"), (6) low maintenance ("In two days I will forget I got the app" — top comment, 138 upvotes), (7) **real** body doubling (the highest willingness-to-pay niche, $0–35/mo, 10+ active platforms; community: it "requires the other person to actually be doing the thing"), (8) **an active sidekick that messages the user** ("the problem with every app is I need to be proactive… and I never am"), (9) focus audio + phone control, (10) complexity ceiling ("apps with so much stuff just don't work"), (11) **honest pricing** (Finch: 4.9★ App Store vs 2.4 Trustpilot — top complaint "a full year charged to my card"; Tiimo: "accidentally ended up buying a subscription"), (12) AI that helps without pushing (Inflow's top review: "I'm not interested in developing AI psychosis by using a validation bot as a therapist"), (13–14) medication support + widgets/watch, plus the structural fact: **novelty decay is a feature of this category, not a bug** — and **billing-trap horror stories are the loudest trust failure in the category**.

Ekagra's research-verified fit: **9/10** on the trust/stability/low-pressure cluster (unique at scale), **5/10** on execution (right bones, missing decomposition/voice/per-task timers), **2.5/10** on accountability (simulated body doubling, zero notifications, no blocking, no widgets). Everything is field-unproven: zero users.

---

## 3. Work order, by phase

Each work item (WI): **Goal → Implementation → Files → Copy → Tests → Acceptance.** All work is PR-sized. Update `docs/` per §4 after each WI.

### PHASE 0 — Baseline (before any feature work)

**WI-0.1 · Run the suite (the #1 open verification gap in the research)**
- Install current stable Flutter; `flutter pub get`; `flutter analyze --fatal-infos`; `flutter test`; record results.
- Fix whatever the first run surfaces (the repo's own assessment predicted "a small number of analyzer nits").
- Move `ci/github-workflow-ci.yml` into `.github/workflows/` (per `ci/README.md` — one manual step) so the gates run on every PR: format, analyze --fatal-infos, test, red-color grep, print() grep, release-APK build on PRs.
- **Acceptance:** green CI on the default branch; a short note appended to `docs/Engineering_Assessment.md` §6 recording that the suite has now been executed and what changed.

**WI-0.2 · Risk register hygiene**
- Rewrite RISK-02: drift is mitigated by wall-clock `remaining()` (cite `focus_session_model.dart`); replace with the real risk.
- Add RISK-09 (session loss on process kill → closed by WI-1.2), RISK-10 (no crash reporting → WI-2.3), RISK-11 (no analytics sink → WI-2.3).

---

### PHASE 1 — Week 1: honesty fixes + the sidekick v0

**WI-1.1 · Real data export (fixes K18 — do this first, it is a brand violation)**
- Goal: the "Export My Data" tile actually exports.
- Implementation: add `path_provider` + `share_plus`. On tap: serialize tasks, focus sessions, rewards, energy/mood logs to JSON (one human-readable file; optional CSV for tasks only) into the app's documents dir, then `Share.shareXFiles` with a fallback dialog ("Saved to your Files app" — true on Android; on iOS show the share sheet, which is the standard). Flip `FeatureFlags.dataExport` to `live` **only when the round-trip test passes**.
- Files: new `lib/services/export_service.dart`; edit `settings_screen.dart` tile handler (delete the fake SnackBar path); `feature_flags.dart`; `pubspec.yaml`.
- Copy: success = "📤 Exported. Share it or save it wherever you like." No invented claims.
- Tests: `test/export_test.dart` — write → read back → field parity; corrupted-model tolerance (reuse SafeStore helpers).
- **Acceptance:** exportable file on both platforms; `dataExport` = `live`; design-rules test still green.

**WI-1.2 · Persist in-flight focus sessions (fixes K20)**
- Goal: a process kill never silently loses a session, the day's minutes, or a reward.
- Implementation: serialize `FocusSession` (toJson exists) + `_todayFocusMinutes` to SharedPreferences on `start()`/`resume()`/`pause()`. On app boot (after `load()`): reconcile — if a persisted session's `endsAt` has passed while the app was dead → `complete()` retroactively (record minutes, fire reward, event `Ev.focusSessionReconciled`); if still running → resume the ticker against wall clock (no drift by construction).
- Write an **ADR-005** (reversible: yes) and close RISK-09 in the register.
- Tests: extend `test/resilience/` — kill scenarios: session ends while dead (reward fires once, idempotent), session running while dead (resumes correctly), corrupt session payload (SafeStore path).
- **Acceptance:** `flutter test` covers all three kill scenarios; no double-reward path (idempotency test).

**WI-1.3 · Onboarding reflow (fixes K19 + the "lost during onboarding" evidence)**
- Goal: 3 effective steps, ~2 minutes, zero billing, zero dead promises.
- Implementation:
  1. Keep Welcome+BrainDump and ADHD-type selection (the question feeds the scorer — it earns its place).
  2. **Dopamine Menu: skip by default** — pre-fill from `DopamineMenu.defaults` (exists), link "tune it later" in Settings. One tap to proceed.
  3. Notifications step becomes **real** (requires WI-1.4 engine; sequence accordingly): request permission with the existing "gentle nudges" copy — which finally means something.
  4. **Remove the paywall route from onboarding.** The soft cap at task 11 (`TaskProvider.atFreeTaskLimit`) already converts at the moment of value; onboarding paywalls contradict the no-pressure brand.
  5. Add a **welcome-back** state: reopening after ≥3 days with data shows one gentle screen: "Nothing was lost. Here's your one thing." (True only because of SafeStore — no competitor can say this.)
- Copy check: every string through `RsdSafeCopy`.
- Tests: widget test for each screen transition; default-fill assertion for dopamine menu.
- **Acceptance:** onboarding completes in ≤3 effective steps with all skips; no paywall reachable during onboarding.

**WI-1.4 · "Nudge" engine v0 (closes N8 — the #1 wishlist ask)**
- Goal: the app comes to the user. Gently. Persistently. Without spam.
- Evidence this design follows: ADHD working memory drops a swiped notification within seconds → one nudge is never enough; the working pattern is *gently recurring* nudges ("firm without guilt" — that is your brand voice); fewer-better reminders (alarm fatigue); action-oriented copy; escalation sequences build urgency; icon + ≤6 words outperforms paragraphs (2018 UO study: minimal text +25–30%, icons +18%); rotate copy/sound weekly to beat habituation.
- Implementation:
  - Add `flutter_local_notifications` (local-only; no backend; offline-first preserved).
  - New `lib/services/nudge_service.dart` with a per-task **NudgePolicy**: `{ firstAt, reNudgeMinutes: [10, 30], maxNudges: 3, action: deepLinkToTask }`. If the user opens the app / completes the task, cancel remaining. After `maxNudges`, **stop silently** (Rule 14: the system doesn't nag forever — it gives up gracefully, shame-free).
  - **Daily "One Thing" brief**: one opt-in notification per day (default ON), icon + ≤6 words + deep link to home.
  - **Transition alerts** from Day View: "15 min left — {task}" with action buttons [Continue] [Pause].
  - **Welcome-back nudge** (after ≥3 days, one-time per gap): "Nothing was lost. Your one thing is still here."
  - **Copy bank**: ≥3 rotations per nudge type, rotate weekly; all copy passes the forbidden-word test (say "still here", never "missed").
  - Opt-out tile in Settings next to the existing analytics opt-out ("Privacy-first" section).
- Tests: policy unit tests (max-nudges cap, cancellation on completion, timezone-safe scheduling), copy through `RsdSafeCopy`.
- **Acceptance:** a timed task produces at most 3 gentle notifications on both platforms; completing early cancels the rest; opt-out stops all.

---

### PHASE 2 — Weeks 2–3: capture + time visibility + observability

**WI-2.1 · Voice Brain Dump, "yap mode" (closes N2)**
- Evidence: "I just yap into it and it organizes my brain dump… having a record makes me feel at ease"; the privacy fear of cloud AI is the documented downside — on-device is the answer *and* the brand line.
- Implementation:
  - Add `whisper_ggml` (on-device whisper.cpp; verified maintained 2026: live streaming, models downloadable once **or shippable in assets for fully offline use**). Use `base` model; first-run model download with progress (respect the offline identity: once downloaded, zero network forever).
  - Brain Dump screen: long-press mic (or a "yap" toggle) → live transcript streams into the input → release → **parser** splits fragments into tasks using the existing quick-add templates + date detection ("tomorrow", "Thursday", "by Friday") → pre-filled task cards → **one tap confirms each** (2-tap rule) → existing celebration.
  - Privacy copy (put it in onboarding and settings): "Your words never leave this phone."
  - `feature_flags.dart`: new `voiceDump` flag → `live` on Android + iOS after both pass; `unbuilt` fallback shows the text input only.
- Tests: parser unit tests (date detection, fragment splitting, template matching, empty-garbage input); no network permission required in the test path.
- **Acceptance:** a 60-second spoken dump produces ≥N correctly parsed task cards on a mid-range Android device in <15s; fully offline after model download.
- DECISION (owner): bundle model in assets (+~140MB app size) vs first-run download. Default: first-run download.

**WI-2.2 · Per-task visual countdowns (closes N3)**
- Evidence: Time Timer is "the gold standard"; a shrinking disk conveys remaining time "without any cognitive processing" (a number like 23:47 forces arithmetic); countdown sequences (60/30/15/5) build the psychological reality of a deadline; Llama Life's entire product is "a countdown timer on one task at a time" and users report it changed their lives.
- Implementation:
  - **One active task at a time** (Llama Life's anti-overwhelm rule). From Day View, a task chip → "Make active" (1 tap).
  - Parameterize the existing `FocusRing` widget into a reusable **shrinking arc** bound to the task's estimate (wall-clock, reuses `FocusSession` math — no new timer model).
  - Estimate + **time padding**: when the user sets an estimate, offer "Add 50% buffer — your brain underestimates" (one tap, removable). The buffer is the documented ADHD estimation correction.
  - Color transitions at 25% and 10% remaining: **warm coral, never red** (Rule 3).
  - Optional 15/5-min transition alerts → feed WI-1.4 nudge service (not a parallel system).
- Tests: arc state at boundary percentages; only-one-active-task invariant; padding math.
- **Acceptance:** active-task countdown survives backgrounding with zero drift (wall-clock proof already in `FocusSession`); design-rules test green on new strings.

**WI-2.3 · Observability (closes RISK-05/08 — prerequisite for every later experiment)**
- Implementation: attach a real sink to the existing `AnalyticsService.addSink()` seam (the seam exists by design — choose PostHog free tier or Plausible Mobile; keep the existing in-app opt-out honored before the first event). Add Sentry **or** Crashlytics on the same seam for crash reporting. Events: the `Ev.*` enum already designed — no new event types unless a WI requires one (log any additions in the ADR).
- DECISION (owner): provider choice (both are ~$0 at this scale).
- **Acceptance:** a crash in debug reaches the dashboard; opt-out verified by test (zero events after toggle).

---

### PHASE 3 — Weeks 3–5: the execution gap + honest billing

**WI-3.1 · Task decomposition + one-step execution (closes N1/N12 — the most-cited community gap)**
- Evidence: Goblin's free "Magic ToDo" is the community gold standard (9/10 in reviews); **every** competitor review cites the same hole — "it stops at the plan… no timer, no guided execution, no 'show me one step at a time' mode"; granularity slider ("spiciness"): low = 3–5 steps, max = 15–20 micro-steps ("Pick up the sponge") — "for deep ADHD paralysis, maximum is often most helpful". Ekagra already owns the two halves (micro-commitment generation, spec F4; FocusRing timer) — this WI fuses them.
- Implementation:
  - New `lib/services/task_decomposer.dart` — **local, no network** (honest label everywhere it appears: "smarter list, not AI"):
    - Activity classifier over the task title (verbs/nouns → domain: clean, cook, study, errand, write, email, move, health, laundry, pay, call…).
    - ~30 template families × 3 spiciness levels (3–5 / 6–10 / 11–20 steps). Templates are data (JSON in assets), not code — owner-editable without a release.
    - Unknown task → generic scaffold: "Open what you need" → "Do the first 2 minutes" → "Check: done, or what's the next step?" (the 2-minute rule).
  - **Execution mode (the differentiator — nobody in the category has this fused with rewards):** the task sheet shows **ONE step at a time** with a per-step countdown (default 2–5 min, wall-clock). Primary view ≤3 choices: [Done with this step] [Skip step] [See all steps]. "Done" fires a **small-tier reward micro-tick** via `RewardEngine` and reveals the next step; finishing all steps fires the normal completion reward.
  - Spiciness control: 3-position slider ("Big steps / Normal / Tiny steps") on the breakdown sheet.
  - `feature_flags.dart`: `taskDecomposition` → `live` when templates + tests pass.
  - **V2 (do NOT build now):** opt-in cloud LLM for freeform tasks — only after owner approval, behind consent + cost controls + honest "AI (cloud, optional)" label. The market wants AI but fears pushiness (documented); opt-in + local-default is the positioning that wins both sides.
- Tests: classifier coverage for all template families + fallback; one-step state machine (done/skip/end); reward idempotency (no double-fire); spiciness step counts within bounds.
- **Acceptance:** "clean the kitchen" at max spiciness produces ≥10 ordered micro-steps, each completable in one tap; full completion fires exactly one completion reward.

**WI-3.2 · Billing, done honestly (closes N11)**
- Evidence: the category's loudest trust failure is billing traps (Finch Trustpilot 2.4: "a full year charged to my card… moved onto Plus without understanding"; Tiimo: "accidentally ended up buying a subscription"; "did i just waste $40?" over Android feature gaps). Your repo already has the right state machine (assessment: "swapping RevenueCat in touches startTrial/purchase and nothing else").
- Implementation:
  - Add the official `revenuecat` Flutter package; wire to the existing `monetization_service.dart` (startTrial/purchase seams).
  - **Pricing (DECISION — owner confirms before store submission):** research-recommended $5.99/mo or $49/yr — inside the $3–10 band, below Sunsama ($16–20), far below Inflow ($47.99/mo, an outlier explicitly positioned against human coaching, not apps). 7-day trial (category norm: ~70% of productivity apps offer trials).
  - **Publish these as marketing lines** (they are the direct answer to the documented horror stories): "Trial ends {date} — we tell you in-app, not just by email." · "Cancel in-app, one tap." · "One price, both stores." (Price parity: publish the same price iOS/Android — the unexplained price gap is a named Finch complaint.)
  - Paywall copy = **only `live` features** (FeatureFlags already enforces — keep it enforced; this is a moat most competitors lack).
- Tests: extend `test/monetization_test.dart` for trial state transitions; non-billable-features-stay-free invariant; paywall-renders-only-live-features snapshot.
- **Acceptance:** full purchase + cancel + trial-expiry flows work in sandbox; zero user can be charged for a non-`live` feature (test-enforced).

---

### PHASE 4 — Weeks 4–9: Focus Caves (REAL body doubling) — DECISION GATE at week 4

**The decision (owner, brief required before build):** the research's verdict is unambiguous — the simulated "127 people" room must become **real or be cut**; leaving it as-is is "the one genuinely bad outcome" (your own assessment, now community-corroborated: body doubling "requires the other person to actually be doing the thing"; free substitutes — Discord, Twitch streams — are a large parallel economy; 10+ platforms are actively monetizing this, $0–35/mo).
- **Option A — Build real (research-recommended if committed to the social bet).** Infra is cheap: LiveKit (official Flutter SDK; self-host OSS ~$60–200/mo at ~200 concurrent, or Cloud Ship tier $50/mo). The real costs are 4–6 weeks engineering + moderation + a privacy review.
- **Option B — Cut (1 day):** remove the screen, re-point Pro to what's real (dopamine menu, themes, ambient sounds), keep a public "caves coming" waitlist.

**If A, build spec:**
- **Rooms:** 24/7 always-open room (StudyStream/Caveday pattern — kills the #1 complaint about 1:1 services: no-shows/cancellations) + optional scheduled 52-minute "caves" (V2; the chronobiology angle Caveday monetizes).
- **Join = 1 tap. Goal check-in = 1 text field** (or voice via WI-2.1): "I'll do: ___" (Focusmate's start ritual, proven). Leave = 1 tap, optional "how did it go?" (end ritual).
- **The proof mechanic:** your **timer ring becomes visible to the room while running** (wall-clock — already built) — Prodpod's "you can see other users' timers running in real time" is the exact "actually doing the thing" signal that community evidence says matters, *without* the video awkwardness ("video with strangers can feel socially weird depending on the day").
- **Camera optional → avatar fallback** in the existing cartoon style (a brand asset; Gogh/LifeAt/Prodpod prove no-camera rooms are a feature, not a compromise).
- **Reward flywheel (nobody else has this):** completing a focus session *inside a live room* fires the RewardEngine as normal — the dopamine menu becomes the reason to return to caves.
- **Privacy as a feature (make it a line in the listing):** "We never record. Only your timer is visible." Presence-only data; no media stored.
- **Moderation spec (write before code):** ToS + in-room report flow → human review queue; avatar mode for privacy/minors; rate limits on join; no DMs in V1 (kills 80% of abuse surface).
- **Honesty gate (non-negotiable):** `FeatureFlags.bodyDoubling` stays `simulated` until the first real room works end-to-end on both platforms; flips to `live` only then — and only `live` may ever be billable (ADR-002 does the rest).
- ADR-006 (architecture: LiveKit self-host vs Cloud) + RISK-12 (moderation/abuse) + RISK-13 (presence cost).
- **Acceptance (V1):** 2 devices on a real network join, see each other's running timer rings, check in/out, complete a session, both receive rewards; camera off throughout; no recording artifacts on disk.

---

### PHASE 5 — Weeks 5–8: phone control + ambient presence

**WI-5.1 · "Gentle Block" (closes N9 — platform-honest)**
- Evidence: the user's own Play app "Ekagra: Screen Time & Focus" already proves the Android pattern (Accessibility Service for foreground detection, "mindful pause, not a wall"); Roots' "monk mode" (hard lock, no override) shows the demand tier; iOS self-restriction exists via the Screen Time API (FamilyControls + ManagedSettings + DeviceActivity; WWDC22 "Worklog" demo) but requires Apple's API approval, uses opaque tokens (your app cannot see which app the user opened — a *privacy plus* to market), and has a 15-minute minimum unlock window.
- **Android (V1):** during an active focus session, a user-selected blocked app (defaults: Instagram, YouTube, TikTok) triggers the **existing calm pause screen** instead of a cold lock: "You reached for {app}. Return to {task}, or take a 10-min break — your call." Reuse the sister app's detection approach; permissions explained in-app in plain language (the sister app's FAQ copy is a good base).
- **Monk mode (optional toggle, off by default):** hard lock for the session duration, no override (Roots pattern).
- **iOS (V1):** app creates a custom **"Deep Work" Focus mode** (silences notifications) + a "Guide me to Screen Time" step-by-step deep-link flow; `FeatureFlags` honesty labels until the Screen Time API approval lands (V2 track, no guaranteed timeline — log as RISK-14).
- Rules: never block Ekagra itself; the pause screen is a **choice** (Rules 10/14 — no wall, no shame); **no counts** of "how many times you reached for it" (Rule 7).
- **Acceptance (Android):** blocked app during a session → pause screen → return or break; monk-mode variant locks; no crash paths; permissions flow honest.
- **Acceptance (iOS):** Focus mode creation works; guide flow deep-links correctly; nothing implies capabilities the app doesn't have.

**WI-5.2 · Widgets (closes N14)**
- Evidence: Tiimo's broken watch/widgets are a documented churn driver; the working pattern is a two-cue system — **lock screen = urgency** ("Leave in 20 minutes"), **home = the day** — and "if a reminder needs interpretation, it's probably too weak" (icon + ≤6 words).
- Implementation: `home_widget` (Android Glance) + WidgetKit (iOS). Spec Section L is already written — follow it.
  - Small: One Thing + shrinking arc (icon + ≤6 words).
  - Medium: next 3 + day progress.
  - Lock screen (iOS): active focus countdown / "15 min left".
  - **No task counts anywhere** (Rule 7).
- **Acceptance:** both platforms render from real data; widget tap deep-links; stale state (app killed) still correct (wall-clock).

**WI-5.3 · Anti-novelty-decay retention program (closes N15)**
- Evidence: "expect novelty decay within weeks to months; treat rotating as a feature, not your failure" (Simply Psychology); Finch: "lost its self-care novelty after the first month… now it's a dress-up game"; "I just open it, mark off everything, don't touch it again". Your variable-ratio rewards are already the most decay-resistant reinforcement schedule known — extend it:
  - **Dopamine menu refresh:** monthly, suggest 3 new default rewards (1-tap add). "New toys, same box."
  - **Milestones as "active days", never streaks** (Rule 4): 7 / 30 / 100 days-showing-up celebration with a rare reward from RewardEngine. Copy: "30 days you showed up for yourself."
  - **Hyperfocus celebration** (detection already exists, `Ev.hyperfocusDetected`): post-hoc "That was a 3-hour deep dive. That's the brain you're building." — celebration, never scolding (the inverse of streak apps).
  - **Novelty rotation:** nudge copy/sound rotates weekly (feeds WI-1.4 copy bank); one new ambient sound per season.
  - **Instrument everything** (WI-2.3 sink): the existing `experiment_service.dart` runs the A/B framework — register experiments here, results into `docs/audits/`.
- **Acceptance:** each item gated by FeatureFlags; every celebration string passes Rule-15 tests; experiment registration works end-to-end in test.

---

### PHASE 6 — Weeks 8–12: the pilot (the data moat)

**WI-6.1 · 20–50 user, 4-week pre-registered pilot**
- Why: **no competitor in the shame-free/low-maintenance cluster has public retention data.** Inflow used an open feasibility study (n=240, 7 weeks) to buy trust *and* funding. First with real numbers owns the narrative; it also gates every future DECISION with data instead of taste.
- Protocol:
  - Recruit 20–50 ADHD adults (owner's network + a transparent r/ADHD launch post: "free for 4 weeks, we measure, you get feedback" + the ADHD Discord servers the research identified).
  - Pre-register hypotheses BEFORE launch (example: "nudge ON beats OFF on D7 retention by ≥5 points"; "decomposition usage correlates with task completion ≥ +20%"). Store the pre-registration doc in `docs/`.
  - Primary metrics (priors = category "strong performer" benchmarks, not promises): **D1 ≥ 30% · D7 ≥ 15% · D30 ≥ 12%**; One-Thing adoption ≥ 50% of active days; focus completion rate; reward claim rate.
  - The one qualitative question at week 4: "If you stopped using it, why — one word." (Churn reasons = next roadmap.)
  - Privacy: opt-in analytics on the existing opt-out architecture; local-only default; no PII in events (verify by test).
- Output: `docs/audits/pilot-results.md` — methods, pre-registered hypotheses, results, what we'd change. This document is also the press/marketing asset.
- **Acceptance:** dashboard exists before first user installs; zero PII in event payload (tested); results doc published to the repo.

---

## 4. Documentation duties (per work item, non-negotiable)

1. **ADR** in `docs/decision-log.md` for any persistence, architecture, or irreversible product decision (their format, including Reversible: Yes/No).
2. **Risk register** entries opened/closed with severity (P0–P3) as work lands.
3. **Spec deltas:** if a WI deliberately deviates from `docs/Ekagra_Unified_Final_Specification.md`, record the delta in the ADR — the spec is a plan, the code is the truth, and the ADR is the bridge.
4. **Audit trail:** meaningful self-checks (e.g., "paywall renders only live features", "no forbidden words in new strings") live in `docs/audits/`, not in PR descriptions.
5. Never rewrite history: the repo's 2-day git history is the provenance record; keep commits small and honest.

## 5. Global definition of done (every PR)

- `dart format --set-exit-if-changed` · `flutter analyze --fatal-infos` · `flutter test` — all green (the CI gates).
- New user-facing strings covered by `test/design_rules_test.dart` (the test *finds* violations — if it flags one, the string is wrong, fix the string, not the test).
- No `print()`; no TODO without a linked ADR/risk.
- No new dependency without a one-line justification in the PR (the 8-dependency footprint is a feature).
- FeatureFlags entry exists for anything partially real; billing only for `live`.
- Docs updated per §4.

## 6. What you must NOT do

- Do not migrate state management, add a backend, or introduce cloud calls into core features.
- Do not ship any "coming soon" screen that displays as if it works (the K18 pattern, anywhere).
- Do not add streaks, task counts, red error states, or forbidden words — the tests will fail you.
- Do not change persisted data formats without an ADR + SafeStore-compatible migration test.
- Do not touch pricing, store presence, or the body-doubling build/cut without owner sign-off (DECISION markers above).
- Do not purchase anything (reports, services, credits). Maximum quality ≠ maximum spend.
- Do not present unexecuted tests as passing. If the toolchain is unavailable, say so and stop.

## 7. Evidence appendix (verify, don't trust, these are the load-bearing claims)

- **Inflow** (YC, ~$16.7M raised, $11M Series A; 7-week open feasibility study n=240): top Android review (Apr 2026) rejects the AI-chat push ("AI psychosis… validation bot as a therapist") — the opt-in-AI positioning's source. Store: 3.9★/2,010 Android, 4.4★/5,602 iOS, 100K+ downloads, $47.99/mo–$199/yr.
- **Finch** (PBC, 4.95★, ~724K iOS ratings, est. $0.9–1.75M/mo): Trustpilot 2.4 — top complaint is trial→annual billing surprises; r/finch users: "what I hate most is the streaks… my brain doesn't work well with negative motivation"; "corrupts the app and loses all your data"; "novelty lost after the first month".
- **Tiimo** (€3M seed, 4.59★): review-verified timer bugs, "things have disappeared from my schedule", "constantly logged out", "accidentally ended up buying a subscription", Android tier gaps ("did i just waste $40?").
- **Llama Life** (4.5★, ~$6/mo): single-task countdown timer = "changed my life. I actually get things done now."
- **Goblin Tools** (free, no account, no onboarding): Magic ToDo = gold standard; documented gap: "it stops at the plan… no one-step-at-a-time mode." "Most productivity apps lose ADHD users during onboarding."
- **Body-doubling market 2026:** Focusmate $0–12/mo (goal check-ins; no-shows), Caveday $35/mo (100s in Zoom, 52-min sprints, 24/7), StudyStream (YC, ~$2.1M, 4M students, ~$10/mo, 24/7 cam-on/mic-off), Prodpod (no camera, **visible running timers**), dubbii ($5.99+, pre-recorded task doubles), FLOWN ($19–25/mo, "studied for ADHD"), plus free Discord/Twitch economy.
- **Notification science/practice:** one notification is never enough (62–85% WM impairment); gentle persistent re-nudging ("firm without guilt"); fewer-better; action-oriented copy; event/habit anchors beat clock times; 60/30/15/5 escalation; UO 2018 — minimal text +25–30%, icons +18%; rotate to beat habituation.
- **Time blindness:** Time Timer "gold standard"; shrinking visual > numeric; +50% estimation padding; visual timers "without any cognitive processing."
- **Platform APIs:** iOS self-blocking = Screen Time API (FamilyControls/ManagedSettings/DeviceActivity, WWDC22; Apple approval; opaque tokens; 15-min unlock floor); Android blocking = UsageStats + AccessibilityService (proven in the owner's own Play app); on-device STT = `whisper_ggml` (live streaming, assets-shipable, 99 languages).
- **Market:** $1.9–2.2B (2024/25) → ~$4B (2029–33), 12–18% CAGR (research-firm estimates, disagreement disclosed); ~15.5M US adults diagnosed (CDC brief via aggregator); retention: D30 median ~8%, strong >12%; trials ~70% of category; first-renewal ~60% → 28.6% by 5th; 95% of category sub-revenue to top-10% apps.
- Full verbatim quotes, URLs, and claim-level confidence: `evidence-ledger-v4.md` (and v2/v3) in the research folder.

---

*Prompt prepared 2026-08-25 from three levels of owner-approved research (L1 Quick Brief → L2 Deep Research → L3 Bottom-Depth, incl. sentiment/competitor/solution tracks). Research verdicts are separated from implementation recommendations throughout; every DECISION marker is an owner call, not an agent call.*
