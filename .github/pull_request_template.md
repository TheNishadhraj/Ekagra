# What & why

<!-- One paragraph: what changes for the user, and why now. -->

## Rule compliance

Most of the 15 non-negotiable rules are enforced automatically by
`test/design_rules_test.dart` and the CI workflow. **Do not re-tick what CI
already proves** — only the rules below need human judgement, because no
test can evaluate them.

- [ ] **Rule 1** — no screen added here shows more than 3 primary choices
- [ ] **Rule 2** — no new action takes more than 2 taps
- [ ] **Rule 9** — no setup is forced before the user gets value
- [ ] **Rule 10** — feature parity: this works on both iOS and Android
- [ ] **Rule 12** — the screen does not go dark during focus mode

<details>
<summary>Enforced by CI (no action needed)</summary>

| Rule | Enforced by |
|---|---|
| 3 — no red | `design_rules_test.dart` + CI grep |
| 4, 5, 6, 15 — shame-free copy | `RsdSafeCopy` audit over user-facing strings |
| 8 — no subscription dark patterns | paywall governor tests |
| 13 — soft delete only | provider source scan |
| 14 — no user comparison | ranking-language scan |

</details>

## Monetization safety

Only tick if this PR touches pricing, gating or the paywall.

- [ ] Every feature advertised on a payment screen is `FeatureMaturity.live`
- [ ] `FeatureFlags` updated if a feature changed maturity
- [ ] No new hard gate added (there is exactly one, by design)

> Charging for a simulated feature is a misrepresentation and grounds for
> App Store removal — not a rough edge. See `lib/config/feature_flags.dart`.

## Verification

<!-- What did you actually run? Screenshots for UI changes. -->

- [ ] `flutter test` passes locally
- [ ] Tested on a physical device (not just simulator)
