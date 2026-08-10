# 🏗️ EKAGRA — SYSTEM ARCHITECTURE SPECIFICATION

This document outlines the system architecture, component relationships, data flow, state management, persistence strategy, and key system invariants for **Ekagra**.

---

## 1. System Overview & Principles

Ekagra is built as an **offline-first, client-driven Flutter application** optimized for zero friction, high responsiveness, and complete protection against user data loss.

### Core Architectural Principles
1. **Offline Primacy:** Every core feature (Brain Dump, "Pick One Thing" AI recommendation, Focus Timer, Dopamine Rewards, Visual Time Compass) functions 100% offline without cloud latency or network dependency.
2. **Quarantine-Over-Delete:** User data (tasks, rewards, energy logs) is never destructively wiped on delete/archive; soft-delete flags (`isDeleted`, `status: archived`) ensure recoverability.
3. **State Integrity & Defensive Persistence:** Local storage writes are isolated, sanitized, and resilient against unexpected app termination (force-quit mid-write).
4. **Shame-Free Boundary Invariants:** System copy, state transitions, and error handlers strictly conform to Ekagra's 15 Non-Negotiable Design Rules (Rule-15 Compliance).

---

## 2. Component Hierarchy & Layering

The application follows a clean 3-layer architecture:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER (UI)                         │
│  - MainShell & Navigation Routes (AppRoutes)                           │
│  - Screens: Welcome, Home (The Board), BrainDump, DayView, Focus, etc. │
│  - Reusable Widgets: EkagraCard, EnergyGauge, FocusRing, TaskChip      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        BUSINESS / PROVIDER LAYER                       │
│  - TaskProvider        (Task list, AI scoring, 1-Thing selection)      │
│  - FocusProvider       (Timer state, wall-clock reconciliation)        │
│  - RewardProvider      (Dopamine menu, variable ratio engine)          │
│  - SettingsProvider    (User profile, ADHD traits, theme, entitlement) │
│  - EnergyProvider      (Energy levels, check-in intervals)             │
│  - MoodProvider        (Mood levels, check-in intervals)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        SERVICES & PERSISTENCE                          │
│  - AiService           (Hybrid offline task scoring & micro-commitments)│
│  - RewardEngine        (Variable ratio reward rolling 70/25/5 + rare)  │
│  - SharedPreferences   (Local JSON persistence layer with safe parsing) │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Data Flow & State Management

State management uses Flutter's `Provider` framework with `ChangeNotifier` reactive providers:

### Main Data Flows:
1. **App Initialization Flow:**
   `main.dart` -> `Future.wait([settings.load(), tasks.load(), energy.load(), mood.load(), rewards.load()])` -> `EkagraApp` initializes route (`/welcome` or `/main`).

2. **"Pick One Thing" AI Recommendation Flow:**
   User energy/mood update -> `EnergyProvider`/`MoodProvider` updates state -> `TaskProvider.refreshOneThing(energy, mood)` triggers `AiService.pickOneThing()` -> UI updates "Pick One Thing" card reactively.

3. **Focus Session Flow:**
   User selects task -> `FocusProvider.setTask(task)` -> User taps Start -> Wall-clock `startedAt` and `endsAt` set -> Ticker fires every 1s updating `remaining` -> On completion, `FocusProvider.complete()` records focus minutes -> `RewardProvider.recordTaskCompletion()` rolls reward via `RewardEngine`.

---

## 4. Local Persistence & Resilience Strategy

- **Storage Engine:** `SharedPreferences` storing key-value pairs of JSON string arrays (`ekagra_tasks`, `ekagra_user`, `ekagra_dopamine_menu`, `ekagra_rewards`, `ekagra_energy_logs`, `ekagra_mood_logs`).
- **Resilience Controls:**
  - Standardized JSON serialization/deserialization with null-safety defaults.
  - Safe try-catch wrappers around `jsonDecode()` to prevent startup crashes on corrupted payload.
  - Graceful fallback to default initial state when storage is empty or invalid.

---

## 5. Non-Negotiable System Invariants (Rule-15 Compliance)

| Invariant | Specification | Enforcement Mechanism |
|---|---|---|
| **Max Primary Choices** | Screen must show ≤ 3 primary action choices | UI Layouts & Widget constraints |
| **Max Action Taps** | Primary actions complete in ≤ 2 taps | Screen flow & Direct actions |
| **No Negative Red** | Error/Negative states use Warm Coral (`0xFFFF8C6B`) | `EkagraColors.error` theme constant |
| **Forbidden Words** | "streak", "overdue", "failed", "missed" banned | `RsdSafeCopy.isSafe()` & Unit tests |
| **Task Counts** | Incomplete/pending task count never displayed | `TaskProvider` getters exclude count UI |
| **Quarantine / Soft Delete** | Tasks marked `isDeleted = true`, never purged | `TaskProvider.archiveTask()` |
| **Honest Monetization** | Simulated features are free/honestly labeled | `SettingsProvider` & Paywall sheets |
