# Coverage and CI

`flow test` is the single entry point for running the Cadence testing framework from the command line. It discovers every file ending in `_test.cdc` beneath the working directory, executes the tests against an in-process emulator, and prints a per-file summary. The same command supports targeted runs for a single file or subtree, coverage reporting in two output formats, deterministic random ordering for flaky-test diagnosis, and a fork mode that seeds the emulator with state from a live network. This reference covers the CLI surface and how to wire it into a GitHub Actions workflow.

The same `flow test` binary runs both on a developer machine and inside CI, which keeps the feedback loop honest: if a test passes locally, it will pass in CI unless the test genuinely depends on something outside the project tree (the wall clock, the network, a seeded random order). Those dependencies are exactly what the `--random`, `--seed`, and `--fork*` flags are there to expose or control.

## Running Tests

```bash
flow test                                     # all test files
flow test cadence/tests/Counter_test.cdc      # one file
flow test cadence/tests/                      # a directory
```

With no argument, `flow test` walks the current project looking for `_test.cdc` files and runs all of them. Pass a file to run a single test file; pass a directory to run every `_test.cdc` file beneath it recursively. Test files are independent — each one gets its own emulator instance, so running a subset produces the same per-file output as running the whole suite.

The working directory matters for import resolution: `flow test` reads `flow.json` from the current directory (or the nearest ancestor), and that manifest's `testing` aliases are what let the test file resolve `import "Counter"` and friends. Running `flow test` from outside the project tree fails at import time with a manifest-not-found error, so CI workflows should `cd` into the project root (or rely on `actions/checkout` placing the project at the workspace root) before invoking the command.

The exit status reflects the aggregate result: zero when every test passes, non-zero when any test or lifecycle function fails. CI systems that key on exit status (GitHub Actions, GitLab CI, Buildkite, and so on) therefore pick up failures without any extra wiring — a red check appears the moment a test regresses.

Unlike `go test` or `pytest`, `flow test` does not have a watch mode. For local rapid iteration, pair the CLI with a file watcher such as `entr`, `watchexec`, or an editor save hook that re-runs the relevant test file on every change. The fast emulator startup keeps the loop tight even without a dedicated watcher built into the tool.

## Flag Reference

| Flag | Description |
|---|---|
| `--cover` | Enable coverage collection for the run and print a coverage summary after the test results. |
| `--coverprofile` | Write the coverage profile to a file. Defaults to `coverage.json`; pass a path ending in `.lcov` to emit LCOV format instead. |
| `--covercode` | Scope coverage collection. `contracts` (default) covers only user contracts; `all` also covers transactions, scripts, and test files themselves. |
| `--name` | Run only test functions whose name matches the given pattern. Useful for iterating on a single failing test. |
| `--random` | Shuffle test execution order within each file to surface order-dependent bugs. |
| `--seed` | Shuffle with a specific `uint64` seed for reproducible ordering. Overrides `--random` when both are given. |
| `--fork` | Run against a blockchain seeded from a live network (`mainnet` or `testnet`) instead of a fresh emulator. |
| `--fork-host` | Override the gRPC access-node endpoint used when forking. Defaults to the public access node for the chosen network. |
| `--fork-height` | Pin the fork point to a specific block height. Without this flag the fork starts from the latest sealed block at the time of the run. |

Flags compose: `flow test --cover --coverprofile=coverage.lcov --random --name Counter` is a perfectly valid single invocation that runs only tests whose name contains `Counter`, in shuffled order, with coverage collection enabled and output written to `coverage.lcov`. There are no mutually exclusive pairs other than the `--random`/`--seed` interaction noted below.

## Coverage

`flow test --cover` prints a coverage summary line at the end of the run, of the form:

```
Coverage: 87.5% of statements
```

The percentage reports the fraction of statements in the covered code (see `--covercode`) that executed at least once during the test run. Coverage collection is off by default because instrumenting every executed statement measurably slows the suite down — turn it on in CI, leave it off during the tight local edit-test loop.

`--coverprofile` writes the full per-file breakdown to disk. The default path is `coverage.json`:

```bash
flow test --cover --coverprofile=coverage.json
```

To emit the same profile in LCOV format for tools that consume `.lcov` (Codecov, Coveralls, most IDE plugins), use a `.lcov` extension:

```bash
flow test --cover --coverprofile=coverage.lcov
```

`--covercode=contracts` (the default) restricts coverage tracking to the contract sources your project defines. `--covercode=all` widens the scope to include transactions, scripts, and the test files themselves — useful when you want to confirm that every branch of a complex transaction body is exercised, but noisier in the summary.

Coverage is a blunt instrument: a high percentage means every line ran, not that every line behaved correctly. A contract can hit 100% coverage with a suite that never checks return values or emitted events, and the tests will still miss real bugs. Treat coverage as a floor — a low number is a clear signal that the suite has holes — and lean on the assertion quality review to catch cases where the tests execute code without meaningfully exercising it.

Branch coverage and statement coverage are different numbers, and `flow test --cover` reports statement coverage. A statement that contains an `if`/`else` with only the true branch exercised still counts as covered. For the most rigorous confidence, pair the coverage percentage with a manual review of untested conditional branches — the coverage report tells you which lines were skipped entirely, but it cannot tell you which predicate arms were never taken.

The JSON profile format is a map from contract identifier to an array of line-by-line hit counts, which makes it straightforward to diff between runs or to feed into a custom dashboard. The LCOV profile is line-oriented text that most third-party coverage viewers (Codecov, Coveralls, the VS Code Coverage Gutters extension) consume directly. Pick the format that fits the consumer; the underlying data is the same.

When tests use `blockchain.reset(height:)` to roll back state between cases, coverage continues to accumulate across the full run — `reset` rolls back chain state, not the coverage tracker. A suite that aggressively resets still contributes all of its executed lines to the final percentage, which is the right behaviour: the goal is to know which statements ran at least once, not which statements ran in the most recent snapshot.

## Deterministic Ordering

```bash
flow test --random
flow test --seed 1729
```

`--random` shuffles the execution order of test functions within each file before running them. The lifecycle functions (`setup`, `beforeEach`, `afterEach`, `tearDown`) still run in their declared slots; only the `testXxx` cases are reordered. Running with `--random` regularly is a cheap way to catch tests that accidentally depend on the declaration order of their siblings.

Shuffling is per-file: each file's tests are reordered independently, and the across-file order (which file runs first) is not randomised. This matches the isolation boundary the framework already enforces — tests in different files share no state — so cross-file reordering would not surface any new class of bug. Within a file, the shuffle can expose mutations that leak through `access(all) let` bindings or uncleared storage, which is where order-dependent bugs actually hide.

`--seed <uint64>` uses the given seed to drive the shuffle, producing the same order on every run. When `--random` and `--seed` are both passed, `--seed` wins — the run is reordered but deterministic. Save the seed from a failing CI run and replay it locally with `--seed` to reproduce the same order without guessing.

A healthy CI pipeline emits a fresh seed with every run and prints it in the workflow logs. When a flake appears, the seed from the failing run goes straight back into a local `flow test --seed <seed>` invocation, and the failure reproduces on the first try. Without that hook, chasing order-dependent flakes is pure guesswork — the shuffle is genuinely random, so the odds of stumbling on the same ordering a second time are negligible.

A common pattern is a PR-gating workflow that runs with the default in-file order (no `--random`, no `--seed`) and a nightly workflow that runs with `--random`. The PR gate stays fast and predictable; the nightly catches order-dependence before it ships. When the nightly fails, open the job log, copy the seed, run `flow test --seed <seed>` locally, and fix the bug once.

## Fork Mode

Fork mode boots the emulator with state copied from a live Flow network, so a test can exercise a contract against real mainnet or testnet balances, deployed contract versions, and capability graphs. The forked blockchain is still an in-process emulator — reads against it look the same as reads against a plain emulator, but the initial state is whatever the live network had at the pinned height. Enable it in a test file with the `#test_fork` pragma:

```cadence
#test_fork(network: "mainnet", height: nil)

import Test

access(all) let blockchain = Test.newEmulatorBlockchain()
```

`height: nil` forks from the latest sealed block at the time of the run. Pass a specific `UInt64` to pin the fork to a historical height — the canonical way to write regression tests against known-good on-chain state. Mixing pinned and unpinned tests in the same suite is fine; each test file with a pragma gets its own forked blockchain at whatever height the pragma specifies.

The CLI has equivalent flags for ad-hoc runs:

```bash
flow test --fork mainnet --fork-height 100000000
flow test --fork testnet --fork-host access.testnet.nodes.onflow.org:9000
```

`--fork-host` lets you point at a private or community access node instead of the default public endpoint. Useful when the public node is rate-limiting or when your organisation runs its own archival node for historical queries. The host string is a gRPC endpoint (`host:port`), not an HTTP URL; use `access.mainnet.nodes.onflow.org:9000` or the equivalent testnet endpoint as a template when pointing at a custom node.

The pragma form and the CLI flags are equivalent but solve different problems. The pragma is version-controlled and travels with the test file, so the fork source stays reproducible even when a teammate checks out the repo and runs the suite for the first time. The flags are better for one-off experiments and for rehearsal workflows where the fork network or height is parameterised by the pipeline.

Fork tests are integration-style: they read real contract state, so they are slower and less deterministic than plain emulator tests (the forked state changes whenever the source network advances unless `--fork-height` pins it). Keep the bulk of your suite on the plain emulator and use fork mode only for the handful of tests that genuinely need live state.

The common scenarios for fork mode are upgrade rehearsals ("apply this contract update to a copy of mainnet and confirm existing balances survive"), integration checks against third-party protocols that are hard to stub, and regression tests for historical incidents (pin the fork to a block just before a bug manifested and reproduce the original conditions deterministically). For every other test, a plain emulator run with explicit fixtures is faster, more reproducible, and easier to reason about.

When a fork test fails, the error message typically reports the failing assertion the same way a plain emulator test would, but the state it ran against came from a snapshot of a live network. Pin the fork to a specific height on the first green run and never change it — the alternative is chasing ambient state changes on mainnet, which is a miserable way to diagnose a failing assertion.

## Example Output

A typical passing run looks like:

```
Test results: "cadence/tests/Counter_test.cdc"
- PASS: testInitialCountIsZero
- PASS: testIncrementAddsOne
- PASS: testResetReturnsToZero
3 tests, 3 passed, 0 failed

Test results: "cadence/tests/Registry_test.cdc"
- PASS: testRegisterAddsCounter
- FAIL: testDuplicateRegisterFails
        assertion failed: expected transaction to fail, got success
1 tests, 0 passed, 1 failed

Coverage: 82.4% of statements
```

Each file gets its own header, per-test PASS/FAIL lines, and a summary. Failing assertions print the matcher's rendered message immediately below the `FAIL` line. The coverage line appears only when `--cover` is set.

The summary line is the line CI pipelines typically grep for when building status badges or posting Slack notifications — it is stable across Flow CLI versions and always matches the pattern `N tests, N passed, N failed`. If the suite errors out before running any test (for example, a missing `testing` alias in `flow.json`), you will see an explicit error line instead and the exit status is still non-zero, so a simple `exit-on-error` CI script catches both categories.

## GitHub Actions Workflow

GitHub Actions is the most widely used CI target for Flow projects, and the Flow CLI ships with first-class support for it. The same pattern ports to GitLab CI, CircleCI, and Buildkite with minimal changes — the install step stays identical, and the `flow test` invocation is the same everywhere.

A minimal CI workflow that installs the Flow CLI, runs the tests with coverage, and uploads the profile:

```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Flow CLI
        run: sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
      - name: Run tests with coverage
        run: flow test --cover --coverprofile=coverage.lcov
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.lcov
```

The install script drops the `flow` binary into a directory on the runner's `PATH`, so the next step can invoke `flow test` directly. Using `--coverprofile=coverage.lcov` produces the format Codecov (and most other coverage services) consume natively — if you prefer the native JSON profile, change the extension to `.json` and configure the upload action accordingly.

Pin `actions/checkout` and `codecov/codecov-action` to explicit major versions so a breaking upstream release does not silently break CI. The Flow CLI install script pulls the latest stable release; if you need to pin a specific CLI version, replace the one-liner with a targeted download.

For monorepos where a single workflow runs tests in multiple Flow projects, wrap the `flow test` step in a matrix that iterates over project directories and sets `working-directory` on each step. Each matrix entry produces its own `coverage.lcov` — either upload them with distinct artifact names or give each job its own Codecov flag so the service tracks them separately. Sharing a single coverage file between jobs almost always ends in one job overwriting another's profile and the final number being meaningless.

The install step runs every job on a clean runner, which keeps builds reproducible but adds about ten seconds per job for the download. For pipelines that run many short jobs, cache the installed binary with `actions/cache` keyed on the Flow CLI version string to amortise the install cost across the matrix. For a single-job workflow the cache is not worth the added complexity.

For private repositories, add a `secrets: CODECOV_TOKEN` reference and pass it through to the `codecov/codecov-action` step via `token: ${{ secrets.CODECOV_TOKEN }}` — Codecov's tokenless upload works only for public repos. Coveralls and other services have equivalent token conventions; check their action's documentation for the exact shape.

The workflow above runs on `ubuntu-latest`, which is the cheapest and fastest option for Flow CLI tests. There is no platform-specific behaviour in the emulator, so matrix-ing across operating systems wastes minutes without catching any real bug. Reserve multi-OS matrices for the frontend or SDK portions of a project — the Cadence suite itself only needs one.

Concurrency control is worth adding once the workflow becomes a bottleneck. A `concurrency` block keyed on the branch name cancels superseded runs so a developer who pushes three commits in a minute only burns runner minutes on the latest commit:

```yaml
concurrency:
  group: test-${{ github.ref }}
  cancel-in-progress: true
```

Drop that block alongside the `jobs:` key at the top of the workflow file. For `main` branch pushes you usually want every run to complete (so the history shows each commit's real status); key the `group:` on `github.head_ref || github.ref` to scope the cancellation to pull-request branches only.

## Tips

- **Local dev loop.** Use `flow test --name <pattern>` while iterating on a single failing test. It re-runs only tests whose name contains the pattern, which turns a full-suite run into a sub-second loop for tight TDD cycles. Drop the flag once the test passes and re-run the whole file to confirm the change did not break a sibling.
- **Coverage in PR comments.** Codecov, Coveralls, and similar services post a coverage delta as a comment on every pull request when the workflow uploads an LCOV profile. The delta is what reviewers actually look at — the absolute number matters less than whether the change moved it up or down. A PR that drops coverage materially deserves a review comment asking what the missing tests would be.
- **Store the profile as a CI artifact.** Add an `actions/upload-artifact@v4` step after the test step to keep `coverage.json` or `coverage.lcov` attached to each run. The artifact survives even when the coverage service is down and gives you something to diff against when a later run regresses. Seven-day retention is usually enough — longer retention fills storage with profiles nobody reads.
- **Run with `--random` periodically.** Scheduled runs on a nightly cron with `--random` catch order-dependent flakes before they reach `main`. When a shuffle run fails, capture the seed from the output and reproduce locally with `--seed`.
- **Keep fork tests on a separate workflow.** Fork mode hits a live network, so it is slower and less reliable than the plain emulator suite. Put fork tests behind a workflow dispatch trigger or a nightly schedule, and keep the PR-gating workflow on fork-free tests. A flaky fork test that blocks every PR is a recipe for developers routinely overriding a red CI.
- **Fail fast on a single regression.** `flow test` runs every discovered file even after one fails, which is usually what you want — the full report is more informative than a truncated one — but for very large suites where the first failure tells you enough, invoking `flow test <specific/file.cdc>` from a pre-push hook keeps the dev loop tight. Save the full-suite run for CI.
- **Review coverage diffs, not absolutes.** A well-tested project plateaus at whatever percentage its ratio of untested error paths and defensive checks to active logic dictates. What matters for each PR is whether the number moved down — a regression of even a few percent usually means a new branch went in without a corresponding test.
- **Pin a fork height per regression test.** When a fork-mode test is wired as a regression for a historical bug, pin `--fork-height` (or the `height:` argument in the pragma) to a block just before the bug's triggering transaction. The test then reproduces the exact on-chain conditions the bug surfaced in, which is the whole point of using fork mode for a regression.
- **Match workflow name to purpose.** If the repo has both a PR-gating workflow and a nightly workflow, name them clearly (`Test` and `Nightly Test`, say). Developers who see a red `Nightly Test` check should know at a glance that it is not blocking the PR, only flagging a latent flake for follow-up.
- **Keep `flow.json` aliases tidy.** CI runs with the same manifest everyone else uses, and a missing `testing` alias on a new contract surfaces as an import-resolution failure long before any assertion runs. Add the `testing` entry the moment a new contract joins the project, not after the first failing CI run asks for it.
