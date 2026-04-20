# Design: `cadence-testing` Skill

**Status:** Approved
**Date:** 2026-04-20
**Author:** Peter Argue
**Plugin:** `flow-dev`

## Goal

Add a new skill, `cadence-testing`, to the `flow-dev` plugin. It guides Cadence developers in writing, running, and debugging unit tests using the built-in Cadence Testing Framework (`Test` contract) and the Flow CLI's `flow test` command.

## Scope

In scope:

- Writing tests (`_test.cdc` files, lifecycle, assertions, matchers, blockchain emulation, events, time manipulation, mocking through contract substitution).
- Running tests (`flow test` with all flags, `flow.json` test aliases, coverage reports, CI integration, fork mode).
- Testing patterns and anti-patterns.

Out of scope:

- Generating test files from scratch. `cadence-scaffold` already exists and can be extended in a later change if desired.
- Integration tests that drive the emulator from external processes (not the framework's domain).
- Changing existing non-test skills' content beyond companion-skill cross-links.

## Style

Guide-style, matching `cadence-lang` and `cadence-audit`:

- Short SKILL.md body with a navigation map.
- Six focused reference files in `references/`, each 200–300 lines.
- Progressive disclosure: metadata → SKILL.md body → references on demand.

## Directory Layout

```
plugins/flow-dev/skills/cadence-testing/
    SKILL.md
    references/
        setup-and-basics.md
        assertions-and-matchers.md
        blockchain-emulation.md
        events-and-logs.md
        coverage-and-ci.md
        patterns.md
```

## SKILL.md Frontmatter

```yaml
---
name: cadence-testing
description: |
  Guide for writing, running, and debugging unit tests for Cadence smart contracts
  using the built-in Cadence Testing Framework and `flow test`. Covers test file
  structure (_test.cdc, setup/beforeEach/tearDown), assertions and matchers,
  blockchain emulation (accounts, deployments, events, time manipulation), coverage
  reports, CI integration, and testing patterns.
  TRIGGER when: writing Cadence unit tests, debugging failing tests, using
  Test.assert / Test.expect / Test.assertEqual / Test.expectFailure, matchers
  (Test.equal, Test.beGreaterThan, etc.), Test.newEmulatorBlockchain,
  executeTransaction / executeScript in tests, moveTime, eventsOfType in tests,
  `flow test`, `flow test --cover`, coverage reports, `_test.cdc`,
  "how do I test this contract", "test is flaky", "mock a capability in a test".
  DO NOT TRIGGER when: writing contract or transaction code itself (use cadence-lang),
  generating new contracts/transactions from scratch (use cadence-scaffold), auditing
  non-test code for security (use cadence-audit), running flow CLI commands other
  than `flow test` (use flow-cli), setting up flow.json contract aliases outside a
  testing context (use flow-project-setup).
---
```

## SKILL.md Body Structure

1. **One-paragraph overview.** The `Test` contract is built into Cadence. Tests live in `*_test.cdc` files and run via `flow test`. A test gets an emulator blockchain, can deploy contracts, send transactions, inspect events, and advance time.
2. **Key principles** (4 bullets):
   - Test lifecycle is `setup` / `beforeEach` / `afterEach` / `testXxx` / `tearDown`.
   - Each test should operate on a clean blockchain state (fresh blockchain in `setup()` or explicit `reset` in `beforeEach`).
   - Assertions: `Test.assert`, `Test.assertEqual`, `Test.expect(value, matcher)`, `Test.expectFailure(closure, errorSubstring)`.
   - Tests must cover happy paths plus failure paths (access-control denials, pre/post-condition violations, resource semantics).
3. **Navigation map** — 6-row table pointing to the reference files.
4. **Running tests — quick reference.** Four lines: `flow test`, `flow test --cover`, `flow test --name MyTest`, `flow test --seed 42`. Deeper details in `coverage-and-ci.md`.
5. **Companion Skills** — one-line entries for `cadence-lang`, `cadence-scaffold`, `cadence-audit`, `flow-cli`, `flow-project-setup`.

## Reference File Contents

### 1. `setup-and-basics.md` (~250 lines)

- Project layout: `cadence/contracts/`, `cadence/tests/`, `flow.json`.
- `flow.json` test aliases: contracts need a `"testing": "0x000000000000000N"` alias (range 0x05–0x0E).
- `_test.cdc` filename convention — required for `flow test` discovery.
- Full test lifecycle: `setup()` (once), `beforeEach()` / `afterEach()` (per test), `testXxx()` functions, `tearDown()` (once).
- Importing: `import Test`, importing contracts under test, `Test.readFile(path)` to load contract source from the filesystem.
- Minimal end-to-end hello-world example: deploy contract → run script → assert equals.
- Running with `flow test path/to/foo_test.cdc`.

### 2. `assertions-and-matchers.md` (~250 lines)

- Assertion functions: `Test.assert(cond, msg?)`, `Test.fail(msg?)`, `Test.assertEqual(expected, actual)`, `Test.expect(value, matcher)`, `Test.expectFailure(closure, errorMessageSubstring)`.
- Built-in matchers: `Test.equal`, `Test.beGreaterThan`, `Test.beLessThan`, `Test.beNil`, `Test.beEmpty`, `Test.haveElementCount`, `Test.contain`, `Test.beSucceeded`, `Test.beFailed`.
- Combinators: `Test.not(matcher)`, `matcher.and(other)`, `matcher.or(other)`.
- Custom matchers via `Test.newMatcher<T>(testFn)`.
- Idiom guidance: when to use `assertEqual` vs `expect(x, Test.equal(y))`.
- Testing reverts: wrap in `expectFailure` and match on a stable substring of the error.

### 3. `blockchain-emulation.md` (~300 lines)

- `Test.newEmulatorBlockchain()` and where to create it (`setup()` typical).
- Account management: `blockchain.createAccount()`, `blockchain.serviceAccount()`. `Account` fields: `address`, `publicKey`.
- Deploying: `blockchain.deployContract(name, path, args)`.
- `blockchain.useConfiguration(config)` — mapping import locations to addresses so `import "Foo"` resolves in tests.
- Script execution: `blockchain.executeScript(code, args)` → `ScriptResult { status, returnValue?, error? }`.
- Transactions: `Transaction { code, authorizers[], signers[], arguments[] }`, `executeTransaction(tx)` → `TransactionResult { status, error? }`.
- Queued execution: `addTransaction` + `executeNextTransaction` + `commitBlock`.
- State reset: `blockchain.reset(height)` for per-test isolation.
- Time manipulation: `blockchain.moveTime(delta)` for time-dependent logic (vesting, expirations, rate limits).
- Mocking via contract substitution — deploy a fake implementation under the same import name for isolated unit tests.

### 4. `events-and-logs.md` (~200 lines)

- `blockchain.events()` — all events across history.
- `blockchain.eventsOfType(type)` — filter to a specific event type.
- Fully qualified event type format: `A.<address>.<Contract>.<EventName>`.
- `blockchain.logs()` — reading `log()` output.
- Patterns: assert a single event fired, count events, inspect fields, assert ordered sequences.
- Pitfalls: events from `setup()` leaking into test assertions; type-string typos; comparing addresses with and without `0x`.

### 5. `coverage-and-ci.md` (~200 lines)

- `flow test --cover` and coverage output interpretation ("Coverage: X% of statements").
- `--coverprofile` (`coverage.json` default; `.lcov` supported).
- `--covercode=contracts|all`.
- Selecting tests: `--name <pattern>`, passing specific files or directories.
- Determinism: `--random`, `--seed <uint64>` (seed overrides random).
- Fork mode: `--fork`, `--fork-host`, `--fork-height`, and the `#test_fork(network: "mainnet", height: nil)` pragma.
- Minimal GitHub Actions workflow: install Flow CLI, run `flow test --cover --coverprofile=coverage.lcov`, upload to Codecov.

### 6. `patterns.md` (~300 lines)

- What to test: business logic, invariants, access-control boundaries, pre/post conditions, event emissions, failure paths. What to skip: standard-interface plumbing, framework internals.
- Arrange / act / assert structure.
- Test isolation strategies — fresh blockchain per test vs explicit `reset`. When each makes sense.
- Testing resources safely — move, inspect, destroy; never leak a resource in a test.
- Testing access control — unauthorized signer should hit `expectFailure`.
- Testing pre/post conditions — trigger violations and match the error substring.
- Treating events as part of the public API — assert them explicitly.
- Flakiness prevention — don't depend on wall clock (`moveTime`), don't depend on implicit block state.
- Anti-patterns: over-mocking, assertion-free tests, tests that only pass due to ordering, testing framework internals instead of contract behavior.

## Companion Skill Cross-Links

Small edits to existing SKILL.md files (Companion Skills sections):

- `cadence-lang/SKILL.md` — add:
  `cadence-testing` — Use alongside when writing tests for Cadence code. Tests are Cadence too and must follow the rules in this skill.
- `cadence-audit/SKILL.md` — add (if a Companion Skills section exists; otherwise skip):
  `cadence-testing` — Use to follow up on audit findings like "missing test coverage" or "edge case not tested" with concrete test-writing guidance.
- `cadence-scaffold/SKILL.md` — add:
  `cadence-testing` — Use to write tests for any scaffolded contract or transaction before deployment.

No other edits to existing references.

## Top-Level Catalog Updates

- **`.claude-plugin/marketplace.json`** — if the `flow-dev` plugin entry enumerates skills or keywords, add `cadence-testing`. If it does not enumerate them, no edit needed.
- **`README.md`**:
  - Add a row to the `flow-dev` skill table describing `cadence-testing`.
  - Update the skill list in the `flow-dev` row of the top summary table.
  - Update the Repository Structure tree to include `cadence-testing/` with `# 6 reference files`.
- **`CLAUDE.md`**:
  - Add two rows to the Skill Routing Guide table:
    - "Write unit tests for Cadence contracts" → `cadence-testing` | `cadence-lang`
    - "Debug failing Cadence tests / add coverage" → `cadence-testing` | `cadence-lang`, `cadence-audit`
  - Update the `skills/` listing in the Repository Structure section to include `cadence-testing/`.

## Acceptance Criteria

1. The new skill directory and all six references exist with the contents described above.
2. `SKILL.md` frontmatter matches the spec verbatim (or with agreed adjustments).
3. Each reference file is 200–300 lines, cites only APIs that appear in the verified Cadence Testing Framework surface, and includes at least one runnable Cadence code example.
4. All Cadence examples follow Cadence 1.0 syntax.
5. Companion-skill cross-links are added to `cadence-lang`, `cadence-audit` (if applicable), and `cadence-scaffold`.
6. `README.md` and `CLAUDE.md` routing tables and structure trees list the new skill.
7. No files under other skills are modified beyond the companion-link additions to `cadence-lang/SKILL.md`, `cadence-audit/SKILL.md` (if applicable), and `cadence-scaffold/SKILL.md`. No existing `references/*.md` files are touched.

## Verified API Surface

The reference content must stick to the APIs below (verified against cadence-lang.org/docs/testing-framework and developers.flow.com/tools/flow-cli/tests).

**Assertions:** `Test.assert`, `Test.fail`, `Test.assertEqual`, `Test.expect`, `Test.expectFailure`.

**Matchers:** `Test.equal`, `Test.beGreaterThan`, `Test.beLessThan`, `Test.beNil`, `Test.beEmpty`, `Test.haveElementCount`, `Test.contain`, `Test.beSucceeded`, `Test.beFailed`, `Test.not`, `matcher.and`, `matcher.or`, `Test.newMatcher<T>`.

**Blockchain:** `Test.newEmulatorBlockchain`, `createAccount`, `serviceAccount`, `deployContract`, `useConfiguration`, `executeScript`, `executeTransaction`, `addTransaction`, `executeNextTransaction`, `commitBlock`, `events`, `eventsOfType`, `logs`, `reset`, `moveTime`.

**Types:** `Transaction` (`code`, `authorizers`, `signers`, `arguments`), `ScriptResult` (`status`, `returnValue?`, `error?`), `TransactionResult` (`status`, `error?`), `Account` (`address`, `publicKey`), `Configuration`, `Error` (`message`).

**Utilities:** `Test.readFile(path)`.

**`flow test` flags:** `--cover`, `--coverprofile`, `--covercode`, `--name`, `--random`, `--seed`, `--fork`, `--fork-host`, `--fork-height`. Pragma: `#test_fork(network: "mainnet", height: nil)`. Testing address range: `0x0000000000000005`–`0x000000000000000E`.

## Risks & Open Questions

- **Open:** Does `.claude-plugin/marketplace.json` enumerate skills under the `flow-dev` plugin? (Checked during implementation; no edit if it doesn't.)
- **Open:** Does `cadence-audit/SKILL.md` currently have a Companion Skills section? (Checked during implementation; skip cross-link addition if absent.)
- **Risk:** The Cadence testing framework API can evolve between Cadence versions. Reference files target Cadence 1.0 (the version used throughout this repo) and should say so at the top of `setup-and-basics.md`.

## Non-Goals for This Change

- No test scaffolding/generation templates.
- No edits to `cadence-lang`, `cadence-audit`, or `cadence-scaffold` beyond the single companion-link lines.
- No new plugin — lives inside `flow-dev`.
