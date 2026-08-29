# CI — one manual step still required (attempted 2026-08-26, blocked by token scope)

`github-workflow-ci.yml` is the pipeline. It is parked here because the
GitHub App used by the coding agent lacks the `workflows` permission:

- `git push` adding `.github/workflows/ci.yml` → rejected
  ("refusing to allow a GitHub App to create or update workflow ... without
  `workflows` permission")
- `PUT /repos/.../contents/.github/workflows/ci.yml` → 403
  ("Resource not accessible by integration")

**Activate it (30 seconds, from a laptop with normal repo write access):**

```bash
mkdir -p .github/workflows
git mv ci/github-workflow-ci.yml .github/workflows/ci.yml
git commit -m "Enable CI"
git push
```

Then delete this README. Until this lands, the gates do not run on PRs;
`tools/static_verify.py` is the interim static stand-in.

## What it enforces

| Gate | Why |
|---|---|
| `dart format --set-exit-if-changed` | Diff hygiene — keeps reviews about substance |
| `flutter analyze --fatal-infos` | The analyzer baseline is clean today; cheapest moment to keep it clean is now |
| `flutter test` | Rule compliance, monetization and startup-resilience suites |
| Red-colour grep | Rule 3, including files the Dart tests don't scan |
| `print()` grep | Debug leftovers never reach a release build |
| Release APK build (PRs only) | Catches tree-shaking, R8 and const-eval failures that debug builds and unit tests never surface |
