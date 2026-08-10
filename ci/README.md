# CI — one manual step required

`github-workflow-ci.yml` is the pipeline, parked here because the GitHub App
used to push this branch lacks the `workflows` permission and the push is
rejected outright.

**Activate it:**

```bash
mkdir -p .github/workflows
git mv ci/github-workflow-ci.yml .github/workflows/ci.yml
git commit -m "Enable CI"
git push
```

Do this from an account with normal repo write access — it works from a
laptop, it just can't be done by the agent's token.

## What it enforces

| Gate | Why |
|---|---|
| `dart format --set-exit-if-changed` | Diff hygiene — keeps reviews about substance |
| `flutter analyze --fatal-infos` | The analyzer baseline is clean today; cheapest moment to keep it clean is now |
| `flutter test` | Rule compliance, monetization and startup-resilience suites |
| Red-colour grep | Rule 3, including files the Dart tests don't scan |
| `print()` grep | Debug leftovers never reach a release build |
| Release APK build (PRs only) | Catches tree-shaking, R8 and const-eval failures that debug builds and unit tests never surface |

## Before the first green run

No Dart toolchain was available in the environment where this was written, so
`flutter analyze` and `flutter test` have **not been executed**. Verification
was static (delimiter lexing, exhaustive-switch checks, import resolution) plus
simulation of the test logic against the real model constructors.

Expect a handful of analyzer nits on the first run. If `--fatal-infos` proves
too strict for the existing baseline, relax that one step to `flutter analyze`
rather than deleting the job.
