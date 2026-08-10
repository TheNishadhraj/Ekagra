# 📋 SPECIALIST BRIEF: QA & RESILIENCE AGENT

- **From:** Chief Architect
- **To:** QA & Resilience Agent
- **Date:** 2026-08-10
- **Priority:** High / Immediate Execution

---

## 1. OBJECTIVE & QUESTION
We have established our initial architectural baseline for **Ekagra**. To ensure zero-defect execution and prevent data-loss modes or Rule-15 regressions, you are commissioned to design and implement a comprehensive test suite and resilience audit for Ekagra's core engines and providers.

---

## 2. CONSTRAINTS & INVARIANTS
1. **Rule-15 Hard Constraints:**
   - Verify that no UI string or error copy contains forbidden terms: `"streak"`, `"overdue"`, `"failed"`, `"missed"`, `"lazy"`, `"broken"`, `"behind"`.
   - Verify that no error color utilizes harsh red (`#FF0000`); confirm usage of Warm Coral (`#FFFF8C6B`).
2. **Offline-First Persistence Invariants:**
   - Confirm that corrupted JSON payloads in `SharedPreferences` do not crash provider initialization (`TaskProvider`, `SettingsProvider`, `RewardProvider`, `EnergyProvider`, `MoodProvider`).
3. **Engine Correctness:**
   - `AiService`: Validate deterministic ranking under varying energy/mood levels, micro-commitment generation, and skip penalties.
   - `RewardEngine`: Validate tier probabilities (~70% quick, ~25% medium, ~5% big) and ~5% rare drop frequency.
   - `FocusProvider`: Validate wall-clock duration calculation and background pause/resume delta accuracy.

---

## 3. REQUIRED DELIVERABLES
1. **Unit Test Suite (`test/unit/`):**
   - `test/unit/ai_service_test.dart`
   - `test/unit/reward_engine_test.dart`
   - `test/unit/rsd_safe_copy_test.dart`
   - `test/unit/provider_resilience_test.dart`
2. **Failure-Mode Analysis Report:**
   - Document edge cases tested and verified resilience mechanisms.

---

## 4. OUTPUT FORMAT
A structured summary of created unit tests, test coverage results, and a confirmation of Rule-15 compliance across all core business engines.
