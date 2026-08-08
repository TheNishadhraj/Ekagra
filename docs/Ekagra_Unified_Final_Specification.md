# 🧠 EKAGRA — Complete Unified Application Specification
## Final Developer Handoff Document (Merged & Gap-Audited)

**Version:** 2.0 — August 2026  
**For:** Antigravity Development Team  
**Platform:** iOS + Android (Flutter)  
**Status:** FINAL — Merge of App Specification + Gap Audit  
**This document is the single source of truth. If it's not here, it doesn't ship.**

---

# MASTER TABLE OF CONTENTS

```
SECTION A — DESIGN SYSTEM & RULES
  A1. Non-Negotiable Design Rules (15 Hard Rules)
  A2. Color System
  A3. Typography
  A4. Spacing & Radius
  A5. File & Code Architecture

SECTION B — ONBOARDING (Progressive, Zero-Config)
  B1. Revised Onboarding Philosophy
  B2. Screen 1: Welcome / Brain Dump Launch
  B3. Screen 2: ADHD Type Selection
  B4. Screen 3: Dopamine Menu Setup
  B5. Screen 4: Notification Permission
  B6. Screen 5: Account Creation + Soft Paywall
  B7. Post-Onboarding First Home Visit

SECTION C — HOME SCREEN (The Ekagra Board)
  C1. Layout Structure
  C2. Dynamic Greeting & Encouragement
  C3. Day Progress Bar
  C4. Energy Check-In
  C5. Mood Check-In (NEW)
  C6. "Your ONE Thing" Card
  C7. Upcoming Tasks Grid
  C8. Today's Stats (Shame-Free)
  C9. Task Detail Bottom Sheet

SECTION D — BRAIN DUMP (Task Capture)
  D1. Core Philosophy
  D2. Screen Layout
  D3. Text Input
  D4. Voice Input
  D5. Quick-Add Chips & Common Task Templates (NEW)
  D6. Task Entry Animations
  D7. Voice Dump Mode
  D8. Brain Dump Celebration

SECTION E — TASK MANAGEMENT SYSTEM (NEW SECTION)
  E1. Task Data Model (Expanded)
  E2. Task Schedule Types (Today / This Week / Anytime / Someday)
  E3. Someday/Maybe List (NEW)
  E4. Auto-Pruning System (NEW)
  E5. Flexible Recurring Tasks (NEW)
  E6. Deadline Types (Hard / Soft / Flexible)
  E7. Task Search & Filter (NEW)
  E8. Honest Completion Check (NEW)

SECTION F — "PICK ONE THING" AI ENGINE
  F1. Hybrid Selection Algorithm
  F2. AI Task Selection (GPT-4o-mini)
  F3. Mood-Aware Task Selection (NEW)
  F4. Micro-Commitment Generation
  F5. Fallback Logic
  F6. AI Caching Strategy

SECTION G — VISUAL TIME COMPASS (Day View)
  G1. Screen Layout
  G2. Free Time Gap Visualization (NEW)
  G3. Rolling 7-Day View (NEW)
  G4. Drag-to-Reschedule (V1.1)
  G5. Energy Insight Card
  G6. Smart Task Visibility (NEW)

SECTION H — FOCUS MODE
  H1. Screen Layout
  H2. Focus Ring (Central Timer)
  H3. Bulletproof Timer Logic (NEW)
  H4. Timer Duration Selector
  H5. Control Buttons
  H6. "Can't Focus?" Flow
  H7. Ambient Sound System
  H8. Transition Sounds (NEW)
  H9. Focus Mode Distraction Blocking (NEW)
  H10. Hyperfocus Support (NEW)
  H11. Focus Session Complete Flow
  H12. No Forced Breaks Between Sessions (NEW)

SECTION I — DOPAMINE MENU & REWARD ENGINE
  I1. Variable Ratio Reinforcement
  I2. Pre-Loaded Dopamine Menu (NEW)
  I3. Reward Reveal Screen
  I4. Rare / Special Rewards
  I5. Reward History
  I6. Shareable Reward Cards

SECTION J — BODY DOUBLING (Silent Co-Working)
  J1. Design Philosophy
  J2. Focus Room Screen
  J3. Cheer System
  J4. Presence System

SECTION K — SETTINGS & PROFILE
  K1. Settings Screen Layout
  K2. ADHD Profile Editor
  K3. Dopamine Menu Editor
  K4. Notification Schedule (NEW Discipline Rules)
  K5. Font Options (NEW)
  K6. Subscription Management (Transparent Cancellation) (NEW)
  K7. Data Export (NEW)
  K8. Account Deletion

SECTION L — WIDGETS
  L1. iOS Widgets (Small, Medium, Lock Screen)
  L2. Android Widgets (Small, Medium, Large)
  L3. Widget Update Logic

SECTION M — PUSH NOTIFICATION SYSTEM
  M1. Notification Types
  M2. Notification Copy Guidelines
  M3. Notification Discipline Rules (NEW)
  M4. Smart Notification Timing
  M5. Notification Auto-Dismiss (NEW)

SECTION N — AI INTEGRATION (Complete)
  N1. AI Use Cases Summary
  N2. AI Service Implementation (Full Code)
  N3. Audio Read-Aloud for All Text (NEW)
  N4. AI Response Caching
  N5. Offline AI Fallback (NEW)

SECTION O — SUBSCRIPTION & PAYWALL
  O1. Free vs Pro Feature Matrix
  O2. Paywall Trigger Points
  O3. Transparent Pricing (NEW)
  O4. RevenueCat Integration
  O5. Easy Cancellation Policy (NEW)

SECTION P — ANIMATIONS & MICRO-INTERACTIONS
  P1. Complete Animation Registry (35+ entries)
  P2. Lottie Animation Files
  P3. Haptic Feedback Map

SECTION Q — EDGE CASES & ERROR HANDLING
  Q1. Network Errors
  Q2. Data Edge Cases
  Q3. Account Edge Cases
  Q4. State Recovery (Crash Handling)
  Q5. Offline-First Architecture (NEW)

SECTION R — ACCESSIBILITY
  R1. Visual Accessibility
  R2. Screen Reader Labels
  R3. Motor Accessibility
  R4. Font Options & Dyslexia Support (NEW)
  R5. RSD-Safe Language Audit (NEW)

SECTION S — ANALYTICS
  S1. Event Registry (50+ events)
  S2. Funnel Tracking

SECTION T — DATABASE SCHEMA (Firestore)
  T1. Collections (All)
  T2. Indexes
  T3. Security Rules

SECTION U — API & CLOUD FUNCTIONS
  U1. Cloud Functions (8 functions)
  U2. External API Integrations

APPENDICES
  App A. Complete Notification Copy Pool
  App B. Shame-Free Error Messages
  App C. App Store Metadata
  App D. Launch Checklist
  App E. Gap Audit Reference Table
```

---

# SECTION A: DESIGN SYSTEM & RULES

## A1. Non-Negotiable Design Rules (15 Hard Rules)

These rules are derived from analysis of 136,000+ app store reviews and 30+ Reddit threads from ADHD communities. Violating any of these rules will cause user abandonment. **These are non-negotiable.**

```
RULE  1: No screen shows more than 3 primary choices
RULE  2: No action requires more than 2 taps
RULE  3: No text uses red for negative states (warm coral only)
RULE  4: No word "streak" in the UI (use "active days")
RULE  5: No word "overdue" in the UI
RULE  6: No word "failed" or "missed" in the UI
RULE  7: No count of "incomplete" or "pending" tasks shown
RULE  8: No dark patterns on subscription
RULE  9: No forced setup before core value delivery
RULE 10: No feature ships on only one platform
RULE 11: No notification without user consent
RULE 12: No screen goes dark during focus mode
RULE 13: No task auto-deletes (ever) — soft delete only
RULE 14: No comparison to other users
RULE 15: No shame in any copy, animation, or interaction
```

### Rule Enforcement
Every pull request must include a "Rule Compliance" checkbox confirming the change doesn't violate any of the 15 rules. QA must test against these rules before every release.

## A2. Color System

### Light Mode (Default)

```dart
class NudgeColors {
  // Primary — Warm, calming purple (not clinical blue)
  static const primary = Color(0xFF7C5CFC);
  static const primaryLight = Color(0xFFB8A9FC);
  static const primaryDark = Color(0xFF5A3FD6);
  
  // Background — Not pure white (reduces eye strain)
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF5F3FF);
  
  // Text — Softer than pure black
  static const textPrimary = Color(0xFF2D2B42);
  static const textSecondary = Color(0xFF6B6889);
  static const textTertiary = Color(0xFF9E9BB5);
  
  // Semantic — NO RED ANYWHERE
  static const success = Color(0xFF6BCB77);
  static const warning = Color(0xFFFFB84D);
  static const info = Color(0xFF5CB8FF);
  static const error = Color(0xFFFF8C6B);  // Warm coral, NEVER red
  
  // Energy Colors
  static const energyHigh = Color(0xFFFFB84D);
  static const energyMedium = Color(0xFF6BCB77);
  static const energyLow = Color(0xFF5CB8FF);
  static const energyDrained = Color(0xFFD4D2E0);
  
  // Mood Colors (NEW)
  static const moodGreat = Color(0xFF6BCB77);
  static const moodGood = Color(0xFF8DD88E);
  static const moodOkay = Color(0xFFFFB84D);
  static const moodLow = Color(0xFF5CB8FF);
  static const moodRough = Color(0xFFD4D2E0);
  
  // Focus Timer
  static const focusActive = Color(0xFF7C5CFC);
  static const focusPaused = Color(0xFFFFB84D);
  static const focusComplete = Color(0xFF6BCB77);
  
  // Reward Tiers
  static const rewardQuick = Color(0xFFFFD93D);
  static const rewardMedium = Color(0xFFFF8C6B);
  static const rewardBig = Color(0xFF7C5CFC);
  
  // NEVER USE
  // static const shame = Color(0xFFFF0000);     // DOES NOT EXIST
  // static const overdue = Color(0xFFFF0000);   // DOES NOT EXIST
}
```

### Dark Mode

```dart
class NudgeDarkColors {
  static const background = Color(0xFF1A1825);
  static const surface = Color(0xFF252336);
  static const surfaceElevated = Color(0xFF2F2D42);
  static const textPrimary = Color(0xFFF0EEFF);
  static const textSecondary = Color(0xFF9E9BB5);
  static const primary = Color(0xFF9B85FC);
  // All semantic colors remain same with 10% brightness boost
}
```

## A3. Typography

```dart
class NudgeTypography {
  // Font: Inter (clean, readable, ADHD-friendly)
  
  static const h1 = TextStyle(
    fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700,
    height: 1.2, letterSpacing: -0.5, color: NudgeColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600,
    height: 1.3, letterSpacing: -0.3, color: NudgeColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600,
    height: 1.3, color: NudgeColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400,
    height: 1.5, color: NudgeColors.textPrimary,
  );
  static const bodyBold = TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600,
    height: 1.5, color: NudgeColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.4, color: NudgeColors.textSecondary,
  );
  static const tiny = TextStyle(
    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
    height: 1.3, color: NudgeColors.textTertiary,
  );
  static const encouragement = TextStyle(
    fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w500,
    height: 1.4, color: NudgeColors.textSecondary,
    fontStyle: FontStyle.italic,
  );
}
```

## A4. Spacing & Radius

```dart
class NudgeSpacing {
  static const double xs = 4;  static const double sm = 8;
  static const double md = 12; static const double lg = 16;
  static const double xl = 24; static const double xxl = 32;
  static const double xxxl = 48; static const double screen = 20;
}

class NudgeRadius {
  static const double sm = 8;  static const double md = 12;
  static const double lg = 16; static const double xl = 24;
  static const double full = 999;
}
```

## A5. File & Code Architecture

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart
│   ├── routes.dart
│   ├── constants.dart
│   └── design_rules.dart          # NEW: Rule enforcement constants
├── models/
│   ├── user_model.dart
│   ├── task_model.dart            # EXPANDED: schedule types, deadlines, subtasks
│   ├── brain_dump_model.dart
│   ├── focus_session_model.dart
│   ├── dopamine_reward_model.dart
│   ├── dopamine_menu_model.dart
│   ├── time_block_model.dart
│   ├── energy_log_model.dart
│   ├── mood_log_model.dart        # NEW
│   ├── body_double_session.dart
│   ├── subscription_model.dart
│   ├── recurrence_rule.dart       # NEW
│   └── calendar_event.dart        # NEW
├── providers/
│   ├── auth_provider.dart
│   ├── task_provider.dart
│   ├── focus_provider.dart
│   ├── reward_provider.dart
│   ├── energy_provider.dart
│   ├── mood_provider.dart         # NEW
│   ├── subscription_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── onboarding/
│   │   ├── welcome_screen.dart
│   │   ├── adhd_type_screen.dart
│   │   ├── dopamine_menu_setup_screen.dart
│   │   ├── notification_permission_screen.dart
│   │   └── paywall_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── brain_dump/
│   │   └── brain_dump_screen.dart
│   ├── task_detail/
│   │   └── task_detail_sheet.dart
│   ├── focus/
│   │   ├── focus_timer_screen.dart
│   │   ├── focus_complete_screen.dart
│   │   └── ambient_player.dart
│   ├── timeline/
│   │   └── day_view_screen.dart
│   ├── rewards/
│   │   ├── reward_reveal_screen.dart
│   │   └── reward_history_screen.dart
│   ├── body_double/
│   │   └── body_double_screen.dart
│   ├── someday/                   # NEW
│   │   └── someday_list_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── dopamine_menu_edit_screen.dart
│   │   ├── notification_settings_screen.dart
│   │   ├── font_settings_screen.dart   # NEW
│   │   ├── data_export_screen.dart     # NEW
│   │   └── subscription_management_screen.dart
│   └── shared/
│       └── ekagra_paywall_sheet.dart
├── widgets/
│   ├── ekagra_card.dart
│   ├── task_chip.dart
│   ├── time_compass.dart
│   ├── energy_gauge.dart
│   ├── mood_selector.dart          # NEW
│   ├── focus_ring.dart
│   ├── dopamine_burst.dart
│   ├── gentle_buttons.dart
│   ├── brain_dump_input.dart
│   ├── reward_mystery_box.dart
│   ├── shimmer_loading.dart
│   ├── free_time_gap.dart          # NEW
│   ├── someday_card.dart           # NEW
│   └── search_bar.dart             # NEW
├── services/
│   ├── ai_service.dart
│   ├── firebase_service.dart
│   ├── notification_service.dart
│   ├── analytics_service.dart
│   ├── reward_engine.dart
│   ├── energy_tracker.dart
│   ├── mood_tracker.dart           # NEW
│   ├── task_pruning_service.dart   # NEW
│   ├── recurrence_service.dart     # NEW
│   ├── calendar_service.dart       # NEW
│   ├── data_export_service.dart    # NEW
│   ├── transition_sound_service.dart # NEW
│   ├── wakelock_service.dart       # NEW
│   ├── read_aloud_service.dart     # NEW
│   └── subscription_service.dart
├── utils/
│   ├── haptic_feedback.dart
│   ├── sound_effects.dart
│   ├── date_helpers.dart
│   ├── validators.dart
│   ├── rsd_safe_copy.dart          # NEW: Language audit helpers
│   └── offline_queue.dart          # NEW
└── l10n/
    └── app_en.arbs
```

---

# SECTION B: ONBOARDING (Progressive, Zero-Config)

## B1. Revised Onboarding Philosophy

**Problem:** Every competitor requires setup before delivering value. ADHD users spend 3 hours customizing then never open the app again. Source: 30+ Reddit complaints.

**Solution:** The app works PERFECTLY with zero setup. All customization is optional and can be done incrementally.

```
REVISED FLOW:

MINUTE 0:   App opens → "Ready to dump what's swirling?" → Brain dump
MINUTE 0.5: User types 3-5 tasks (with common task suggestions)
MINUTE 1:   AI picks one thing → Focus timer starts (25 min default)
MINUTE 25:  "🎉 You did it!" → Reward reveal
MINUTE 26:  "Want to set up your profile?" → OPTIONAL setup screens

KEY: The user has received VALUE (completed a task + got a reward) 
     BEFORE being asked to set up anything.
```

## B2. Screen 1: Welcome / Brain Dump Launch

```
┌─────────────────────────────────────┐
│                                     │
│         [Animated Logo]             │
│         (brain → nudge icon)        │
│                                     │
│         "Hey there 👋"              │
│                                     │
│         "Ready to dump what's       │
│          swirling in your head?"    │
│                                     │
│    ┌───────────────────────────┐    │
│    │     Let's go →            │    │
│    └───────────────────────────┘    │
│                                     │
│    "Want to customize first?        │
│     Skip for now →"                 │
│                                     │
└─────────────────────────────────────┘
```

### Animations
| Element | Animation | Duration | Easing |
|---|---|---|---|
| Logo | Fade in + scale 0.8→1.0 | 800ms | easeOutBack |
| "Hey there 👋" | Fade in + slide up 20px | 600ms | easeOut (400ms delay) |
| Description | Fade in + slide up 20px | 600ms | easeOut (200ms delay) |
| "Let's go" button | Fade in + slide up 30px | 500ms | easeOut (400ms delay) |
| "Skip" link | Fade in | 300ms (with button) | linear |

### Logic
- "Let's go" → Opens Brain Dump immediately (Section D)
- "Skip for now" → Loads defaults from QuickStartTemplates → Home Screen
- Haptic: `lightImpact()` on tap

## B3. Screen 2: ADHD Type Selection (Optional)

### Layout
```
┌─────────────────────────────────────┐
│  ← Back                    2 of 4   │
│                                     │
│  "What does ADHD look like          │
│   for you?"                         │
│                                     │
│  "This helps us personalize.        │
│   Change anytime in Settings."      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🧊 "I freeze and can't      │    │
│  │    start anything"           │    │
│  │    Task Paralysis            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ⏰ "Time just... vanishes"   │    │
│  │    Time Blindness            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🦋 "I start 10 things and   │    │
│  │    finish none"              │    │
│  │    Task Switching            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🎢 "My energy is a          │    │
│  │    rollercoaster"            │    │
│  │    Energy Fluctuation        │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🌈 "A bit of everything"    │    │
│  │    All of the above          │    │
│  └─────────────────────────────┘    │
│                                     │
│        [Continue →]                 │
│                                     │
│  ● ○ ○ ○                           │
└─────────────────────────────────────┘
```

### Card Design
- Height: 72px, Border radius: 16px
- Background: `surface`, Border: 1.5px `primaryLight` (unselected) → 2px `primary` (selected)
- Selected: background `primary.withOpacity(0.08)` + checkmark icon

### Animations
| Element | Animation | Duration | Easing |
|---|---|---|---|
| Cards (stagger) | Slide from right + fade | 400ms each, 80ms stagger | easeOut |
| Card press | Scale 1.0→0.97 | 150ms | easeInOut |
| Selected card | Border + background transition | 200ms | easeInOut |
| Checkmark | Scale 0→1.2→1.0 | 300ms | easeOutBack |

### Logic
- Multiple selections allowed (stored as array)
- Default if skipped: `[AdhdTrait.taskParalysis]`
- Haptic: `selectionClick()` on tap, `mediumImpact()` on confirm

### Data Model
```dart
enum AdhdTrait {
  taskParalysis,
  timeBlindness,
  taskSwitching,
  energyFluctuation,
}
```

## B4. Screen 3: Dopamine Menu Setup (Optional)

### Layout
```
┌─────────────────────────────────────┐
│  ← Back                    3 of 4   │
│                                     │
│  "Set up your Dopamine Menu 🍫"     │
│                                     │
│  "Your rewards. We pick a surprise  │
│   after you complete tasks."        │
│                                     │
│  Quick Hits (2 min)                 │
│  ┌─────────────────────────────┐    │
│  │ 🎵 Listen to 1 hype song    │ ✓  │
│  │ 🍫 Eat a snack              │ ✓  │
│  │ 📱 Check social media       │    │
│  │ 🎮 Play 1 round of a game   │    │
│  │ ✨ + Add your own            │    │
│  └─────────────────────────────┘    │
│                                     │
│  Medium Rewards (15 min)            │
│  ┌─────────────────────────────┐    │
│  │ 🚶 Take a short walk        │ ✓  │
│  │ ☕ Make a fancy coffee       │    │
│  │ 🎬 Watch a short video      │    │
│  │ 🐕 Pet the dog/cat          │    │
│  │ ✨ + Add your own            │    │
│  └─────────────────────────────┘    │
│                                     │
│  Big Rewards (30+ min)              │
│  ┌─────────────────────────────┐    │
│  │ 📺 Watch an episode         │    │
│  │ 🛁 Take a long bath         │    │
│  │ 🎮 Gaming session           │    │
│  │ ✨ + Add your own            │    │
│  └─────────────────────────────┘    │
│                                     │
│  "Select at least 2 per category"   │
│                                     │
│        [Continue →]                 │
│                                     │
│  ● ● ○ ○                           │
└─────────────────────────────────────┘
```

### Pre-Loaded Defaults (Work Without Setup)
```dart
final defaultDopamineMenu = DopamineMenu(
  quick: [
    DopamineItem(emoji: '🎵', text: 'Listen to 1 hype song', durationMinutes: 3),
    DopamineItem(emoji: '🍫', text: 'Eat a snack', durationMinutes: 2),
    DopamineItem(emoji: '💃', text: '60-second dance break', durationMinutes: 1),
  ],
  medium: [
    DopamineItem(emoji: '🚶', text: 'Take a short walk', durationMinutes: 15),
    DopamineItem(emoji: '☕', text: 'Make a fancy coffee', durationMinutes: 10),
    DopamineItem(emoji: '🐕', text: 'Pet/play with your pet', durationMinutes: 10),
  ],
  big: [
    DopamineItem(emoji: '📺', text: 'Watch an episode of your show', durationMinutes: 45),
    DopamineItem(emoji: '🛁', text: 'Take a long bath/shower', durationMinutes: 30),
    DopamineItem(emoji: '🎮', text: 'Gaming session', durationMinutes: 60),
  ],
);
```

### Full Pre-Defined Options Pool
```dart
final predefinedRewards = {
  'quick': [
    DopamineItem(emoji: '🎵', text: 'Listen to 1 hype song', durationMinutes: 3),
    DopamineItem(emoji: '🍫', text: 'Eat a snack', durationMinutes: 2),
    DopamineItem(emoji: '📱', text: 'Scroll social media guilt-free', durationMinutes: 2),
    DopamineItem(emoji: '🎮', text: 'Play 1 round of a game', durationMinutes: 3),
    DopamineItem(emoji: '💃', text: '60-second dance break', durationMinutes: 1),
    DopamineItem(emoji: '☕', text: 'Make a quick tea/coffee', durationMinutes: 3),
    DopamineItem(emoji: '🌈', text: 'Watch a funny reel', durationMinutes: 2),
    DopamineItem(emoji: '🫧', text: 'Pop bubble wrap (yes, really)', durationMinutes: 1),
  ],
  'medium': [
    DopamineItem(emoji: '🚶', text: 'Take a short walk', durationMinutes: 15),
    DopamineItem(emoji: '☕', text: 'Make a fancy coffee', durationMinutes: 10),
    DopamineItem(emoji: '🎬', text: 'Watch a YouTube video', durationMinutes: 15),
    DopamineItem(emoji: '🐕', text: 'Pet/play with your pet', durationMinutes: 10),
    DopamineItem(emoji: '🎵', text: 'Listen to a full album', durationMinutes: 15),
    DopamineItem(emoji: '🧖', text: 'Quick skincare routine', durationMinutes: 10),
    DopamineItem(emoji: '📞', text: 'Call a friend', durationMinutes: 15),
    DopamineItem(emoji: '🧁', text: 'Bake something simple', durationMinutes: 15),
  ],
  'big': [
    DopamineItem(emoji: '📺', text: 'Watch an episode of your show', durationMinutes: 45),
    DopamineItem(emoji: '🛁', text: 'Take a long bath/shower', durationMinutes: 30),
    DopamineItem(emoji: '🎮', text: 'Gaming session', durationMinutes: 60),
    DopamineItem(emoji: '🎨', text: 'Creative time (art, music, etc.)', durationMinutes: 45),
    DopamineItem(emoji: '🛍️', text: 'Online window shopping', durationMinutes: 30),
    DopamineItem(emoji: '📖', text: 'Read a book/manga', durationMinutes: 30),
    DopamineItem(emoji: '🌳', text: 'Go outside for a while', durationMinutes: 30),
    DopamineItem(emoji: '😴', text: 'Guilt-free nap', durationMinutes: 30),
  ],
};
```

### Logic
- If user skips: defaults are loaded automatically
- Minimum 2 items per category enforced
- "+ Add your own" → inline text field
- Custom items get `isCustom: true` flag

### Data Model
```dart
class DopamineItem {
  final String id;
  final String emoji;
  final String text;
  final int durationMinutes;
  final RewardTier tier;
  final bool isCustom;
  final DateTime createdAt;
}

enum RewardTier { quick, medium, big }
```

## B5. Screen 4: Notification Permission (Optional)

### Layout
```
┌─────────────────────────────────────┐
│  ← Back                    4 of 4   │
│                                     │
│         🔔                          │
│                                     │
│  "Gentle nudges, not alarms"        │
│                                     │
│  "Soft reminders like a friend      │
│   tapping your shoulder."           │
│                                     │
│  💛 "Hey, you've got 15 min.        │
│      Want to tackle that email?"    │
│                                     │
│  💛 "You haven't checked in today.  │
│      No pressure — just saying hi." │
│                                     │
│    ┌───────────────────────────┐    │
│    │  Enable gentle nudges 🔔  │    │
│    └───────────────────────────┘    │
│                                     │
│    I'll do this later               │
│                                     │
│  ● ● ● ●                           │
└─────────────────────────────────────┘
```

### Logic
- "Enable" → System notification permission dialog
- "Later" → Proceed without blocking
- Never block the user for denying notifications
- Pre-configured defaults: Morning 8AM, Midday 12PM, Afternoon 3PM, Evening 8PM

## B6. Screen 5: Account Creation + Soft Paywall

### Account Screen
```
┌─────────────────────────────────────┐
│                                     │
│  "You're all set! 🎉"               │
│                                     │
│  "Create an account to save         │
│   your progress across devices"     │
│                                     │
│  ┌───────────────────────────┐      │
│  │  Continue with Google     │      │
│  └───────────────────────────┘      │
│  ┌───────────────────────────┐      │
│  │  Continue with Apple      │      │
│  └───────────────────────────┘      │
│  ┌───────────────────────────┐      │
│  │  Continue with Email      │      │
│  └───────────────────────────┘      │
│                                     │
│  ─────────── OR ───────────         │
│                                     │
│  Skip for now →                     │
│                                     │
└─────────────────────────────────────┘
```

### Soft Paywall (Bottom Sheet)
```
┌─────────────────────────────────────┐
│  (slides up from bottom)            │
│                                     │
│  🚀 "Unlock the full Ekagra          │
│      experience"                    │
│                                     │
│  Free Forever:                      │
│  ✓ Brain dump (10 tasks)            │
│  ✓ Basic focus timer                │
│  ✓ 3 dopamine menu items            │
│                                     │
│  Ekagra Pro adds:                    │
│  ⭐ Unlimited tasks + AI picks      │
│  ⭐ Full dopamine menu              │
│  ⭐ Body doubling                   │
│  ⭐ Widgets                         │
│  ⭐ Custom themes                   │
│                                     │
│  Try Pro free for 7 days            │
│  Then $7.99/month or $49.99/year    │
│                                     │
│  ┌───────────────────────────┐      │
│  │  Start Free Trial         │      │
│  └───────────────────────────┘      │
│                                     │
│  Maybe later                        │
│                                     │
│  "Cancel anytime — 1 tap in         │
│   Settings. No tricks."             │
│                                     │
└─────────────────────────────────────┘
```

### Animations
| Element | Animation | Duration |
|---|---|---|
| Confetti burst | 50 particles | 1.5s |
| Account buttons | Slide up, stagger | 400ms each |
| Paywall sheet | Slide up from bottom | 400ms, easeOut |
| Feature list items | Checkmark reveal, stagger | 200ms each, 100ms stagger |
| CTA button | Gradient shimmer | 2s loop |

### Logic
- "Start Free Trial" → RevenueCat 7-day trial → $7.99/mo or $49.99/yr
- "Maybe later" → Dismiss, enter home screen
- "Skip for now" → Anonymous account
- Store `paywall_seen: true` + `paywall_skipped_at`
- Next paywall: After 3 days of active use OR when hitting free tier limit

## B7. Post-Onboarding: First Home Screen Visit

### First-Time State
```
┌─────────────────────────────────────┐
│                                     │
│  "Welcome to Ekagra, [Name]! 👋"     │
│                                     │
│  "Let's start with a brain dump."   │
│                                     │
│         [Animated arrow             │
│          pointing to FAB]           │
│                                     │
│         "Tap the + to dump          │
│          everything in your head"   │
│                                     │
│                    [+] ← FAB pulses │
│                                     │
│  ┌────┬────┬────┬────┐             │
│  │Home│Brain│Foc.│Prof│             │
│  └────┴────┴────┴────┘             │
└─────────────────────────────────────┘
```

### Quick Start Defaults (Loaded Automatically)
```dart
class QuickStartTemplates {
  static final defaults = UserPreferences(
    adhdTraits: [AdhdTrait.taskParalysis],
    dopamineMenu: defaultDopamineMenu,  // See B4
    wakeTime: TimeOfDay(hour: 7, minute: 0),
    sleepTime: TimeOfDay(hour: 23, minute: 0),
    notifications: NotificationSettings(
      morning: NudgeNotification(enabled: true, time: TimeOfDay(hour: 8, minute: 0)),
      midday: NudgeNotification(enabled: true, time: TimeOfDay(hour: 12, minute: 0)),
      afternoon: NudgeNotification(enabled: true, time: TimeOfDay(hour: 15, minute: 0)),
      evening: NudgeNotification(enabled: true, time: TimeOfDay(hour: 20, minute: 0)),
      smartTiming: true,
      inactivityNudge: true,
      dndStart: TimeOfDay(hour: 22, minute: 0),
      dndEnd: TimeOfDay(hour: 7, minute: 0),
    ),
  );
}
```

---

# SECTION C: HOME SCREEN (The Ekagra Board)

## C1. Layout Structure

```
┌─────────────────────────────────────┐
│  Ekagra                    [⚙️]      │
│                                     │
│  Good morning, Alex ☀️              │
│  "You've got this today."           │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  DAY PROGRESS               │    │
│  │  ████████░░░░░░░░  42%      │    │
│  │  11:14 AM                   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  ENERGY + MOOD CHECK-IN     │    │
│  │                             │    │
│  │  "How's your energy?"       │    │
│  │  😫  😐  🙂  😄  🔥         │    │
│  │                             │    │
│  │  "How are you feeling?"     │    │
│  │  😢  😔  😐  🙂  😄         │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── YOUR ONE THING ──               │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  🎯                          │    │
│  │  Reply to Sarah's email     │    │
│  │  ~15 min · Quick task       │    │
│  │                             │    │
│  │  "Just open the email and   │    │
│  │   read the first line."     │    │
│  │                             │    │
│  │  [Start Focus ⏱️]  [Skip →] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── UPCOMING ──                     │
│                                     │
│  ┌────────────────┐ ┌────────────┐ │
│  │ 📧 Email boss  │ │ 🛒 Groceries│ │
│  │ ~10 min        │ │ ~30 min    │ │
│  └────────────────┘ └────────────┘ │
│  ┌────────────────┐ ┌────────────┐ │
│  │ 📄 Finish deck │ │ 📞 Call mom│ │
│  │ ~45 min        │ │ ~15 min    │ │
│  └────────────────┘ └────────────┘ │
│                                     │
│  + Add task                         │
│                                     │
│  ── TODAY'S STATS ──                │
│                                     │
│  ┌──────────┐ ┌──────────┐         │
│  │ ✅ 3 done│ │ ⏱️ 47 min │         │
│  └──────────┘ └──────────┘         │
│  ┌──────────┐ ┌──────────┐         │
│  │ 🎁 2     │ │ 💛 3 days│         │
│  │ rewards  │ │ active   │         │
│  └──────────┘ └──────────┘         │
│                                     │
│                    [+]              │
│  ┌────┬────┬────┬────┐             │
│  │Home│Brain│Foc.│Prof│             │
│  └────┴────┴────┴────┘             │
└─────────────────────────────────────┘
```

## C2. Dynamic Greeting & Encouragement

### Greeting Logic
```dart
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Still up? 🌙';
  if (hour < 12) return 'Good morning ☀️';
  if (hour < 17) return 'Good afternoon 🌤️';
  if (hour < 21) return 'Good evening 🌅';
  return 'Night owl mode 🦉';
}
```

### Encouragement Pool (15 rotating messages, never repeat two days in a row)
```dart
final encouragements = [
  "You've got this today.",
  "One thing at a time. That's enough.",
  "Progress, not perfection.",
  "Your brain works differently. That's a feature, not a bug.",
  "Starting is the hardest part. You already opened the app.",
  "You don't have to do it all. Just do one thing.",
  "Be kind to yourself today.",
  "Small steps count as steps.",
  "You showed up. That matters.",
  "The fact that you're reading this means you're trying.",
  "Done is better than perfect.",
  "You're not lazy. You're running a different operating system.",
  "Today's goal: one thing. Everything else is bonus.",
  "Rest is productive too.",
  "Your best looks different every day. That's okay.",
];
```

## C3. Day Progress Bar

- Width: Full card, Height: 8px
- Background: `surfaceElevated`, Fill: Gradient `primary` → `primaryLight`
- Border radius: `full`
- Animation: Fill animates from 0% to current % over 800ms on load
- Updates every minute (not real-time — battery preservation)

```dart
double getDayProgress() {
  final now = DateTime.now();
  final wake = user.wakeTime ?? TimeOfDay(hour: 7, minute: 0);
  final sleep = user.sleepTime ?? TimeOfDay(hour: 23, minute: 0);
  final total = sleep.inMinutes - wake.inMinutes;
  final elapsed = now.inMinutes - wake.inMinutes;
  return (elapsed / total).clamp(0.0, 1.0);
}
```

## C4. Energy Check-In

### Design
- Shows once per day on first home screen visit
- Shows again if user hasn't checked in for 4+ hours
- 5 emoji buttons in a row, 48px circles
- Selected: Background matches energy level, scale 1.1
- Others fade to 0.5 opacity

### Energy Levels
```dart
enum EnergyLevel {
  drained,   // 😫 — "Rest might be what you need right now"
  low,       // 😐 — "Let's keep it simple today"
  medium,    // 🙂 — "Good energy! Let's tackle some tasks"
  high,      // 😄 — "Great energy! Perfect for important stuff"
  superHigh, // 🔥 — "You're on fire! Let's make the most of it"
}
```

### Animations
| State | Animation | Duration |
|---|---|---|
| Unselected emojis | Gentle float (up/down 3px) | 3s loop, offset per emoji |
| Selection | Selected scales 1.2, others fade 0.5 | 300ms easeOut |
| Response text | Fade in below | 400ms |

### Logic
- Store: `energyLog: [{level: medium, timestamp: now}]`
- AI uses energy data for task selection
- Dismissed without selecting → default `medium`
- Card disappears after selection with fade-out (300ms)

## C5. Mood Check-In (NEW — Added from Gap Audit)

### Why This Exists
ADHD includes emotional dysregulation, rejection sensitivity, and mood swings. All competitors ignore this. Source: Reddit, ADHD Tracker app, Bearable app.

### Design
- Shown alongside energy check-in (same card, two rows)
- Same 5-emoji scale but for mood
- Separate from energy (mood ≠ energy)

```
┌─────────────────────────────────────┐
│                                     │
│  "How's your energy?"               │
│  😫  😐  🙂  😄  🔥                 │
│                                     │
│  "How are you feeling?"             │
│  😢  😔  😐  🙂  😄                 │
│                                     │
└─────────────────────────────────────┘
```

### Mood Levels
```dart
enum MoodLevel {
  rough,   // 😢
  low,     // 😔
  okay,    // 😐
  good,    // 🙂
  great,   // 😄
}
```

### Logic
- Store: `moodLog: [{mood: good, timestamp: now}]`
- AI uses mood + energy to adjust task suggestions
- Mood data enables correlation insights in V2

### AI Mood-Aware Task Selection
```dart
// When mood is low:
// AI adjusts to favor:
// 1. Self-care tasks (drink water, take a walk)
// 2. Quick wins (under 5 min)
// 3. Tasks with clear endpoints
// 4. Tasks "for me" not "for others"
//
// NEVER says "cheer up" or "it's not that bad"
// Says: "Low days call for easy wins. Let's start with something small."
```

## C6. "Your ONE Thing" Card

### Design
- Largest card on screen
- Background: Gradient `primary.withOpacity(0.05)` → `primary.withOpacity(0.12)`
- Border: 1.5px `primary.withOpacity(0.2)`
- Border radius: 16px, Padding: 20px

### Content Structure
```
🎯 (animated icon, gentle bounce, 2s loop)
Task Title (h2, bold)
~Estimated time · Category tag
"Italic micro-commitment text"

[Start Focus ⏱️]     [Skip →]
```

### Animations
| Element | Animation | Duration |
|---|---|---|
| 🎯 icon | Gentle bounce | 2s loop, scale 1.0→1.08→1.0 |
| Card entrance | Slide up + fade in | 500ms easeOut |
| "Start Focus" button | Gradient shimmer | 3s loop |
| Skip text | Opacity pulse | 2s loop, 0.5→1.0 |

### Logic
- "Start Focus" → Opens Focus Mode with this task pre-loaded
- "Skip →" → AI picks next best task (different one)
  - Current card: slide left + fade out (300ms)
  - New card: slide in from right + fade in (300ms)
- After 3 skips: "Want to try a brain dump instead?"
- If no tasks: "Nothing to do! Enjoy the calm 🌊" + "Add a task" button
- If all completed: "You did everything! 🎉" + celebration

## C7. Upcoming Tasks Grid

- Horizontal scroll of task chips (2 rows)
- Each chip: ~160px wide, ~80px tall
- Background: `surface`, Border: 1px `primaryLight.withOpacity(0.3)`
- Chip entrance: Stagger from bottom, 100ms per chip
- Chip tap: Scale to 0.95 (100ms) → back to 1.0 (100ms)
- Swipe right → Mark as done, Swipe left → Archive
- **Maximum 4 upcoming tasks shown** (Rule 1: max 3 primary choices)

## C8. Today's Stats (Shame-Free)

### Design
- 2x2 grid of stat cards
- Icon + number + label

### Stats
| Stat | Icon | Calculation |
|---|---|---|
| Tasks Done | ✅ | Count of completed tasks today |
| Focus Time | ⏱️ | Sum of focus session minutes today |
| Rewards Earned | 🎁 | Count of rewards unlocked today |
| Active Days | 💛 | Total active days this month |

### CRITICAL: Streak Logic (Shame-Free)
```
RULE 4: No word "streak" in the UI
RULE 6: No word "failed" or "missed"

Display rules:
- Active: "💛 3 days active" (warm, not fiery)
- Missed yesterday: "💛 Welcome back!"
- Missed 2+ days: "💛 Welcome back! You've been active 23 days total."
  (Show total, NOT broken streak)
- NEVER: "You broke your streak" or "Start over"
- NEVER: Red color for inactivity
```

```dart
class StreakDisplay {
  static String getDisplay(StreakData data) {
    if (data.isActiveToday) {
      return '💛 ${data.currentConsecutive} days active';
    } else if (data.daysSinceLastActive <= 1) {
      return '💛 Welcome back!';
    } else {
      return '💛 Welcome back! ${data.totalActiveDays} days active total.';
    }
  }
  
  // NEVER return "0 days" or "streak broken"
  // NEVER use red color
  // NEVER use the word "streak"
}
```

## C9. Task Detail Bottom Sheet

```
┌─────────────────────────────────────┐
│  ━━━━━━━━ (drag handle)            │
│                                     │
│  📧 Reply to Sarah's email          │
│                                     │
│  Status: Not started                │
│  Time: ~15 min                      │
│  Energy needed: Low                 │
│  Added: Today                       │
│  Schedule: Today / Anytime / Someday│
│                                     │
│  ───────────────────────────────    │
│                                     │
│  Notes (optional):                  │
│  ┌─────────────────────────────┐    │
│  │ She asked about the Q3      │    │
│  │ report deadline...           │    │
│  └─────────────────────────────┘    │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  [Start Focus ⏱️]                   │
│  [Mark as Done ✅]                  │
│  [Break this down 🔨]               │
│  [Move to Someday 📦]               │
│  [Edit ✏️]                          │
│                                     │
└─────────────────────────────────────┘
```

---

# SECTION D: BRAIN DUMP (Task Capture)

## D1. Core Philosophy
- Capture speed is everything — 2 taps max
- No categories during dump — just type/shout
- No validation — "buy milk" is as valid as "figure out life purpose"
- Celebration after dumping — every dump is an achievement
- **Maximum 2 taps for any action (Rule 2)**

## D2. Screen Layout

```
┌─────────────────────────────────────┐
│  ← Back           Brain Dump 🧠     │
│                                     │
│  "Just dump it. Don't think.        │
│   Don't organize. Just type."       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Type or speak anything...   │    │
│  └─────────────────────────────┘    │
│  [🎤 Voice]                        │
│                                     │
│  Suggestions:                       │
│  [📧 Email] [🛒 Shopping] [📞 Call] │
│  [🧹 Clean] [📄 Work] [💊 Health]   │
│                                     │
│  ── Dumped ──                       │
│                                     │
│  1. 📧 Reply to Sarah    [×]       │
│  2. 🛒 Buy groceries     [×]       │
│  3. 📄 Finish presentation [×]     │
│  4. 📞 Call dentist       [×]      │
│  5. 🧹 Clean kitchen      [×]      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   Done dumping! Pick ONE    │    │
│  │   thing for me → 🎯         │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

## D3. Text Input
- Auto-focus on screen open
- Placeholder cycles: "Type anything...", "What's swirling?", "Dump it here..."
- Submit on Enter (no send button tap needed)
- After submit: Field clears instantly, task appears in list
- No minimum character length

## D4. Voice Input
- Microphone button next to text field
- Tap to start, tap again or auto-stop after 10s silence
- While recording: Pulsing red dot + waveform visualization
- Uses device native STT (speech-to-text)
- After transcription: Task appears with `source: 'voice'`

## D5. Quick-Add Chips & Common Task Templates (NEW)

### Quick-Add Chips
Shown below input as horizontal scroll:
```
[📧 Email] [🛒 Shopping] [📞 Call] [🧹 Clean] [📄 Work] [💊 Health]
```
Tapping pre-fills the input with that category prefix.

### Common Task Templates (When User Is Stuck)
```dart
final commonTasks = [
  // Self-care
  "Brush teeth", "Take medication", "Drink water", "Eat lunch",
  "Shower", "Go for a walk", "Stretch for 5 min",
  // Household
  "Do dishes", "Take out trash", "Laundry", "Clean one room",
  "Grocery shopping", "Cook dinner", "Make bed",
  // Work
  "Check email", "Reply to message", "Finish report",
  "Attend meeting", "Review document",
  // Social
  "Call friend", "Text mom", "Reply to message", "Plan something fun",
  // Life admin
  "Pay bill", "Book appointment", "Return package",
  "Cancel subscription", "Update profile",
];
```

**Why this exists:** Reddit user quote: *"Where's a database of tasks so I can use your app? Like MyFitnessPal has every barcode on the planet."*

## D6. Task Entry Animations
| Animation | Duration | Easing |
|---|---|---|
| New task entry | Slide from right + fade | 300ms easeOut |
| Task number | Scale 0→1 | 200ms easeOutBack |
| Delete (× tap) | Slide out left + fade | 250ms easeIn |
| List reflow | Smooth height | 200ms easeInOut |
| Input clear | Instant | — |

Haptic: `lightImpact()` on add, `selectionClick()` on delete, `mediumImpact()` on "Done dumping"

## D7. Voice Dump Mode
```
┌─────────────────────────────────────┐
│         🎤 Voice Dump Mode          │
│    ┌─────────────────────────┐      │
│    │  [Waveform animation]   │      │
│    └─────────────────────────┘      │
│    "Just talk. We'll catch it all." │
│    Listening... 🔴                   │
│    [Stop & Process]                 │
└─────────────────────────────────────┘
```
- Continuous listening (doesn't stop between tasks)
- Pauses → new task entry
- "Stop & Process" → Processes all audio into task list

## D8. Brain Dump Celebration

After dumping 3+ tasks:
```
┌─────────────────────────────────────┐
│         🎉 Nice dumping!            │
│    5 things out of your head.       │
│    That takes courage.              │
│                                     │
│    [Pick ONE thing for me →]        │
│    Or see all tasks                 │
└─────────────────────────────────────┘
```
- Confetti: 30 particles, 1.5s
- "Pick ONE thing" → AI selection → Home screen

---

# SECTION E: TASK MANAGEMENT SYSTEM (NEW SECTION)

## E1. Task Data Model (Expanded)

```dart
class Task {
  final String id;
  final String title;
  final String? description;
  final String emoji;
  final TaskCategory category;
  final TaskStatus status;
  final EnergyRequired energyRequired;
  final int estimatedMinutes;
  final int? actualMinutes;
  final bool isPriority;
  final TaskSource source;           // text, voice, chip, import
  final TaskScheduleType scheduleType; // NEW: today, thisWeek, anytime, someday
  final DeadlineType deadlineType;    // NEW: none, soft, hard, flexible
  final DateTime? deadline;           // NEW
  final List<Subtask> subtasks;       // NEW
  final String notes;
  final RecurrenceRule? recurrence;   // NEW
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime? movedToSomedayAt;   // NEW
  final int focusSessionCount;
  final String? brainDumpSessionId;
  final bool promptedForRelevance;    // NEW: 7-day prompt flag
}

enum TaskStatus { notStarted, inProgress, completed, archived, someday }
enum TaskCategory { email, shopping, work, health, clean, call, social, selfCare, admin, other }
enum TaskSource { text, voice, chip, import, template, recurring }
enum EnergyRequired { low, medium, high }
enum TaskScheduleType { today, thisWeek, anytime, someday }
enum DeadlineType { none, soft, hard, flexible }

class Subtask {
  final String id;
  final String title;
  final int estimatedMinutes;
  final bool isCompleted;
  final int order;
}
```

## E2. Task Schedule Types

```dart
enum TaskScheduleType {
  today,     // Must do today (high priority, shown on home screen)
  thisWeek,  // Sometime this week (shown in week view)
  anytime,   // No specific day (shown when energy matches)
  someday,   // Aspirational, no pressure (hidden by default)
}
```

### Visibility Rules
| Schedule Type | Home Screen | Day View | Week View | Someday List |
|---|---|---|---|---|
| today | ✅ Shown | ✅ Shown | ✅ Shown | ❌ |
| thisWeek | ❌ | ✅ Shown | ✅ Shown | ❌ |
| anytime | ❌ (unless energy match) | ✅ "Also Available" | ✅ | ❌ |
| someday | ❌ | ❌ | ❌ | ✅ Only here |

### Brain Dump Default
- All brain-dumped tasks default to `today`
- After dumping, AI asks: "Are all of these for today, or are some more like 'someday' ideas?"
- User can quickly swipe tasks to Someday

## E3. Someday/Maybe List (NEW)

### Why This Exists
Reddit user quote: *"I dump too much aspirational stuff and task ideas in there, and then have trouble filtering the signal from the noise."*

### Screen Layout
```
┌─────────────────────────────────────┐
│  ← Back      Someday / Maybe 📦     │
│                                     │
│  "No pressure. These are here       │
│   whenever you're ready."           │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🎨 Learn watercolor         │    │
│  │ Added 12 days ago           │    │
│  │ [Move to Today] [Delete]    │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📚 Read "Atomic Habits"     │    │
│  │ Added 8 days ago            │    │
│  │ [Move to Today] [Delete]    │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🏃 Train for a 5K           │    │
│  │ Added 23 days ago           │    │
│  │ [Move to Today] [Delete]    │    │
│  └─────────────────────────────┘    │
│                                     │
│  Accessible via: Profile → Someday  │
│  Count NOT shown on home screen     │
│  No reminders, no pressure          │
│                                     │
└─────────────────────────────────────┘
```

### Rules
- **No count shown on home screen** (Rule 7)
- **No reminders for someday tasks** (no notifications)
- Accessible only via Profile → Someday/Maybe
- Tasks can be moved back to Today anytime
- Auto-pruning: Tasks in Someday for 30+ days get prompt "Still want this?"

## E4. Auto-Pruning System (NEW)

### Why This Exists
Reddit user quote: *"The huge backlog of things I have entered (but am not doing) starts to weigh me down and get overwhelming."*

```dart
class TaskPruningService {
  static const int gentlePromptDays = 7;
  static const int autoArchiveToSomedayDays = 14;
  static const int somedayExpirationDays = 30;
  
  static Future<void> processOldTasks(List<Task> tasks) async {
    for (final task in tasks) {
      final age = DateTime.now().difference(task.createdAt).inDays;
      
      // Rule 1: 7 days no activity → gentle prompt
      if (age >= gentlePromptDays && 
          task.status == TaskStatus.notStarted && 
          !task.promptedForRelevance) {
        await task.markPrompted();
        // In-app prompt: "This has been sitting for a while. Still relevant?"
        // [Yes, keep it] [Move to Someday] [Delete]
      }
      
      // Rule 2: 14 days no activity → auto-move to Someday
      if (age >= autoArchiveToSomedayDays && 
          task.status == TaskStatus.notStarted) {
        await task.moveToSomeday();
        // Notification: "Moved '[task]' to your Someday list. 
        // It's there whenever you're ready. 💛"
      }
      
      // Rule 3: 30 days in Someday → prompt to keep or delete
      if (task.scheduleType == TaskScheduleType.someday &&
          task.movedToSomedayAt != null &&
          DateTime.now().difference(task.movedToSomedayAt!).inDays >= somedayExpirationDays) {
        // Prompt: "Still want '[task]'? [Yes] [Delete]"
        // Never auto-delete
      }
    }
  }
  
  // CRITICAL: Active task list should NEVER exceed 20 tasks
  // If it does: "You've got a lot on your plate. 
  //             Want to move some to Someday? [Yes, help me] [I'm fine]"
}
```

### Rules
- **No task ever auto-deletes** (Rule 13) — soft delete only, recoverable for 30 days
- **No "overdue" labels** (Rule 5)
- **No count of old/pending tasks shown** (Rule 7)
- All pruning is gentle and reversible

## E5. Flexible Recurring Tasks (NEW)

### Why This Exists
Tiimo user quote: *"I want to repeat an activity every three days but it doesn't give me that option."*

```dart
class RecurrenceRule {
  final RecurrenceType type;
  final int interval;           // Every N days/weeks/months
  final List<int>? daysOfWeek;  // [1,3,5] = Mon, Wed, Fri
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? maxOccurrences;
}

enum RecurrenceType {
  daily,
  weekly,
  everyNDays,     // Every 2, 3, 4, 5... days
  everyNWeeks,
  monthly,
  weekdaysOnly,
  weekendsOnly,
  custom,
}
```

### Recurring Task Behavior
- Recurring tasks auto-appear on their scheduled day
- No re-creation needed
- Can be marked done independently each day
- Skipping one occurrence doesn't affect future occurrences
- Edit series: "Change all future" or "Just this one"

## E6. Deadline Types (NEW)

### Why This Exists
Reddit user quote: *"Throw an alert at me when something is in the danger zone on missing a hard deadline and not my soft should-do deadlines."*

```dart
enum DeadlineType {
  none,      // No deadline (anytime task)
  soft,      // "I'd like to do this by Friday" — no alerts
  hard,      // "This MUST be done by Friday" — alerts at 24h, 2h
  flexible,  // "Sometime this month" — gentle reminder on last week
}
```

### Hard Deadline Behavior
- Show in task card with ⏰ icon
- Alert at 24 hours: "Hey, [task] is due tomorrow"
- Alert at 2 hours: "[task] is due soon. Want to start now?"
- **NEVER show as "overdue"** (Rule 5) — show as "Due today" until end of day
- After deadline passes: "This passed its deadline. [Reschedule] [Done] [Archive]"

## E7. Task Search & Filter (NEW)

### Why This Exists
Tiimo/Inflow gap: No search function.

```
┌─────────────────────────────────────┐
│  🔍 Search tasks...                 │
│                                     │
│  Filter by:                         │
│  [All] [Today] [This Week] [Anytime]│
│  [Energy: Low] [Category: Work]     │
│                                     │
│  ── Results ──                      │
│  📧 Reply to Sarah · Today          │
│  📄 Finish deck · This Week         │
│  📞 Call dentist · Anytime          │
└─────────────────────────────────────┘
```

- Pull-down on Home Screen reveals search bar
- Search: task title, notes, category
- Filter: status, energy level, date added, category, schedule type
- Recent searches saved

## E8. Honest Completion Check (NEW)

### Why This Exists
Reddit user quote: *"I just ticked off tasks without actually completing them."*

```dart
// After marking task as done, occasionally (20% of the time):
// "Quick check: Did you actually do this, or just want it off your list?"
// [I did it! ✅] [Just clearing it 🧹]
//
// If "Just clearing it":
// "No judgment! Want to move it to Someday? [Yes] [Delete]"
//
// This data helps AI learn which tasks the user consistently avoids
// → Suggest breaking them down or removing them
```

---

# SECTION F: "PICK ONE THING" AI ENGINE

## F1. Hybrid Selection Algorithm

```dart
class TaskSelector {
  Future<Task> pickOneThing({
    required List<Task> tasks,
    required EnergyLevel currentEnergy,
    required MoodLevel currentMood,      // NEW
    required List<AdhdTrait> adhdTraits,
    required TimeOfDay currentTime,
    required UserPreferences prefs,
  }) async {
    // STEP 1: Rule-based filtering (fast, no API call)
    final filtered = _applyRules(tasks, currentEnergy, currentTime);
    
    // STEP 2: If 1 task, return it
    if (filtered.length == 1) return filtered.first;
    
    // STEP 3: If 2-5 tasks, use scoring
    if (filtered.length <= 5) return _scoreAndPick(filtered, currentEnergy, currentMood, adhdTraits);
    
    // STEP 4: If 6+ tasks, use AI
    return await _aiPick(filtered, currentEnergy, currentMood, adhdTraits, prefs);
  }
  
  List<Task> _applyRules(List<Task> tasks, EnergyLevel energy, TimeOfDay time) {
    return tasks.where((task) {
      if (task.estimatedMinutes > _availableMinutes(time)) return false;
      if (energy == EnergyLevel.drained && task.energyRequired != EnergyRequired.low) return false;
      if (energy == EnergyLevel.low && task.energyRequired == EnergyRequired.high) return false;
      if (task.status == TaskStatus.archived || task.status == TaskStatus.completed) return false;
      if (task.scheduleType == TaskScheduleType.someday) return false;
      return true;
    }).toList();
  }
  
  Task _scoreAndPick(List<Task> tasks, EnergyLevel energy, MoodLevel mood, List<AdhdTrait> traits) {
    final scored = tasks.map((task) {
      double score = 0;
      
      // Energy match (highest weight)
      score += _energyMatchScore(task.energyRequired, energy) * 3.0;
      
      // Mood adjustment (NEW)
      if (mood == MoodLevel.rough || mood == MoodLevel.low) {
        if (task.energyRequired == EnergyRequired.low) score += 3.0; // Prefer easy tasks when sad
        if (task.estimatedMinutes <= 5) score += 2.0;
      }
      
      // Shorter tasks preferred when overwhelmed
      score += (1.0 - (task.estimatedMinutes / 120)).clamp(0, 1) * 2.0;
      
      // Newer tasks score higher (momentum)
      final age = DateTime.now().difference(task.createdAt).inDays;
      score += (1.0 - (age / 30)).clamp(0, 1) * 1.5;
      
      // ADHD trait matching
      if (traits.contains(AdhdTrait.taskParalysis) && task.estimatedMinutes <= 10) score += 2.0;
      if (traits.contains(AdhdTrait.timeBlindness) && task.deadlineType != DeadlineType.none) score += 1.5;
      
      // Priority flag
      if (task.isPriority) score += 1.0;
      
      // Randomness (prevents same task every time)
      score += Random().nextDouble() * 0.5;
      
      return MapEntry(task, score);
    }).toList();
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.first.key;
  }
}
```

## F2. AI Task Selection (GPT-4o-mini)

### System Prompt
```
You are Ekagra, a gentle and warm ADHD task selector. Your ONLY job is to pick 
ONE task for someone with ADHD to start right now.

PERSONALITY:
- You're like a kind friend, not a productivity coach
- You never shame, guilt, or pressure
- You celebrate starting, not just finishing
- You understand ADHD brains struggle with task initiation
- You use casual, warm language with occasional emojis

RULES:
1. ALWAYS pick the task most likely to get STARTED (not the most important)
2. Prefer quick wins (under 10 min) when user seems overwhelmed
3. Match task difficulty to current energy AND mood level
4. Never pick the same task twice in a row
5. Explain your choice in 1-2 short sentences
6. Suggest a micro-commitment (the tiniest possible first step)
7. If energy is very low or mood is rough, suggest the easiest possible task
8. Keep all text under 100 characters per field
9. NEVER use shame language (no "you should", "you need to", "don't forget")

RESPOND IN VALID JSON ONLY.
```

### User Prompt Template
```
The user has ADHD (traits: {traits}).
Their current energy: {energy} (drained/low/medium/high/superHigh)
Their current mood: {mood} (rough/low/okay/good/great)
Current time: {time}
{lastSelectedTaskId != null ? 'They just skipped task $lastSelectedTaskId — pick something DIFFERENT.' : ''}
They have {taskCount} tasks:

{tasks_json}

Pick ONE task. Respond in JSON:
{
  "selectedTaskId": "the_id",
  "reason": "Short reason (under 80 chars)",
  "encouragement": "Micro-commitment (under 80 chars)",
  "emoji": "single emoji"
}
```

### Response Model
```dart
class AiTaskSelection {
  final String selectedTaskId;
  final String reason;
  final String encouragement;
  final String emoji;
  
  factory AiTaskSelection.fromJson(Map<String, dynamic> json) {
    return AiTaskSelection(
      selectedTaskId: json['selectedTaskId'],
      reason: json['reason'] ?? "This one feels right for now.",
      encouragement: json['encouragement'] ?? "Just start for 2 minutes.",
      emoji: json['emoji'] ?? '🎯',
    );
  }
}
```

### Cost Estimation
```
GPT-4o-mini: ~$0.00015 per request
At 5 requests/user/day, 1000 users: $22.50/month
Verdict: Extremely cheap.
```

## F3. Mood-Aware Task Selection (NEW)

When mood is low, AI adjusts:
- Favors self-care tasks (drink water, take a walk)
- Favors quick wins (under 5 min)
- Favors tasks with clear endpoints
- Avoids tasks that require emotional labor (difficult conversations, etc.)
- NEVER says "cheer up" or "it's not that bad"
- Says: "Low days call for easy wins. Let's start with something small. 💛"

## F4. Micro-Commitment Generation

### System Prompt
```
You are Ekagra. Generate a micro-commitment for an ADHD user.
A micro-commitment is the TINIEST possible first step. Under 60 seconds. Almost zero effort.

Examples:
"Reply to Sarah's email" → "Just open the email and read the first sentence"
"Clean the kitchen" → "Just put one dish in the dishwasher"
"Finish presentation" → "Just open the file and look at slide 1"
"Exercise" → "Just put on your workout clothes"

Respond with ONLY the micro-commitment text. Max 80 characters.
```

## F5. Fallback Logic

```dart
AiTaskSelection _fallbackSelection(List<Task> tasks, EnergyLevel energy, MoodLevel mood) {
  tasks.sort((a, b) {
    int aScore = _energyMatch(a.energyRequired, energy) * 100 + (120 - a.estimatedMinutes);
    int bScore = _energyMatch(b.energyRequired, energy) * 100 + (120 - b.estimatedMinutes);
    // Mood adjustment
    if (mood == MoodLevel.rough || mood == MoodLevel.low) {
      if (a.energyRequired == EnergyRequired.low) aScore += 200;
      if (b.energyRequired == EnergyRequired.low) bScore += 200;
    }
    return bScore.compareTo(aScore);
  });
  
  return AiTaskSelection(
    selectedTaskId: tasks.first.id,
    reason: "This one feels right for now.",
    encouragement: "Just start for 2 minutes. That's all.",
    emoji: tasks.first.emoji,
  );
}
```

## F6. AI Caching Strategy

```dart
class AiCacheService {
  // Cache energy insights (valid 4 hours)
  // Cache micro-commitments (valid 7 days — same task, same commitment)
  // Cache mood insights (valid 4 hours)
  // All cached in SharedPreferences
}
```

---

# SECTION G: VISUAL TIME COMPASS (Day View)

## G1. Screen Layout

```
┌─────────────────────────────────────┐
│  ← Back          Your Day 📅        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  ████████████░░░░░░  58%    │    │
│  │  2:14 PM · Thursday         │    │
│  └─────────────────────────────┘    │
│                                     │
│  ⚡ Energy: ████░░░░ Medium          │
│  💛 Mood: 🙂 Good                    │
│  Best for: Steady work, calls       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ NOW                         │    │
│  │ ┌───────────────────────┐   │    │
│  │ │ 📧 Reply to Sarah     │   │    │
│  │ │ ████████░░ 80% done   │   │    │
│  │ │ 12 min left           │   │    │
│  │ └───────────────────────┘   │    │
│  │                             │    │
│  │ ┌───────────────────────┐   │    │
│  │ │ 💤 Free · 45 min      │   │    │  ← NEW: Gap visualization
│  │ │ "Time for a break or  │   │    │
│  │ │  another task?"        │   │    │
│  │ └───────────────────────┘   │    │
│  │                             │    │
│  │ 3:00 PM                     │    │
│  │ ┌───────────────────────┐   │    │
│  │ │ 🎨 Design review      │   │    │
│  │ │ ░░░░░░░░░░ Not started │   │    │
│  │ │ ~45 min               │   │    │
│  │ └───────────────────────┘   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  💡 "Your peak focus time   │    │
│  │     is usually 10-12 PM."   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ← Yesterday    Tomorrow →          │
│                                     │
│                    [+]              │
│  ┌────┬────┬────┬────┐             │
│  │Home│Brain│Foc.│Prof│             │
│  └────┴────┴────┴────┘             │
└─────────────────────────────────────┘
```

## G2. Free Time Gap Visualization (NEW)

### Why This Exists
Tiimo user quote: *"I wish there was a way to see gaps in the day."*

### Design
```
┌───────────────────────────────┐
│ 💤 Free · 45 min              │
│ "Time for a break or          │
│  another task?"               │
│ [Add task] [Keep free]        │
└───────────────────────────────┘
```

- Background: Dashed border, `primaryLight.withOpacity(0.2)`
- Icon: 💤 (sleeping, relaxed)
- Shows duration of free time
- "Add task" → Opens brain dump with time slot pre-filled
- "Keep free" → Dismisses, marks slot as intentionally free

## G3. Rolling 7-Day View (NEW)

### Why This Exists
Tiimo user quote: *"The lack of a rolling seven-day calendar means the following week always sneaks up as a surprise."*

### Behavior
- Day View is horizontally swipeable
- Today is always centered
- Swipe left: Yesterday (collapsed, just stats)
- Swipe right: Tomorrow, day after, etc.
- Shows 7 days: today + next 6
- NOT Monday-Sunday calendar view
- Smooth page transition: 300ms easeInOut

## G4. Drag-to-Reschedule (V1.1)

- Tasks in Day View are draggable
- Drag to new time slot → Updates task time
- If "auto-adjust" is on → shifts all subsequent tasks
- Haptic: `mediumImpact()` on pickup, `lightImpact()` on drop
- Shows ghost of task during drag (50% opacity)

## G5. Energy Insight Card

### AI Prompt
```
The user's current energy is: {energy} (1-5)
Their current mood is: {mood} (1-5)
Current time: {time}
Tasks today: {count}, Completed: {doneCount}

In 1 sentence, what type of tasks should they focus on right now?
Be warm, practical, specific. Never shame low energy or low mood.
```

### Example Outputs
| Energy | Mood | Time | AI Response |
|---|---|---|---|
| High | Great | 10 AM | "Perfect time to tackle something big — your brain is on fire! 🔥" |
| Low | Low | 3 PM | "Easy wins only right now. That dentist call is just 5 minutes." |
| Drained | Rough | 8 PM | "You've done enough today. Rest is productive too. 💛" |
| Medium | Good | 11 AM | "Solid energy! Knock out the design review — it needs focus but not superpowers." |

## G6. Smart Task Visibility (NEW)

### Why This Exists
Tiimo user quote: *"I don't love that the daily calendar shows my completed tasks. It creates confusion."*

```dart
enum CompletedTaskVisibility {
  collapsed,  // DEFAULT: "3 done ✓" — tap to expand
  expanded,   // Show all completed
  hidden,     // Don't show at all
}

// Settings → Day View → Completed Tasks
```

### Rules
- Maximum 5 tasks visible on Day View by default
- "Also Available" section shows max 3 anytime tasks
- Completed tasks collapse into "3 done ✓" counter
- Tap to expand

---

# SECTION H: FOCUS MODE

## H1. Screen Layout

```
┌─────────────────────────────────────┐
│  ← Exit Focus        Focus Mode 🎯  │
│                                     │
│         ┌─────────────────┐         │
│         │    ╭────────╮   │         │
│         │    │ 14:32  │   │         │
│         │    ╰────────╯   │         │
│         │                 │         │
│         │  Reply to Sarah │         │
│         │  "Just read the │         │
│         │   first line"   │         │
│         │                 │         │
│         └─────────────────┘         │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  15m    25m    45m    Custom │   │
│  │  ○      ●      ○      ○     │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  ⏸ Pause │  │ ✅ Done!  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  😵 Can't focus?             │   │
│  │  (It's okay. Let's adjust.)  │   │
│  └──────────────────────────────┘   │
│                                     │
│  🌧️ Rain    🎵 Lofi    ☕ Café      │
│                                     │
└─────────────────────────────────────┘
```

## H2. Focus Ring (Central Timer)

### Design
- 200px diameter circle
- Ring thickness: 6px
- Background: `surfaceElevated`
- Active: Gradient `focusActive` → `primaryLight`
- Timer text: `h1` (32px), centered

### Ring States
| State | Color | Animation |
|---|---|---|
| COUNTDOWN | Primary violet gradient | Ring fills 0°→360°, subtle pulse every second |
| PAUSED | Warning amber | Dashed border rotates slowly (4s loop) |
| COMPLETE | Success green | Celebratory pulse (scale 1.0→1.08→1.0, 3x) + particle burst |
| OVERTIME | Still green (never red!) | "+2:15" format, "You're in the zone!" |

## H3. Bulletproof Timer Logic (NEW)

### Why This Exists
Tiimo's #1 bug: timers don't pause correctly, add unexpected time, drift when backgrounded.

```dart
class FocusTimerController extends ChangeNotifier {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  Duration _planned = Duration.zero;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _totalPaused = Duration.zero;
  TimerState _state = TimerState.idle;
  
  // CRITICAL: Use DateTime for timing, NOT incremental Timer ticks
  // This prevents drift from app backgrounding
  
  void start(Duration duration) {
    _planned = duration;
    _remaining = duration;
    _startedAt = DateTime.now();
    _totalPaused = Duration.zero;
    _state = TimerState.running;
    _startTicking();
    _keepScreenAwake();  // Wakelock: screen stays on
  }
  
  void pause() {
    if (_state != TimerState.running) return;
    _pausedAt = DateTime.now();
    _state = TimerState.paused;
    _ticker?.cancel();
    _allowScreenSleep();
  }
  
  void resume() {
    if (_state != TimerState.paused || _pausedAt == null) return;
    _totalPaused += DateTime.now().difference(_pausedAt!);
    _pausedAt = null;
    _state = TimerState.running;
    _startTicking();
    _keepScreenAwake();
  }
  
  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(seconds: 1), (_) {
      if (_startedAt == null) return;
      final elapsed = DateTime.now().difference(_startedAt!) - _totalPaused;
      _remaining = _planned - elapsed;
      
      if (_remaining <= Duration.zero) {
        _remaining = Duration.zero;
        _state = TimerState.complete;
        _ticker?.cancel();
        _allowScreenSleep();
        _onComplete();
      }
      notifyListeners();
    });
  }
  
  // Handle app lifecycle (backgrounding)
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _ticker?.cancel();  // Timer keeps running (DateTime-based)
        break;
      case AppLifecycleState.resumed:
        if (_state == TimerState.running) _startTicking();  // Recalculates from DateTime
        break;
    }
  }
  
  void _keepScreenAwake() async => await WakelockPlus.enable();
  void _allowScreenSleep() async => await WakelockPlus.disable();
}

enum TimerState { idle, running, paused, complete }
```

### Key Guarantees
- Timer uses `DateTime.now()` comparison (no drift)
- `WakelockPlus` keeps screen on during focus (no "screen goes dark" bug)
- App lifecycle handling: timer continues when backgrounded
- On resume: recalculates from `DateTime` (no accumulated error)
- Notification: shows remaining time when app is backgrounded

## H4. Timer Duration Selector

| Duration | Label | Use Case |
|---|---|---|
| 15 min | "Quick burst ⚡" | ADHD micro-sessions |
| 25 min | "Classic 🍅" | Standard Pomodoro |
| 45 min | "Deep dive 🏊" | Flow state |
| Custom | "My pace 🎯" | Slider 5-120 min, 5-min steps |

## H5. Control Buttons

### Pause/Resume
- Tap pause: Timer stops, ring changes to amber dashed
- Tap resume: Timer continues
- During pause: "Take your time. No rush."
- Auto-pause after 5 min of no interaction

### Done!
- Tap to complete: Celebration → Reward reveal
- If timer not complete: "Finishing early? That's still a win! ✅"
- Records partial session as completed (no penalty)

### "Can't Focus?" Button
```
┌─────────────────────────────────────┐
│  "It's okay. Let's figure this out."│
│                                     │
│  🔄 Switch tasks                    │
│  🤝 Body double with someone        │
│  ⏸ Take a break                     │
│  🍫 Need a dopamine hit?            │
└─────────────────────────────────────┘
```

| Option | Behavior |
|---|---|
| Switch tasks | AI picks next best task → New session |
| Body double | Opens Body Doubling screen |
| Take a break | 5-min break timer → "Ready to continue?" |
| Dopamine hit | Random quick reward → "Feeling better? Let's try again" |

## H6. Ambient Sound System

| Sound | File | Description |
|---|---|---|
| 🌧️ Rain | rain_ambient.mp3 | Gentle rain, no thunder |
| 🎵 Lofi | lofi_beats.mp3 | Low-fi hip hop instrumental |
| ☕ Café | cafe_ambient.mp3 | Coffee shop background |
| 🌊 Ocean | ocean_waves.mp3 | Gentle wave sounds |
| 🔥 Fireplace | fireplace.mp3 | Crackling fire |
| 🌲 Forest | forest_ambient.mp3 | Birds, leaves, nature |
| 🔇 None | — | Silent mode |

- Free tier: Rain + Lofi only
- Pro: All 6 sounds
- All loop seamlessly
- Fade out over 3s when session ends
- Volume follows system volume

## H7. Transition Sounds (NEW)

```dart
class TransitionSoundService {
  // When focus timer ends or activity switches:
  // Play a gentle chime (NOT jarring alarm)
  
  static const transitionSounds = [
    'sounds/gentle_chime.mp3',      // Default
    'sounds/warm_bell.mp3',         // Alternative
    'sounds/soft_notification.mp3', // Minimal
    'sounds/none',                  // Silent
  ];
  
  // User selects in Settings → Sounds
  // Volume follows system volume
  // Respect Do Not Disturb
}
```

## H8. Focus Mode Distraction Blocking (NEW)

```dart
// During Focus Mode:
// 1. Do Not Disturb: auto-enable when focus starts
// 2. App blocking (Android): block social media apps
//    - Uses Android UsageStats API
//    - User selects which apps to block
//    - iOS: Show "Screen Time" prompt instead
// 3. Full-screen mode: Hide notification bar
// 4. "Emergency exit": Double-tap to leave (prevents accidental exits)
```

## H9. Hyperfocus Support (NEW)

### Why This Exists
Reddit user quote: *"I just stopped the app whenever my brain decided to focus."*

```dart
// When focus timer expires but user is still active:
// 1. Don't force-stop (no jarring alarm)
// 2. Gentle notification: "You've been focused for 45 min. 
//    Still going? [Keep going] [Take a break]"
// 3. Track hyperfocus duration for analytics
// 4. After 2+ hours: Stronger suggestion
//    "You're in the zone! Quick water break? 💧"
// 5. NEVER shame hyperfocus — it's a superpower when managed
```

## H10. Focus Session Complete Flow

### Sequence
```
1. Timer hits 0:00
   → Ring turns green + pulse animation
   → Haptic: Heavy impact
   → Sound: Gentle chime

2. Confetti burst (50 particles, 2s)

3. Stats card:
   ┌─────────────────────────────┐
   │   🎉 Focus session done!    │
   │                             │
   │   25 minutes of focus       │
   │   Task: Reply to Sarah      │
   │                             │
   │   [Mark as done ✅]         │
   │   [Keep going ⏱️]          │
   │   [Reward time! 🎁]        │
   └─────────────────────────────┘

4. Mark as done → Task complete → Reward reveal
5. Keep going → Timer starts another session
6. Reward time → Direct to reward reveal
```

## H11. No Forced Breaks Between Sessions (NEW)

```dart
// Focus sessions can be chained:
// - "Keep going" option at end of each session
// - NO mandatory break between sessions
// - Gentle suggestion after 2+ hours: "You've been focused for 2 hours.
//   A short break might help you go even longer."
// - User can always override
```

### Session Data
```dart
class FocusSession {
  final String id;
  final String taskId;
  final int plannedMinutes;
  final int actualMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FocusOutcome outcome;  // completed, early, abandoned, overtime, hyperfocus
  final String? ambientSound;
  final bool bodyDoubled;
  final EnergyLevel energyAtStart;
  final EnergyLevel? energyAtEnd;
  final MoodLevel? moodAtStart;      // NEW
  final MoodLevel? moodAtEnd;        // NEW
  final int pauseCount;
  final int totalPauseSeconds;
}
```

---

# SECTION I: DOPAMINE MENU & REWARD ENGINE

## I1. Variable Ratio Reinforcement Engine

```dart
class RewardEngine {
  static const int minTasksForReward = 1;
  static const int maxTasksForReward = 4;
  
  int getNextRewardThreshold({
    required int tasksSinceLastReward,
    required int totalTasksToday,
    required bool isStreakDay,
  }) {
    if (tasksSinceLastReward >= 5) return tasksSinceLastReward; // Force reward
    int base = Random().nextInt(maxTasksForReward - minTasksForReward + 1) + minTasksForReward;
    if (totalTasksToday == 1) return 1; // First task always gets reward
    if (isStreakDay) base = (base * 0.8).ceil();
    return base;
  }
}

RewardTier selectRewardTier({
  required int focusMinutes,
  required TaskDifficulty taskDifficulty,
  required bool isFirstTaskOfDay,
}) {
  if (focusMinutes >= 45) return RewardTier.big;
  if (focusMinutes >= 15) return RewardTier.medium;
  if (taskDifficulty == TaskDifficulty.high) return RewardTier.medium;
  if (isFirstTaskOfDay) return RewardTier.quick;
  return RewardTier.quick;
}
```

## I2. Reward Reveal Screen

### Animation Sequence
```
STAGE 1: Mystery Box (1.5s)
┌─────────────────────────────────────┐
│         ┌─────────────────┐         │
│         │    ┌───────┐    │         │
│         │    │  🎁   │    │         │
│         │    └───────┘    │         │
│         │   Tap to open!  │         │
│         └─────────────────┘         │
└─────────────────────────────────────┘
Box animation: Gentle bounce (scale 1.0→1.05→1.0, 1s loop)
Haptic: lightImpact on bounce

STAGE 2: Opening (0.8s)
- Box lid lifts up (translateY -50, opacity fade)
- Light rays burst from inside (12 rays)
- Haptic: mediumImpact

STAGE 3: Reveal (1.2s)
┌─────────────────────────────────────┐
│         ✨ Your reward! ✨           │
│         ┌─────────────────┐         │
│         │    🎵           │         │
│         │  Listen to 1    │         │
│         │  hype song      │         │
│         │  "Go put on     │         │
│         │   your favorite │         │
│         │   banger."      │         │
│         └─────────────────┘         │
│    [Claim reward 🎉]                │
│    [Skip (save for later)]          │
└─────────────────────────────────────┘
Reward emoji: Scale 0→1.2→1.0 (400ms easeOutBack)
Confetti: 60 particles, 2s
Haptic: heavyImpact
```

## I3. Rare / Special Rewards (~5% chance)

```dart
final rareRewards = [
  RareReward(emoji: '🌈', title: 'Rainbow Drop!', rarity: 'rare', shareable: true),
  RareReward(emoji: '⚡', title: 'Lightning Strike!', rarity: 'epic', shareable: true,
    condition: (stats) => stats.tasksCompletedIn15Min >= 3),
  RareReward(emoji: '🏆', title: 'Champion Drop!', rarity: 'legendary', shareable: true,
    condition: (stats) => stats.currentActiveDays >= 7),
  RareReward(emoji: '🧠', title: 'Brain Power!', rarity: 'epic', shareable: true,
    condition: (stats) => stats.totalFocusMinutesToday >= 120),
];
```

## I4. Shareable Reward Card

```
┌─────────────────────────────────────┐
│  ⚡ Lightning Strike!               │
│  3 tasks in 15 minutes              │
│                                     │
│  [Name] just unlocked a rare drop   │
│  on Ekagra 🧠                        │
│  nudge.app                          │
└─────────────────────────────────────┘
```
- 1080x1920 (Stories format)
- Share to: Instagram, TikTok, Twitter, Copy Link

## I5. Reward History Screen

```
┌─────────────────────────────────────┐
│  ← Back       Your Rewards 🎁       │
│                                     │
│  Total: 47 · Rare: 3                │
│                                     │
│  Today                              │
│  🎵 Listened to a hype song         │
│  🍫 Ate a snack                     │
│                                     │
│  Yesterday                          │
│  🚶 Took a walk                     │
│                                     │
│  ── Rare Drops ──                   │
│  ⚡ Lightning Strike! — Aug 5       │
│  🌈 Rainbow Drop! — Aug 3           │
└─────────────────────────────────────┘
```

---

# SECTION J: BODY DOUBLING (Silent Co-Working)

## J1. Design Philosophy
- NOT video chat (too much friction)
- NOT real-time matching (scheduling kills ADHD momentum)
- YES ambient presence — knowing others are working RIGHT NOW
- Anonymous, no names required

## J2. Focus Room Screen

```
┌─────────────────────────────────────┐
│  ← Back       Body Doubling 🤝      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   127 people are focusing   │    │
│  │   right now                 │    │
│  │   [Animated dots: · · · · ·]│    │
│  └─────────────────────────────┘    │
│                                     │
│  "You're not alone. Pick a task     │
│   and join the focused."            │
│                                     │
│  I'm starting: [Task selector ▼]    │
│  Duration: [25 min ▼]               │
│                                     │
│  [Join the focus room]              │
│                                     │
│  ── Quick Cheer ──                  │
│  [👏] [💪] [🔥] [❤️] [🎉] [🌟]     │
│                                     │
└─────────────────────────────────────┘
```

## J3. Cheer System
- Quick reactions: 👏 💪 🔥 ❤️ 🎉 🌟
- Sends to random person in room
- Floating bubbles animation (3s, fade out at top)
- Limit: 1 cheer per 10 seconds (spam prevention)

## J4. Presence System

```dart
// Firestore: focus_rooms/global_room/presence/{userId}
{
  'taskTitle': 'Reply to Sarah',
  'startedAt': Timestamp,
  'durationMinutes': 25,
  'isAnonymous': true,
  'lastHeartbeat': Timestamp  // Updated every 30s
}

// Cleanup: Remove entries with lastHeartbeat > 2 min (Cloud Function)
// Recalculate activeUserCount every minute
```

---

# SECTION K: SETTINGS & PROFILE

## K1. Settings Screen Layout

```
┌─────────────────────────────────────┐
│  ← Back          Settings ⚙️        │
│                                     │
│  ── Profile ──                      │
│  👤 Alex · alex@email.com · ✏️ Edit │
│                                     │
│  ── Preferences ──                  │
│  🧠 ADHD Profile                    │
│  Task Paralysis, Time Blindness  →  │
│  🍫 Dopamine Menu · 8 items      →  │
│  ⏰ Wake/Sleep · 7AM–11PM         →  │
│  🌙 Dark Mode                    [T]│
│  📏 Font Size                    [→]│
│  ── Notifications ──                │
│  🔔 Gentle Nudges                [T]│
│  📅 Daily Check-in              [T]│
│  🎉 Reward Reminders            [T]│
│  🤝 Body Double Alerts          [T]│
│  Ekagra Schedule: [Customize →]     │
│  ── Subscription ──                 │
│  ⭐ Ekagra Pro (Active)           →  │
│  ── Data ──                         │
│  📤 Export My Data               →  │
│  ── Support ──                      │
│  💬 Send Feedback · ❓ Help         │
│  📋 Privacy · 📋 Terms              │
│  ── Account ──                      │
│  🚪 Sign Out · 🗑️ Delete Account   │
│  v1.0.0 · Made with 💛 by Ekagra     │
└─────────────────────────────────────┘
```

## K2. ADHD Profile Editor
- Same cards as onboarding Screen 2
- Can change selections anytime
- Changes affect AI immediately

## K3. Dopamine Menu Editor
- Same as onboarding Screen 3
- Add/remove/reorder items
- Import community templates (V2)

## K4. Notification Schedule (With Discipline Rules)

```
┌─────────────────────────────────────┐
│  ← Back     Ekagra Schedule 🔔       │
│                                     │
│  Morning Ekagra · 8:00 AM    [T]    │
│  Midday Check-in · 12:00 PM [T]    │
│  Afternoon Boost · 3:00 PM  [T]    │
│  Evening Wind-down · 8:00 PM [T]   │
│                                     │
│  🤖 AI-timed nudges            [T]  │
│  📱 Inactivity nudge           [T]  │
│                                     │
│  🔇 Do Not Disturb                  │
│  [10:00 PM] to [7:00 AM]           │
│                                     │
│  Max notifications per day: [3]     │
│                                     │
└─────────────────────────────────────┘
```

### Notification Discipline Rules (NEW)
```
1. MAX 3 notifications per day (user-configurable)
2. Notifications auto-dismiss after 1 hour
3. Notification channel: "Ekagra Gentle" (low priority, no sound default)
4. No persistent notifications
5. Batch: multiple events → 1 notification
6. Quiet hours: zero notifications
```

## K5. Font Options (NEW)

```
┌─────────────────────────────────────┐
│  ← Back          Font Settings 📏   │
│                                     │
│  Font Family                        │
│  ○ Inter (default, clean)           │
│  ○ OpenDyslexic (dyslexia-friendly) │
│  ○ System font                      │
│                                     │
│  Font Size                          │
│  Standard ───────●──────── Large    │
│                                     │
│  Line Height                        │
│  Compact ────────●─────── Relaxed   │
│                                     │
│  Preview:                            │
│  "Reply to Sarah's email"           │
│  ~15 min · Quick task               │
│                                     │
└─────────────────────────────────────┘
```

## K6. Subscription Management (Transparent Cancellation) (NEW)

### Why This Exists
Tiimo/Inflow Trustpilot: *"Almost impossible to cancel subscription"*

```
┌─────────────────────────────────────┐
│  ← Back     Subscription ⭐         │
│                                     │
│  Plan: Ekagra Pro                    │
│  Status: Active                     │
│  Renews: September 8, 2026          │
│  Price: $49.99/year                 │
│                                     │
│  ┌───────────────────────────┐      │
│  │  Cancel Subscription      │      │  ← 1 TAP, NO CONFIRMATION NESTS
│  └───────────────────────────┘      │
│                                     │
│  ┌───────────────────────────┐      │
│  │  Switch to Monthly         │      │
│  └───────────────────────────┘      │
│                                     │
│  ┌───────────────────────────┐      │
│  │  Restore Purchase          │      │
│  └───────────────────────────┘      │
│                                     │
│  "Cancel anytime — no questions     │
│   asked. Your data stays safe."     │
│                                     │
└─────────────────────────────────────┘
```

### Cancellation Policy
1. Cancel button: 1 tap, no confirmation nests
2. No dark patterns
3. Show exact renewal date always
4. Email reminder 3 days before renewal
5. Offer pause option (keep data, stop billing)
6. Refund within 14 days, no questions asked
7. If user emails "cancel", cancel immediately

## K7. Data Export (NEW)

```
Settings → Data → Export My Data
- Export all tasks as CSV
- Export all focus sessions as CSV
- Export all rewards as CSV
- Export complete data as JSON
- Email export or download to device
- GDPR compliance: User owns their data
```

---

# SECTION L: WIDGETS

## L1. iOS Widgets

### Small (2x2)
```
┌─────────────────────┐
│ Ekagra               │
│ 📧 Reply to Sarah   │
│ ~15 min             │
│ [Start Focus]       │
└─────────────────────┘
```

### Medium (4x2)
```
┌─────────────────────────────────┐
│ Ekagra            3 done today ✅│
│ 🎯 Reply to Sarah  [Focus →]   │
│ 📄 Finish deck    (upcoming)    │
│ 📞 Call dentist   (upcoming)    │
│ ████████████░░░░  58% of day    │
└─────────────────────────────────┘
```

### Lock Screen (iOS 16+)
```
┌─────────────────┐
│ 🎯 Reply to     │
│    Sarah · 15m  │
└─────────────────┘
```

## L2. Android Widgets

### Small (2x2): Same as iOS
### Medium (4x2): Same as iOS, Material 3 styling
### Large (4x4): Full home screen layout with ONE thing + upcoming + stats

## L3. Widget Update Logic
```dart
class WidgetUpdateService {
  // Update when: task completed, new ONE thing, focus ends, energy check-in, every 15 min
  Future<void> updateWidgets() async {
    final oneThing = await TaskSelector().getCurrentOneThing();
    final stats = await StatsService().getTodayStats();
    await _writeToWidgetData({...});
    await HomeWidget.updateWidget(name: 'NudgeWidget', iOSName: 'NudgeWidget');
  }
}
```

---

# SECTION M: PUSH NOTIFICATION SYSTEM

## M1. Notification Types

| Type | Title | Body | Schedule |
|---|---|---|---|
| Morning | "Good morning, {name} ☀️" | "4 tasks on your list. Let's start with one small thing." | User-configured (default 8AM) |
| Midday | "How's your day? 🌤️" | "2 tasks done so far. Want to tackle another?" | User-configured (default 12PM) |
| Afternoon | "Energy dipping? ☕" | "A quick 5-min task might help." | User-configured (default 3PM) |
| Evening | "Time to rest 🌙" | "You did 3 things today. That's enough. 💛" | User-configured (default 8PM) |
| Inactivity | "Hey, just checking in 💛" | "No pressure. Just saying hi." | 2 days after last open (max 1/week) |
| Reward | "You earned something! 🎁" | "A surprise is waiting for you!" | 30-120 min after task completion |
| Body Double | "34 people focusing 🤝" | "Join them?" | Random during active hours (max 1/day) |
| Weekly | "Your week in review 📊" | "8 tasks, 2.5 hours focused. You showed up!" | Sunday evening |

## M2. Notification Copy Guidelines

### ALWAYS
- Use first name
- Include emoji
- Offer action, not demand
- Under 50 chars title, 100 chars body
- Casual, friendly language

### NEVER (RSD-Safe Language)
- "You haven't..." (guilt)
- "Don't forget..." (pressure)
- "Reminder:" (clinical)
- "You missed..." (shame)
- More than 1 exclamation mark
- More than 3 notifications per day
- Notifications during DND hours

## M3. Auto-Dismiss (NEW)
- Notifications auto-dismiss after 1 hour (don't pile up in notification bar)
- Notification channel: "Ekagra Gentle" (low priority)
- No persistent/ongoing notifications

## M4. Smart Timing
```dart
class SmartNotificationScheduler {
  // Learn best times from historical data
  // Find hour within window where user most often opens notifications
  // Adjust over time based on open rates
}
```

---

# SECTION N: AI INTEGRATION (Complete)

## N1. AI Use Cases Summary

| Use Case | Model | Trigger | Fallback |
|---|---|---|---|
| Task Selection | GPT-4o-mini | "Pick ONE thing" | Rule-based scoring |
| Micro-Commitment | GPT-4o-mini | After task selected | "Just start for 2 minutes" |
| Energy Insight | GPT-4o-mini | Day view load | Template pool |
| Mood Insight | GPT-4o-mini | Day view load (with mood) | Template pool |
| Task Breakdown | GPT-4o-mini | "Break this down" | Simple 4-step template |

## N2. AI Service Implementation (Full Code)

```dart
class AiService {
  static const String _model = 'gpt-4o-mini';
  final String _apiKey;
  final FirebaseService _firebase;
  
  // ═══════════════════════════════════
  // TASK SELECTION
  // ═══════════════════════════════════
  
  static const String _taskSelectionSystemPrompt = '''
You are Ekagra, a gentle ADHD task selector. Pick ONE task to start right now.
RULES: Pick task most likely to get STARTED (not most important). Prefer quick wins when overwhelmed.
Match difficulty to energy AND mood. Never same task twice. Suggest micro-commitment.
NEVER use shame language. Casual, warm, with emojis. Respond in JSON only.
''';

  Future<AiTaskSelection> pickOneThing({
    required List<Task> tasks,
    required EnergyLevel energy,
    required MoodLevel mood,
    required List<AdhdTrait> traits,
    required String? lastSelectedTaskId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _taskSelectionSystemPrompt},
            {'role': 'user', 'content': _buildTaskPrompt(tasks, energy, mood, traits, lastSelectedTaskId)},
          ],
          'temperature': 0.7,
          'max_tokens': 200,
          'response_format': {'type': 'json_object'},
        }),
      );
      if (response.statusCode != 200) return _fallbackSelection(tasks, energy, mood);
      final data = jsonDecode(response.body);
      return AiTaskSelection.fromJson(jsonDecode(data['choices'][0]['message']['content']));
    } catch (e) {
      await _firebase.logError('ai_task_selection_failed', e);
      return _fallbackSelection(tasks, energy, mood);
    }
  }
  
  // ═══════════════════════════════════
  // MICRO-COMMITMENT
  // ═══════════════════════════════════
  
  Future<String> generateMicroCommitment(String taskTitle) async {
    // Same pattern: try AI → fallback "Just start for 2 minutes"
  }
  
  // ═══════════════════════════════════
  // ENERGY + MOOD INSIGHT
  // ═══════════════════════════════════
  
  Future<String> getInsight({required EnergyLevel energy, required MoodLevel mood}) async {
    // Combined energy + mood insight
    // Fallback: template pool based on energy+mood combination
  }
  
  // ═══════════════════════════════════
  // TASK BREAKDOWN
  // ═══════════════════════════════════
  
  Future<List<Subtask>> breakdownTask(String taskTitle) async {
    // AI breaks task into 3-8 subtasks
    // Fallback: 4-step template
  }
}
```

## N3. Audio Read-Aloud for All Text (NEW)

```dart
class ReadAloudService {
  // Every piece of text has a "read aloud" option
  // - Encouragement text: optional auto-read
  // - Task descriptions: tap speaker icon
  // - AI responses: tap to hear
  // Uses device TTS (text-to-speech) — no API cost
  // Settings: Enable/Disable auto-read
}
```

## N4. Offline AI Fallback (NEW)

```dart
// When offline:
// - Task selection: rule-based scoring (no API call)
// - Micro-commitment: "Just start for 2 minutes. That's all."
// - Energy insight: template pool
// - Task breakdown: 4-step default template
// - User never sees an error — seamless fallback
```

---

# SECTION O: SUBSCRIPTION & PAYWALL

## O1. Free vs Pro Feature Matrix

| Feature | Free | Pro ($7.99/mo) |
|---|---|---|
| Brain dump | 10 tasks max | Unlimited |
| "Pick ONE thing" (AI) | ❌ (random) | ✅ (AI-powered) |
| Focus timer | 25 min only | All durations + custom |
| Dopamine menu | 3 items (1/tier) | Unlimited |
| Visual timeline | ✅ | ✅ |
| Body doubling | ❌ | ✅ |
| Widgets | ❌ | ✅ |
| Ambient sounds | 2 (Rain, Lofi) | All 6 |
| Task breakdown (AI) | ❌ | ✅ |
| Energy/mood insights (AI) | ❌ | ✅ |
| Themes | Default only | Custom |
| Stats | Basic | Detailed |
| Data export | ❌ | ✅ |
| Search | ✅ | ✅ |
| Recurring tasks | ✅ | ✅ |
| Someday list | ✅ | ✅ |

## O2. Paywall Trigger Points

| Trigger | Type | Can Skip? |
|---|---|---|
| Onboarding (Screen 5) | Bottom sheet | Yes |
| 11th task added | Modal | No |
| 3rd+ AI pick | Bottom sheet | Yes |
| Widget attempt | Tutorial | Yes |
| Body doubling attempt | Bottom sheet | Yes |
| 3-day inactive return | Time-limited trial (48h) | Yes |

## O3. Transparent Pricing (NEW)

```
In-app pricing page:
- EXACTLY what's free vs Pro
- No asterisks or fine print
- "Try Pro free for 7 days" — shows when trial ends
- "Cancel anytime — 1 tap in Settings"
- "Not sure? Use Free forever. It's actually free."
```

## O4. Easy Cancellation Policy (NEW)

```
1. Cancel: Settings → Subscription → Cancel (1 tap)
2. No dark patterns
3. Show exact renewal date
4. Email reminder 3 days before renewal
5. Pause option available
6. 14-day refund, no questions
7. Email "cancel" → immediate cancellation
```

## O5. RevenueCat Integration

```dart
class SubscriptionService {
  final RevenueCat _revenueCat;
  
  Future<void> initialize() async {
    await Purchases.configure(PurchasesConfiguration('your_api_key'));
  }
  
  Future<bool> purchasePro() async {
    final offering = await getCurrentOffering();
    final package = offering?.monthly ?? offering?.annual;
    if (package == null) return false;
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo.entitlements.active.containsKey('pro');
  }
  
  Future<bool> isProUser() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey('pro');
  }
}
```

---

# SECTION P: ANIMATIONS & MICRO-INTERACTIONS

## P1. Complete Animation Registry

| ID | Element | Trigger | Animation | Duration | Easing | Haptic |
|---|---|---|---|---|---|---|
| A01 | Logo | Load | Fade in + scale 0.8→1.0 | 800ms | easeOutBack | — |
| A02 | Card entrance | Load | Slide from right + fade | 400ms | easeOut | — |
| A03 | Card stagger | Load | A02 with 80ms delay | — | — | — |
| A04 | Card press | Tap down | Scale 1.0→0.97 | 100ms | easeInOut | lightImpact |
| A05 | Card release | Tap up | Scale 0.97→1.0 | 100ms | easeOut | — |
| A06 | Card selection | Selected | Border color transition | 200ms | easeInOut | selectionClick |
| A07 | Checkmark | Selection | Scale 0→1.2→1.0 | 300ms | easeOutBack | — |
| A08 | Task entry | New task | Slide from right + fade | 300ms | easeOut | lightImpact |
| A09 | Task delete | Swipe | Slide left + fade | 250ms | easeIn | selectionClick |
| A10 | Focus ring fill | Timer active | 0°→360° clockwise | Timer | linear | — |
| A11 | Focus ring pulse | Every second | Scale 1.0→1.01→1.0 | 1s | easeInOut | — |
| A12 | Ring complete | Timer done | Scale 1.0→1.08→1.0 (x3) | 400ms | easeOutBack | heavyImpact |
| A13 | Confetti | Task/session done | 50 particles from center | 2s | easeOut | heavyImpact |
| A14 | Mystery box bounce | Reward reveal | Scale 1.0→1.05→1.0 | 1s loop | easeInOut | — |
| A15 | Box open | Tap | Lid translateY -50, opacity 0 | 800ms | easeOut | mediumImpact |
| A16 | Light rays | Box open | 12 rays expand | 600ms | easeOut | — |
| A17 | Reward emoji | After rays | Scale 0→1.2→1.0 | 400ms | easeOutBack | heavyImpact |
| A18 | Reward text | After emoji | Fade in + slide up 20px | 300ms | easeOut | — |
| A19 | Button appear | After text | Slide up + fade | 300ms | easeOut | — |
| A20 | Breathing pulse | Idle button | Scale 1.0→1.02→1.0 | 3s loop | easeInOut | — |
| A21 | Gradient shimmer | CTA button | Light sweep L→R | 2s loop | linear | — |
| A22 | Energy emoji float | Unselected | TranslateY ±3px | 3s loop | easeInOut | — |
| A23 | Energy select | Tap | Scale 1.0→1.2, others fade | 300ms | easeOut | mediumImpact |
| A24 | Progress bar fill | Load | Width 0→current% | 800ms | easeOut | — |
| A25 | Tab switch | Nav tap | Slide transition | 300ms | easeInOut | lightImpact |
| A26 | FAB pulse | Idle 30s | Scale 1.0→1.15→1.0 | 1.5s loop | easeInOut | — |
| A27 | Typewriter text | Encouragement | Char-by-char reveal | 800ms/line | linear | — |
| A28 | Cheer bubble | Receive cheer | Float up + fade at top | 3s | easeOut | lightImpact |
| A29 | Progress update | Every minute | Width transition | 500ms | easeOut | — |
| A30 | Bottom sheet open | Trigger | Slide up | 400ms | easeOut | — |
| A31 | Bottom sheet close | Dismiss | Slide down | 300ms | easeIn | — |
| A32 | Skeleton loading | Data loading | Shimmer sweep | 1.5s loop | linear | — |
| A33 | Error state | Error | Shake translateX ±5px | 300ms | easeInOut | mediumImpact |
| A34 | Success toast | Success | Slide down + auto-hide | 2s | easeOut | lightImpact |
| A35 | Onboarding dots | Progress | Active dot scale 1.3 | 200ms | easeOut | — |

## P2. Lottie Animation Files

| File | Used In | Description |
|---|---|---|
| onboarding_brain_to_nudge.json | Welcome | Brain → Ekagra logo morph |
| chaos_to_organized.json | Brain dump intro | Scribbles → single line |
| confetti_celebration.json | Task/session complete | Confetti burst |
| mystery_box_idle.json | Reward waiting | Box bounce + sparkle |
| mystery_box_open.json | Reward reveal | Box opens + light burst |
| focus_ring_complete.json | Focus done | Ring fill + particles |
| loading_brain.json | AI thinking | Brain + thinking dots |
| empty_state_tasks.json | No tasks | Peaceful notebook |
| error_gentle.json | Errors | Friendly "oops" face |
| welcome_back.json | Returning user | Warm wave |

---

# SECTION Q: EDGE CASES & ERROR HANDLING

## Q1. Network Errors

| Scenario | Behavior |
|---|---|
| No internet (launch) | Works offline. Banner: "Offline mode — data will sync later 📶" |
| No internet (AI call) | Fall back to rule-based. No error shown. |
| No internet (sync) | Queue changes locally. Sync when restored. |
| API timeout (10s) | Fall back to rule-based. No error. |
| API rate limit | Fall back. Log for monitoring. |
| Firebase error | Toast: "Something hiccupped. Your data is safe." Auto-retry. |

## Q2. Data Edge Cases

| Scenario | Behavior |
|---|---|
| 0 tasks | "Your list is clear! Enjoy the calm 🌊" + "Add a task" button |
| 1 task | Auto-select it. "You've got one thing. Let's do it!" |
| 100+ tasks | AI works (sends top 20). "Big list! Let's focus on one." |
| No title | Prevent submission. "Every task needs a name" |
| 500+ char title | Truncate to 80 chars in display |
| Duplicate tasks | Allow (user might want to do same thing twice) |
| Task from 2024 | "This has been here a while. Still relevant?" |
| Timezone change | Adjust all times. "Looks like you've traveled! 🌍" |
| DST change | Automatic. No user-facing change. |
| Clock skew | Server time for critical logic (rewards, streaks) |

## Q3. Account Edge Cases

| Scenario | Behavior |
|---|---|
| Deleted account | 30-day grace period. "Changed your mind?" |
| New device sign-in | Full Firestore sync. Loading animation during sync. |
| Multiple devices | Real-time sync. Last-write-wins. |
| Subscription expires | Graceful downgrade. Keep data, gate features. |
| Payment failed | 3-day grace. Then downgrade. Never delete data. |
| Apple/Google refund | Immediate downgrade. Data accessible. |

## Q4. State Recovery

```dart
class StateRecoveryService {
  // Crash during focus session:
  Future<void> recoverFocusSession() async {
    final session = await _prefs.getString('active_focus_session');
    if (session != null) {
      final elapsed = DateTime.now().difference(session.startedAt).inSeconds;
      final remaining = (session.plannedMinutes * 60) - elapsed;
      if (remaining > 0) {
        // "Looks like you were focusing on [task]. Continue? [X min left]"
      } else {
        // "Welcome back! Your focus session completed while away 🎉"
        await _completeSession(session);
      }
    }
  }
  
  // Interrupted brain dump:
  Future<void> recoverBrainDump() async {
    final draft = await _prefs.getString('brain_dump_draft');
    if (draft != null) {
      // "You were in the middle of a brain dump. Continue? [Yes] [Start fresh]"
    }
  }
}
```

## Q5. Offline-First Architecture (NEW)

```dart
// EVERYTHING works offline:
// - Brain dump: works, syncs when online
// - Focus timer: works
// - Rewards: pre-cached reward items
// - Task list: cached locally (Hive/SQLite)
// - AI features: rule-based fallback
// - Body doubling: "Requires internet" message
// - Sync: Automatic when connection restored
// - Conflict: Last-write-wins with merge for tasks

class OfflineQueue {
  final List<QueuedAction> _queue = [];
  
  void enqueue(QueuedAction action) {
    _queue.add(action);
    _saveQueue();
  }
  
  Future<void> processQueue() async {
    if (!await ConnectivityService.isConnected()) return;
    for (final action in _queue) {
      try {
        await action.execute();
        _queue.remove(action);
      } catch (e) {
        break; // Stop processing, retry later
      }
    }
    _saveQueue();
  }
}
```

---

# SECTION R: ACCESSIBILITY

## R1. Visual Accessibility

| Requirement | Implementation |
|---|---|
| Color contrast | WCAG 2.1 AA (4.5:1 normal, 3:1 large) |
| Color alone | Never only indicator (always pair with icon/text) |
| Font scaling | Support system font up to 200% |
| Dynamic type | `MediaQuery.textScaleFactor` throughout |
| Dark mode | Full support with proper contrast |
| Reduced motion | `MediaQuery.disableAnimations` → instant transitions |
| Screen reader | Every element has `semanticsLabel` |
| Focus indicators | Ring on focused elements with external keyboard |

## R2. Screen Reader Labels

```dart
Semantics(
  label: 'Reply to Sarah email, estimated 15 minutes, tap to start focus session',
  button: true, child: TaskCard(task: task),
)
Semantics(
  label: 'Focus timer, 14 minutes and 32 seconds remaining, currently active',
  child: FocusRing(),
)
Semantics(
  label: 'Energy level selector, currently medium energy, tap to change',
  child: EnergyCheckIn(),
)
Semantics(
  label: 'Mystery reward box, tap to open and reveal your reward',
  child: MysteryBox(),
)
```

## R3. Motor Accessibility

| Requirement | Implementation |
|---|---|
| Touch targets | Minimum 48x48dp |
| Tap vs hold | No long-press required |
| Swipe alternatives | All swipe actions via button in context menu |
| One-hand mode | Primary actions in bottom 60% |
| Voice control | Clear, speakable labels |

## R4. Font Options & Dyslexia Support (NEW)

- OpenDyslexic font option (specifically designed for dyslexic readers)
- Font size slider: 14px → 24px
- Line height slider: 1.2 → 2.0
- System font option (respects user's system choice)

## R5. RSD-Safe Language Audit (NEW)

### Why This Exists
Rejection Sensitivity Dysphoria (RSD) is a core ADHD symptom. Apps that criticize, compare, or show failure can trigger it.

### NEVER Use
- "You failed to complete..."
- "You're falling behind..."
- "You missed..."
- "Your streak is broken"
- Compare to other users
- "You should have..."
- Any form of ranking

### ALWAYS Use
- "Welcome back!"
- "Let's try something small"
- "You showed up — that counts"
- "No pressure"
- "Whenever you're ready"
- Celebrate effort, not outcome

### Audit Process
Every user-facing string must pass RSD audit before shipping. QA checklist includes RSD-safe review.

---

# SECTION S: ANALYTICS

## S1. Event Registry

| Event | Parameters | When |
|---|---|---|
| `onboarding_started` | `{}` | First screen shown |
| `onboarding_step_completed` | `{step}` | Each step |
| `onboarding_completed` | `{duration, skipped_steps[]}` | Finished |
| `onboarding_abandoned` | `{last_step, duration}` | Left onboarding |
| `account_created` | `{method}` | Account created |
| `brain_dump_opened` | `{source}` | Brain dump opened |
| `brain_dump_task_added` | `{length, source}` | Task added |
| `brain_dump_completed` | `{task_count, duration}` | "Done dumping" |
| `mood_checkin` | `{level}` | Mood selected |
| `energy_checkin` | `{level}` | Energy selected |
| `ai_selection_triggered` | `{task_count, energy, mood}` | "Pick ONE thing" |
| `ai_selection_completed` | `{task_id, fallback_used}` | AI returns |
| `ai_selection_skipped` | `{times_skipped}` | User skips |
| `focus_session_started` | `{task_id, duration, ambient}` | Timer starts |
| `focus_session_paused` | `{elapsed, reason}` | Paused |
| `focus_session_completed` | `{planned, actual, outcome}` | Session ends |
| `focus_session_abandoned` | `{elapsed, reason}` | Abandoned |
| `cant_focus_tapped` | `{elapsed}` | "Can't focus" |
| `cant_focus_action` | `{action}` | Option selected |
| `hyperfocus_detected` | `{duration_minutes}` | 2+ hour session |
| `reward_triggered` | `{tier, tasks_since_last}` | Reward fires |
| `reward_revealed` | `{reward_id, tier, is_rare}` | Shown |
| `reward_claimed` | `{reward_id}` | Claimed |
| `reward_shared` | `{reward_id, platform}` | Shared |
| `body_double_joined` | `{task_id, room_count}` | Joined |
| `body_double_cheered` | `{type}` | Cheer sent |
| `task_created` | `{source}` | Task created |
| `task_completed` | `{method}` | Task done |
| `task_archived` | `{age_days}` | Archived |
| `task_moved_to_someday` | `{age_days}` | Moved to Someday |
| `task_breakdown_requested` | `{task_id}` | "Break down" |
| `sday_list_opened` | `{task_count}` | Someday viewed |
| `auto_prune_prompted` | `{task_id}` | 7-day prompt shown |
| `honest_check_shown` | `{}` | Completion check appears |
| `honest_check_cleared` | `{choice}` | "Did it" or "Just clearing" |
| `paywall_shown` | `{trigger}` | Paywall displayed |
| `paywall_converted` | `{plan, trial}` | Purchase |
| `paywall_dismissed` | `{trigger}` | Skipped |
| `subscription_cancelled` | `{plan}` | Cancelled |
| `data_exported` | `{format}` | Export triggered |
| `widget_added` | `{size}` | Widget placed |
| `notification_received` | `{type}` | Delivered |
| `notification_opened` | `{type, delay}` | Tapped |
| `app_opened` | `{days_since_last}` | Foregrounded |
| `app_backgrounded` | `{session_duration}` | Backgrounded |
| `error_occurred` | `{type, context, recoverable}` | Any error |

## S2. Funnel Tracking

```
ONBOARDING: Step 1 → 2 → 3 → 4 → Paywall → Home
CORE LOOP: App Open → Energy/Mood → AI Selection → Focus → Reward → Task Done → repeat
MONETIZATION: Paywall Shown → Trial Start → Trial Active (7d) → Convert → Renewal
RETENTION: Day 1 → Day 7 → Day 30 → Day 90
```

---

# SECTION T: DATABASE SCHEMA (Firestore)

## T1. Collections

### `users/{userId}`
```json
{
  "id": "user_abc123",
  "email": "alex@email.com",
  "displayName": "Alex",
  "createdAt": "2026-08-08T10:00:00Z",
  "updatedAt": "2026-08-08T10:00:00Z",
  "adhdTraits": ["task_paralysis", "time_blindness"],
  "dopamineMenu": {
    "quick": [{"id": "dm_1", "emoji": "🎵", "text": "Listen to 1 hype song", "durationMinutes": 3, "isCustom": false}],
    "medium": [...],
    "big": [...]
  },
  "preferences": {
    "wakeTime": "07:00",
    "sleepTime": "23:00",
    "darkMode": false,
    "fontFamily": "inter",
    "fontScale": 1.0,
    "lineHeight": 1.5,
    "completedTaskVisibility": "collapsed",
    "notifications": {
      "morning": {"enabled": true, "time": "08:00"},
      "midday": {"enabled": true, "time": "12:00"},
      "afternoon": {"enabled": true, "time": "15:00"},
      "evening": {"enabled": true, "time": "20:00"},
      "smartTiming": true,
      "inactivityNudge": true,
      "maxPerDay": 3,
      "dndStart": "22:00",
      "dndEnd": "07:00"
    }
  },
  "subscription": {
    "plan": "pro",
    "status": "active",
    "expiresAt": "2026-09-08T10:00:00Z",
    "revenueCatId": "rc_abc123",
    "trialEndsAt": "2026-08-15T10:00:00Z"
  },
  "stats": {
    "totalTasksCompleted": 47,
    "totalFocusMinutes": 840,
    "totalRewardsEarned": 23,
    "totalActiveDays": 23,
    "lastActiveDate": "2026-08-08"
  },
  "onboarding": {
    "completed": true,
    "completedAt": "2026-08-08T10:05:00Z",
    "usedDefaults": false,
    "paywallSeen": true
  },
  "aiContext": {
    "lastSelectedTaskId": "task_456",
    "lastSelectionTime": "2026-08-08T14:30:00Z",
    "preferredTaskDuration": 15,
    "peakFocusHours": [10, 11, 14, 15]
  }
}
```

### `users/{userId}/tasks/{taskId}`
```json
{
  "id": "task_456",
  "title": "Reply to Sarah's email",
  "description": "She asked about the Q3 report deadline",
  "emoji": "📧",
  "category": "email",
  "status": "not_started",
  "energyRequired": "low",
  "estimatedMinutes": 15,
  "actualMinutes": null,
  "isPriority": false,
  "source": "text",
  "scheduleType": "today",
  "deadlineType": "none",
  "deadline": null,
  "subtasks": [],
  "notes": "",
  "recurrence": null,
  "createdAt": "2026-08-08T10:00:00Z",
  "updatedAt": "2026-08-08T10:00:00Z",
  "completedAt": null,
  "archivedAt": null,
  "movedToSomedayAt": null,
  "promptedForRelevance": false,
  "focusSessionCount": 0,
  "brainDumpSessionId": "bd_789"
}
```

### `users/{userId}/focusSessions/{sessionId}`
```json
{
  "id": "fs_101",
  "taskId": "task_456",
  "taskTitle": "Reply to Sarah's email",
  "plannedMinutes": 25,
  "actualMinutes": 23,
  "outcome": "completed",
  "startedAt": "2026-08-08T14:00:00Z",
  "endedAt": "2026-08-08T14:23:00Z",
  "ambientSound": "rain",
  "bodyDoubled": false,
  "energyAtStart": "medium",
  "energyAtEnd": "low",
  "moodAtStart": "good",
  "moodAtEnd": "good",
  "pauseCount": 1,
  "totalPauseSeconds": 45
}
```

### `users/{userId}/energyLogs/{logId}`
```json
{"id": "el_201", "level": "medium", "timestamp": "2026-08-08T10:00:00Z"}
```

### `users/{userId}/moodLogs/{logId}` (NEW)
```json
{"id": "ml_201", "level": "good", "timestamp": "2026-08-08T10:00:00Z"}
```

### `users/{userId}/rewards/{rewardId}`
```json
{
  "id": "rw_301",
  "dopamineItemId": "dm_1",
  "emoji": "🎵",
  "title": "Listen to 1 hype song",
  "tier": "quick",
  "isRare": false,
  "triggerTaskId": "task_456",
  "triggeredAt": "2026-08-08T14:23:00Z",
  "claimedAt": "2026-08-08T14:25:00Z",
  "skippedAt": null,
  "sharedAt": null
}
```

### `users/{userId}/brainDumps/{dumpId}`
```json
{
  "id": "bd_789",
  "taskIds": ["task_456", "task_457", "task_458"],
  "taskCount": 3,
  "source": "text",
  "durationSeconds": 45,
  "createdAt": "2026-08-08T10:00:00Z"
}
```

### `focus_rooms/global_room` + `presence/{userId}` + `cheers/{cheerId}`
(Same as previous spec)

## T2. Indexes

```
1. users/{userId}/tasks: status ASC, createdAt DESC
2. users/{userId}/tasks: status ASC, energyRequired ASC, estimatedMinutes ASC
3. users/{userId}/tasks: scheduleType ASC, status ASC
4. users/{userId}/focusSessions: endedAt DESC
5. users/{userId}/energyLogs: timestamp DESC
6. users/{userId}/moodLogs: timestamp DESC
7. users/{userId}/rewards: triggeredAt DESC
8. focus_rooms/{roomId}/presence: lastHeartbeat ASC
```

## T3. Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /focus_rooms/{roomId} {
      allow read: if true;
      match /presence/{userId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      match /cheers/{cheerId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }
  }
}
```

---

# SECTION U: API & CLOUD FUNCTIONS

## U1. Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `cleanupPresence` | Scheduled (1 min) | Remove stale presence, recalculate counts |
| `onTaskCompleted` | Firestore write | Update stats, check reward, update widgets |
| `onFocusSessionEnded` | Firestore write | Update stats, check rare reward, summary |
| `sendSmartNotification` | Scheduled (hourly) | Personalized notifications based on data |
| `generateWeeklySummary` | Scheduled (Sunday) | Weekly stats aggregation |
| `processVoiceDump` | HTTP callable | Audio → text → task list |
| `runTaskPruning` | Scheduled (daily) | 7-day prompts, 14-day auto-archive, 30-day someday cleanup |
| `processOfflineQueue` | HTTP callable | Process queued offline actions |

## U2. External API Integrations

| Service | Purpose | Auth |
|---|---|---|
| OpenAI (GPT-4o-mini) | AI selection, insights, breakdown | API key (Cloud Functions only) |
| RevenueCat | Subscription management | Public SDK key |
| Firebase Auth | Authentication | — |
| Firebase Messaging | Push notifications | Service account |
| Firebase Analytics | Event tracking | — |
| Google Speech-to-Text | Voice dump transcription | Service account |

---

# APPENDIX A: COMPLETE NOTIFICATION COPY POOL

## Morning Nudges
```
1. "Good morning, {name} ☀️ Ready for one small thing?"
2. "Morning, {name}! Your tasks are waiting — gently."
3. "Hey {name} ☀️ Today's plan: one thing at a time."
4. "Rise and shine, {name} 💛 Let's make today kind to you."
5. "Good morning! Your brain is fresh. Perfect time to start."
```

## Midday Check-ins
```
1. "How's your day, {name}? 🌤️ {done} tasks done so far."
2. "Midday check-in! You've focused for {min} min today. Nice."
3. "Hey! Halfway through. Want to tackle another task?"
4. "Afternoon approaching! Need a quick win before lunch?"
5. "Your day so far: {done} done, {remaining} to go. You're doing great."
```

## Afternoon Boosts
```
1. "Afternoon slump? Totally normal. A quick 5-min task might help."
2. "Energy dipping? Your brain is asking for a break. Or a snack. 🍫"
3. "Hey {name}, want to squeeze in one more thing before evening?"
4. "3 PM vibes: hard things can wait. Easy wins are still wins."
5. "Your focus time today: {min} minutes. Every minute counts."
```

## Evening Wind-downs
```
1. "Time to rest, {name}. You did {count} things today. That's enough. 💛"
2. "Evening mode: ON. Your tasks will be there tomorrow."
3. "You showed up today. That matters more than any task list."
4. "Night time = recovery time. Sleep well, {name} 🌙"
5. "Today's wins: {count} tasks, {min} min focused. Be proud."
```

## Inactivity Nudges
```
1. "Hey {name} 💛 No pressure. Just checking in."
2. "Missed you! Whenever you're ready, we're here."
3. "Life happens. Your tasks aren't going anywhere. Neither are we."
4. "Quick hello from Ekagra 👋 Hope you're doing okay."
5. "No guilt, no catch. Just wanted to say hi 💛"
```

## Reward / Body Double / Weekly (Same as previous spec)

---

# APPENDIX B: SHAME-FREE ERROR MESSAGES

| Error | Message |
|---|---|
| Network error | "Looks like you're offline. No worries — your data is safe 📶" |
| AI timeout | "Hmm, our AI is thinking slowly. Let's pick a task the old-fashioned way." |
| Task limit | "You've got 10 tasks! Upgrade to Pro for unlimited tasks + AI picks." |
| Subscription expired | "Your Pro access ended. Your data is still here! Renew to keep going." |
| Payment failed | "Payment didn't go through. No stress — try again when you're ready." |
| Sync error | "Your data had a hiccup syncing. It'll sort itself out next time." |
| App crash recovery | "Welcome back! Let's pick up where you left off." |
| Rate limit | "We're taking a quick breather. Try again in a moment." |
| Unknown error | "Something unexpected happened. Your data is safe. Try again?" |

---

# APPENDIX C: APP STORE METADATA

**Title:** Ekagra — ADHD Focus & Plan  
**Subtitle:** Your shame-free daily companion  
**Category:** Health & Fitness (Primary), Productivity (Secondary)  
**Keywords:** ADHD,focus,planner,task,productivity,neurodivergent,body doubling,timer,routine,executive function  
**Age Rating:** 12+

**Description:**
```
Built by ADHD brains, for ADHD brains. 🧠

Overwhelmed by your to-do list? Ekagra picks ONE thing for you. 
Can't focus? Start a gentle timer with ambient sounds. 
Need motivation? Unlock random dopamine rewards.

━━━━━━━━━━━━━━━━━━━━━━

✦ THE ONE THING — AI picks your next task based on energy & mood
✦ BRAIN DUMP — Dump everything, don't organize, just type
✦ FOCUS MODE — Gentle timers + ambient sounds + distraction blocking
✦ DOPAMINE MENU — Random rewards keep your brain interested
✦ VISUAL TIMELINE — See your day as a picture, not a list
✦ BODY DOUBLING — Focus alongside 100+ people in real-time
✦ MOOD & ENERGY TRACKING — Understand your patterns
✦ SHAME-FREE DESIGN — No streaks, no red badges, no guilt

━━━━━━━━━━━━━━━━━━━━━━

FREE FOREVER: Brain dump (10 tasks), basic timer, 3 rewards
NUDE PRO ($7.99/mo): Unlimited tasks + AI, all sounds, body doubling, widgets

━━━━━━━━━━━━━━━━━━━━━━

Not a medical device. Not a replacement for therapy. 
Just a really good tool for really good brains. 💛
```

---

# APPENDIX D: LAUNCH CHECKLIST

## Pre-Launch (Week 11)
- [ ] All MVP features implemented
- [ ] All 15 design rules verified
- [ ] All animations polished (35+ from registry)
- [ ] Dark mode complete
- [ ] Accessibility audit passed
- [ ] RSD-safe language audit passed
- [ ] Widget implementation complete (iOS + Android)
- [ ] Push notification system tested
- [ ] RevenueCat integration tested (sandbox)
- [ ] Firebase security rules deployed
- [ ] Cloud Functions deployed and tested
- [ ] Analytics events firing (50+ events)
- [ ] App Store screenshots (6.7", 5.5" iPhone, 12.9" iPad)
- [ ] App Store listing written
- [ ] Privacy policy live
- [ ] Terms of service live
- [ ] Landing page live (nudge.app)
- [ ] Beta build to 100 testers
- [ ] Critical bugs fixed
- [ ] Performance profiling (60fps verified)
- [ ] Offline mode tested
- [ ] Android feature parity verified
- [ ] Low-end device testing (3GB RAM)
- [ ] Timer precision testing (background, resume, drift)
- [ ] Notification delivery testing

## Launch Day (Week 12)
- [ ] Submit to App Store review
- [ ] Submit to Google Play review
- [ ] Product Hunt draft ready
- [ ] Launch tweet/thread drafted
- [ ] Reddit posts drafted (r/ADHD, r/SideProject)
- [ ] TikTok launch video recorded
- [ ] Press kit ready
- [ ] Monitoring dashboard live
- [ ] Error alerting configured
- [ ] Support email active (support@nudge.app)

---

# APPENDIX E: GAP AUDIT REFERENCE TABLE

## Competitor Gaps Addressed

| Gap ID | Source | Complaint | Ekagra Solution | Status |
|---|---|---|---|---|
| T1 | Tiimo | No task management | Brain dump + AI selection | ✅ Covered |
| T2 | Tiimo | Setup before value | Zero-config quick start | ✅ Added |
| T3 | Tiimo | Timer bugs | DateTime-based timer | ✅ Added |
| T4 | Tiimo | Can't drag to reschedule | Drag-to-reschedule | 🟡 V1.1 |
| T5 | Tiimo | No gap visualization | Free time blocks | ✅ Added |
| T6 | Tiimo | No notifications/sounds | Transition sounds | ✅ Added |
| T7 | Tiimo | No subtasks | Subtask support | 🟡 V1.1 |
| T8 | Tiimo | Limited recurring | Every N days | ✅ Added |
| T9 | Tiimo | Keyboard covers input | Proper handling | ✅ Added |
| T10 | Tiimo | Completed tasks clutter | Smart visibility | ✅ Added |
| T11 | Tiimo | AI doesn't understand | GPT-4o-mini + fallback | ✅ Covered |
| T12 | Tiimo | No calendar sync | Google + Apple calendar | 🟡 V1.1 |
| T13 | Tiimo | No rolling week view | Rolling 7-day view | ✅ Added |
| T14 | Tiimo | Watch not functional | Watch app | ⚪ V2 |
| T15 | Tiimo | Hard to cancel | 1-tap cancellation | ✅ Added |
| T16 | Tiimo | Android lags iOS | Feature parity policy | ✅ Added |
| T17 | Tiimo | Too playful | Theme options | 🟡 V1.1 |
| T18 | Tiimo/Inflow | No search | Task search + filter | ✅ Added |
| I1 | Inflow | Too much reading | Audio read-aloud | ✅ Added |
| I2 | Inflow | Too expensive | $7.99/mo pricing | ✅ Covered |
| I3 | Inflow | Billing issues | Bulletproof billing | ✅ Added |
| I4 | Inflow | Buggy Android | Rigorous testing protocol | ✅ Added |
| I5 | Inflow | Not personalized | Learning system | 🟡 V1.1 |
| F1 | Focusmate | Scheduling friction | Instant body doubling | ✅ Covered |
| F2 | Focusmate | Social anxiety | Anonymous, no video | ✅ Covered |
| F5 | Focusmate | Forced breaks | No forced breaks | ✅ Added |
| FH1 | Habitica | Gamification wears off | Variable ratio rewards | ✅ Covered |
| FH2 | Habitica | Too overwhelming | Progressive disclosure | ✅ Added |
| FH3 | Habitica | "Another thing to fail" | Auto-pruning | ✅ Added |
| FH5 | Habitica | Streak anxiety | No streaks, active days | ✅ Added |
| G1 | Reddit | Setup takes energy | Zero-config start | ✅ Added |
| G3 | Reddit | Too many features | Progressive disclosure | ✅ Added |
| G6 | Reddit | Aspirational clutter | Someday/Maybe list | ✅ Added |
| G7 | Reddit | Day vs anytime tasks | Schedule types | ✅ Added |
| G8 | Reddit | Uses executive function | 2-tap max rule | ✅ Added |
| G13 | Reddit | Overwhelming task list | 5-task cap on home | ✅ Added |
| G14 | Reddit | No task templates | Common task templates | ✅ Added |
| G15 | Reddit | Tool maintenance tedium | Auto-suggestions | ✅ Added |
| G16 | Reddit | Backlog needs pruning | Auto-pruning system | ✅ Added |
| G17 | Reddit | Hard vs soft deadlines | Deadline types | 🟡 V1.1 |
| G18 | Reddit | No mood tracking | Mood check-in | ✅ Added |
| G21 | Reddit | Phone distractions | Distraction blocking | ✅ Added |
| G25 | Reddit | Notification pile-up | Notification discipline | ✅ Added |
| G26 | Reddit | Font discomfort | Font options | ✅ Added |
| G29 | Reddit | No offline support | Offline-first arch | ✅ Added |
| E1 | General | Emotional dysregulation | Mood-aware AI | ✅ Added |
| E2 | General | RSD triggers | RSD-safe language | ✅ Added |
| E3 | General | Hyperfocus not supported | Hyperfocus support | ✅ Added |
| E4 | Reddit | Ticking without doing | Honest completion check | ✅ Added |

---

*This document is the single source of truth for the Ekagra app. It merges the complete application specification with the gap audit addendum. Every competitor weakness, every user complaint, every design decision, every animation, every AI prompt, every database field, and every edge case is documented here.*

*If it's not in this document, it doesn't ship.*

*Document maintained by: Insights Lead*  
*Last updated: August 8, 2026*  
*Total sections: 21 + 5 Appendices*  
*Total features specified: 150+*  
*Total animations: 35+*  
*Total analytics events: 50+*  
*Total AI prompts: 5*  
*Total design rules: 15 (non-negotiable)*
