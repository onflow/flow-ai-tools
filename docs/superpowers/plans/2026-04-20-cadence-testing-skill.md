# `cadence-testing` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `cadence-testing` skill under the `flow-dev` plugin that guides Cadence developers in writing and running unit tests with the built-in Cadence Testing Framework and `flow test`.

**Architecture:** Guide-style skill (matches `cadence-lang`, `cadence-audit`) — short `SKILL.md` with a navigation map pointing at six focused reference files in `references/`. Pure documentation; no executable code. Companion-skill cross-links added to three existing skills. Top-level `README.md` and `CLAUDE.md` updated to surface the skill.

**Tech Stack:** Markdown with YAML frontmatter. Cadence 1.0 syntax for any in-doc examples. Verification via `claude plugin validate .` and targeted `grep` checks.

**Spec reference:** `docs/superpowers/specs/2026-04-20-cadence-testing-skill-design.md`

**Working directory:** All paths are relative to `/Users/pargue/dev/onflow/flow-ai-tools/.worktrees/peter-testing-framework`.

---

## Conventions used throughout this plan

- **No TDD** — this is a documentation-only change; "verification" is `grep` / `claude plugin validate` / structural inspection instead of running tests.
- **Commit after every task** with a concise imperative message. Prefer `git add <specific files>` over `git add .` to avoid picking up stray edits.
- **Every reference file must start with** `# <Title>` H1, end with a blank line, stay between 200 and 300 lines, use Cadence 1.0 syntax, and cite only APIs present in the Verified API Surface section of the spec.
- **Quoting Cadence code** — fenced as ` ```cadence `. Import lines use string form: `import Test`, `import "Counter"`.
- When a step says "run: `<command>`" you run it exactly. When a step says "verify:" use the `grep`/`ls` command shown.

---

## File Structure

New files (all under `plugins/flow-dev/skills/cadence-testing/`):

| File | Responsibility |
|------|----------------|
| `SKILL.md` | Skill entry point: frontmatter, overview, key principles, navigation map, quick-start, companion skills. |
| `references/setup-and-basics.md` | Project layout, `flow.json` test aliases, `_test.cdc` structure, lifecycle functions, imports, minimal example. |
| `references/assertions-and-matchers.md` | Assertion functions, built-in matchers, combinators, custom matchers, `expectFailure`. |
| `references/blockchain-emulation.md` | `Test.newEmulatorBlockchain`, accounts, deploy, scripts, transactions, reset, `moveTime`, contract-substitution mocking. |
| `references/events-and-logs.md` | `events`, `eventsOfType`, `logs`, event-type format, assertion patterns, pitfalls. |
| `references/coverage-and-ci.md` | `flow test` flags, coverage output, determinism, fork mode, GitHub Actions example. |
| `references/patterns.md` | What to test, AAA structure, isolation, resources, access control, pre/post, flakiness prevention, anti-patterns. |

Modified files:

| File | Change |
|------|--------|
| `plugins/flow-dev/skills/cadence-lang/SKILL.md` | Add one line under "Companion Skills". |
| `plugins/flow-dev/skills/cadence-audit/SKILL.md` | Add one line under "Companion Skills". |
| `plugins/flow-dev/skills/cadence-scaffold/SKILL.md` | Add one line under "Companion Skills". |
| `README.md` | Add one row to the `flow-dev` skill table, extend the plugin summary row, add entry to the Repository Structure tree. |
| `CLAUDE.md` | Add two rows to the Skill Routing Guide, add entry to the Repository Structure `skills/` block. |

`.claude-plugin/marketplace.json` does NOT enumerate skills — no edit.

---

## Task 1: Create skill directory and SKILL.md

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/SKILL.md`

- [ ] **Step 1: Create the skill directory**

Run:
```bash
mkdir -p plugins/flow-dev/skills/cadence-testing/references
```

Verify:
```bash
ls plugins/flow-dev/skills/cadence-testing
```
Expected output: `references` (and nothing else yet).

- [ ] **Step 2: Write `SKILL.md`**

Create `plugins/flow-dev/skills/cadence-testing/SKILL.md` with this exact content:

````markdown
---
name: cadence-testing
description: |
  Guide for writing, running, and debugging unit tests for Cadence smart contracts using the built-in Cadence Testing Framework and `flow test`. Covers test file structure (_test.cdc, setup/beforeEach/tearDown), assertions and matchers, blockchain emulation (accounts, deployments, events, time manipulation), coverage reports, CI integration, and testing patterns.
  TRIGGER when: writing Cadence unit tests, debugging failing tests, using Test.assert / Test.expect / Test.assertEqual / Test.expectFailure, matchers (Test.equal, Test.beGreaterThan, etc.), Test.newEmulatorBlockchain, executeTransaction / executeScript in tests, moveTime, eventsOfType in tests, `flow test`, `flow test --cover`, coverage reports, `_test.cdc`, "how do I test this contract", "test is flaky", "mock a capability in a test".
  DO NOT TRIGGER when: writing contract or transaction code itself (use cadence-lang), generating new contracts/transactions from scratch (use cadence-scaffold), auditing non-test code for security (use cadence-audit), running flow CLI commands other than `flow test` (use flow-cli), setting up flow.json contract aliases outside a testing context (use flow-project-setup).
---

# Cadence Testing Guide

Write and run unit tests for Cadence smart contracts using the built-in `Test` contract and the Flow CLI's `flow test` command. Tests are Cadence files named `*_test.cdc` that get an emulator blockchain, deploy contracts, execute scripts and transactions, and assert expected behavior.

## Key Principles

1. **Lifecycle is fixed** — `setup()` runs once, `beforeEach()` / `afterEach()` wrap every test, `testXxx()` functions are the test cases, and `tearDown()` runs once at the end. All are optional except the test functions.
2. **Start each test from a clean state** — create the blockchain in `setup()` and either reset snapshots per test or create fresh resources in `beforeEach()`.
3. **Use the right assertion** — `Test.assert(cond, msg?)` for boolean checks, `Test.assertEqual(expected, actual)` for equality, `Test.expect(value, matcher)` for matcher-based checks, and `Test.expectFailure(closure, errorSubstring)` for expected failures.
4. **Cover failure paths** — access-control denials, pre/post-condition violations, and resource-ownership errors are the parts of the contract that bugs hide in. Every test file should include at least one `expectFailure` case.

## Navigation

| Task | Reference |
|------|-----------|
| Project layout, `flow.json` test aliases, lifecycle, first test | [setup-and-basics.md](references/setup-and-basics.md) |
| Assertions, matchers, combinators, custom matchers, `expectFailure` | [assertions-and-matchers.md](references/assertions-and-matchers.md) |
| Accounts, deployments, scripts, transactions, `reset`, `moveTime`, mocking | [blockchain-emulation.md](references/blockchain-emulation.md) |
| Events and logs — reading, filtering, asserting | [events-and-logs.md](references/events-and-logs.md) |
| Running tests, coverage, determinism, fork mode, CI | [coverage-and-ci.md](references/coverage-and-ci.md) |
| Testing patterns, isolation, flakiness prevention, anti-patterns | [patterns.md](references/patterns.md) |

## Running Tests — Quick Reference

```bash
flow test                                 # run every *_test.cdc it can find
flow test cadence/tests/Counter_test.cdc  # run a specific file
flow test --cover                         # with coverage report
flow test --name testMintWorks            # only tests whose name matches
flow test --seed 42                       # deterministic random order
```

Full flag reference and CI integration live in [coverage-and-ci.md](references/coverage-and-ci.md).

## Companion Skills

- **`cadence-lang`** — Essential. Tests are Cadence too; all access control, resource, and capability rules apply.
- **`cadence-scaffold`** — Generate the contracts and transactions you're about to test.
- **`cadence-audit`** — After writing tests, audit the contracts they cover. Audit findings often point back at missing tests.
- **`flow-cli`** — Background on non-test CLI commands. This skill covers `flow test` in depth.
- **`flow-project-setup`** — Configuring `flow.json` outside a testing context.
````

- [ ] **Step 3: Verify frontmatter parses**

Verify:
```bash
head -8 plugins/flow-dev/skills/cadence-testing/SKILL.md
```
Expected: first line is `---`, last line of the fence is `---` on line matching your file. YAML block contains `name: cadence-testing`.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/SKILL.md
git commit -m "Add cadence-testing skill scaffold"
```

---

## Task 2: Write `references/setup-and-basics.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/setup-and-basics.md`

**Required content outline (write in this order):**

1. H1: `# Setup and Test Basics`
2. Version note paragraph: "Targets Cadence 1.0 and the Flow CLI testing framework shipped with recent Flow CLI releases."
3. H2 `## Project Layout` — canonical directory tree with `cadence/contracts/`, `cadence/transactions/`, `cadence/scripts/`, `cadence/tests/`, `flow.json`. Note that tests live in `cadence/tests/` by convention but any path works with `flow test`.
4. H2 `## `flow.json` Aliases for Tests` — explain that every contract imported by tests needs a `testing` alias under `aliases`. Show a complete `flow.json` snippet:
   ```json
   {
     "contracts": {
       "Counter": {
         "source": "cadence/contracts/Counter.cdc",
         "aliases": {
           "testing": "0x0000000000000007"
         }
       }
     }
   }
   ```
   List the full testing address range: `0x0000000000000005` through `0x000000000000000E`. Note that standard contracts like `FungibleToken` / `NonFungibleToken` get implicit testing aliases.
5. H2 `## File Naming` — filename must end with `_test.cdc`, placed anywhere discoverable; explain how `flow test` auto-discovers them.
6. H2 `## Test File Lifecycle` — list and explain each function:
   - `setup()` — once, before any test. Typical: create blockchain, deploy contracts.
   - `beforeEach()` — before every `testXxx`. Typical: reset state.
   - `afterEach()` — after every `testXxx`. Typical: cleanup.
   - `testXxx()` — test case functions, no params, no return value. Name must begin with `test`.
   - `tearDown()` — once, after all tests.
   Note all are optional except that you need at least one `testXxx`.
7. H2 `## Imports` — `import Test` is implicit (always available). Show importing a contract under test: `import "Counter"`. Cover `Test.readFile(path)` for loading source code from disk before deployment.
8. H2 `## Minimal Example` — full, runnable `Counter_test.cdc`:
   ```cadence
   import Test

   access(all) let blockchain = Test.newEmulatorBlockchain()
   access(all) let admin = blockchain.createAccount()

   access(all) fun setup() {
       let err = blockchain.deployContract(
           name: "Counter",
           path: "../contracts/Counter.cdc",
           arguments: []
       )
       Test.expect(err, Test.beNil())
   }

   access(all) fun testInitialCountIsZero() {
       let script = Test.readFile("../scripts/get_count.cdc")
       let result = blockchain.executeScript(script, [])
       Test.expect(result, Test.beSucceeded())
       Test.assertEqual(0 as Int, result.returnValue! as! Int)
   }
   ```
9. H2 `## Running the Example` — `flow test cadence/tests/Counter_test.cdc`, expected "1 passing" output shape.
10. H2 `## Common Setup Pitfalls` — bullet list:
    - Forgetting the `testing` alias (test fails with "cannot find contract").
    - Paths in `Test.readFile` / `deployContract` are relative to the test file, not the project root.
    - `setup()` errors aren't reported as test failures — assert with `Test.expect(err, Test.beNil())`.

**Length target:** 220–260 lines.

- [ ] **Step 1: Write the file**

Write `plugins/flow-dev/skills/cadence-testing/references/setup-and-basics.md` following the outline above.

- [ ] **Step 2: Verify required APIs are cited**

Run:
```bash
grep -n -E "Test\.newEmulatorBlockchain|deployContract|Test\.readFile|setup\(\)|beforeEach|afterEach|tearDown|_test\.cdc|testing.*0x" plugins/flow-dev/skills/cadence-testing/references/setup-and-basics.md
```
Expected: every keyword appears at least once.

- [ ] **Step 3: Verify length**

Run:
```bash
wc -l plugins/flow-dev/skills/cadence-testing/references/setup-and-basics.md
```
Expected: between 200 and 300. If under, expand pitfalls and example commentary. If over, split the minimal example into two smaller ones rather than dropping content.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/setup-and-basics.md
git commit -m "Add cadence-testing setup-and-basics reference"
```

---

## Task 3: Write `references/assertions-and-matchers.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/assertions-and-matchers.md`

**Required content outline:**

1. H1: `# Assertions and Matchers`
2. Intro paragraph — two assertion styles: direct (`Test.assert`, `Test.assertEqual`, `Test.fail`) and matcher-based (`Test.expect(value, matcher)`). Matchers compose with `and` / `or` / `not`.
3. H2 `## Direct Assertions` — table listing `Test.assert(cond, msg?)`, `Test.fail(msg?)`, `Test.assertEqual(expected, actual)` with a one-line code example for each.
4. H2 `## Matcher-Based Assertions` — `Test.expect(value, matcher)` and `Test.expectFailure(closure, errorMessageSubstring)`. Show the closure form:
   ```cadence
   Test.expectFailure(fun(): Void {
       // code expected to fail
       panic("not authorized")
   }, errorMessageSubstring: "not authorized")
   ```
5. H2 `## Built-in Matchers` — one subsection per matcher with a 2-3 line example for each:
   - `Test.equal(value)`
   - `Test.beGreaterThan(number)`
   - `Test.beLessThan(number)`
   - `Test.beNil()`
   - `Test.beEmpty()`
   - `Test.haveElementCount(int)`
   - `Test.contain(element)`
   - `Test.beSucceeded()`
   - `Test.beFailed()`
6. H2 `## Combinators` — `Test.not(m)`, `m.and(other)`, `m.or(other)`. One combined example:
   ```cadence
   let positive = Test.beGreaterThan(0)
   let small = Test.beLessThan(100)
   Test.expect(42, positive.and(small))
   ```
7. H2 `## Custom Matchers` — `Test.newMatcher<T>(testFn)`. Show a custom matcher that checks a string starts with a prefix.
8. H2 `## `assertEqual` vs `expect(x, Test.equal(y))`` — when to use which:
   - `assertEqual` when you just need equality (simpler error output).
   - `expect` + `Test.equal` when combining with `and`/`or`/`not` or when you want to reuse the matcher.
9. H2 `## Testing Reverts` — pattern for expecting transactions/scripts to fail:
   - Wrap in `expectFailure` **or** inspect `ScriptResult`/`TransactionResult` directly with `Test.expect(result, Test.beFailed())` then assert on `result.error!.message`.
   - Match on a stable substring only (contract error messages often include addresses/nonces that change per run).
10. H2 `## Common Mistakes` — bullet list:
    - Comparing resource addresses without `0x` prefix stripping.
    - Using `assertEqual` across types that don't implement `Equatable`.
    - Overly specific error substrings in `expectFailure` that break when a contract adds context to its panic message.

**Length target:** 230–270 lines.

- [ ] **Step 1: Write the file** following the outline.

- [ ] **Step 2: Verify required APIs are cited**

Run:
```bash
grep -n -E "Test\.assert\b|Test\.fail\b|assertEqual|Test\.expect\b|expectFailure|Test\.equal|beGreaterThan|beLessThan|beNil|beEmpty|haveElementCount|Test\.contain|beSucceeded|beFailed|Test\.not|\.and\(|\.or\(|newMatcher" plugins/flow-dev/skills/cadence-testing/references/assertions-and-matchers.md
```
Expected: every keyword appears at least once.

- [ ] **Step 3: Verify length**

Run: `wc -l plugins/flow-dev/skills/cadence-testing/references/assertions-and-matchers.md`
Expected: 200–300.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/assertions-and-matchers.md
git commit -m "Add cadence-testing assertions-and-matchers reference"
```

---

## Task 4: Write `references/blockchain-emulation.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/blockchain-emulation.md`

**Required content outline:**

1. H1: `# Blockchain Emulation`
2. Intro — emulation gives tests a full Flow runtime: accounts, contracts, transactions, events, and controllable time. Every API here is a method on the blockchain object returned from `Test.newEmulatorBlockchain()`.
3. H2 `## Creating the Blockchain` — `let blockchain = Test.newEmulatorBlockchain()`. Where to create it (top-level `let` preferred; alternatively in `setup()`). Note it's reusable across tests.
4. H2 `## Accounts` — `blockchain.createAccount()` returns `Account { address: Address, publicKey: PublicKey }`. `blockchain.serviceAccount()` for the implicit account that owns protocol contracts. Example creating two accounts and using `.address`.
5. H2 `## Deploying Contracts` — `blockchain.deployContract(name: String, path: String, arguments: [AnyStruct])` returns an optional `Error?`. Example:
   ```cadence
   let err = blockchain.deployContract(
       name: "Counter",
       path: "../contracts/Counter.cdc",
       arguments: []
   )
   Test.expect(err, Test.beNil())
   ```
6. H2 `## Import Address Configuration` — `blockchain.useConfiguration(Test.Configuration(addresses: {...}))`. Covers when you need to override the default testing addresses for imports.
7. H2 `## Executing Scripts` — `blockchain.executeScript(code: String, arguments: [AnyStruct])` returns `ScriptResult { status, returnValue?, error? }`. Show reading `returnValue` safely with `as!` cast after a `Test.beSucceeded()` check.
8. H2 `## Executing Transactions` — Construct a `Transaction` struct:
   ```cadence
   let tx = Test.Transaction(
       code: Test.readFile("../transactions/increment.cdc"),
       authorizers: [admin.address],
       signers: [admin],
       arguments: []
   )
   let result = blockchain.executeTransaction(tx)
   Test.expect(result, Test.beSucceeded())
   ```
9. H2 `## Queued Execution` — `addTransaction` + `executeNextTransaction` + `commitBlock`. When to use instead of `executeTransaction`: ordering tests, multi-tx blocks.
10. H2 `## State Reset (Snapshot Isolation)` — `blockchain.reset(height: UInt64)`. Pattern for snapshot-per-test: capture a height after setup, reset to it in `beforeEach`.
11. H2 `## Time Manipulation` — `blockchain.moveTime(delta: Fix64)`. Seconds as `Fix64`. Use cases: vesting schedules, expiration logic, rate limits. Example: `blockchain.moveTime(by: 86400.0)` for one day.
12. H2 `## Mocking via Contract Substitution` — explain that Cadence has no traditional mocking; instead you deploy a simplified test-only contract under the same import name. Example: replace a price oracle with a constant-price contract.
13. H2 `## Common Pitfalls`:
    - Forgetting to assert `Test.beNil()` on the return of `deployContract` — silent deploy failures.
    - Reusing a blockchain across tests without reset leads to state bleed.
    - `moveTime` doesn't advance block height — use `commitBlock` too if your contract reads block.height.

**Length target:** 270–300 lines. If approaching 300, move the mocking section to its own H3 with minimal prose.

- [ ] **Step 1: Write the file** following the outline.

- [ ] **Step 2: Verify required APIs are cited**

Run:
```bash
grep -n -E "newEmulatorBlockchain|createAccount|serviceAccount|deployContract|useConfiguration|executeScript|executeTransaction|addTransaction|executeNextTransaction|commitBlock|\.reset\(|moveTime|Test\.Transaction" plugins/flow-dev/skills/cadence-testing/references/blockchain-emulation.md
```
Expected: every keyword appears at least once.

- [ ] **Step 3: Verify length**

Run: `wc -l plugins/flow-dev/skills/cadence-testing/references/blockchain-emulation.md`
Expected: 200–300.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/blockchain-emulation.md
git commit -m "Add cadence-testing blockchain-emulation reference"
```

---

## Task 5: Write `references/events-and-logs.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/events-and-logs.md`

**Required content outline:**

1. H1: `# Events and Logs`
2. Intro — events are the contract's public log of state changes; tests should assert on them when a transaction is supposed to emit something. Logs (`log(...)` calls) are for debugging and available in tests too.
3. H2 `## Reading All Events` — `blockchain.events()` returns `[AnyStruct]`. Each entry is the event struct. Note events accumulate across the entire blockchain history unless you `reset`.
4. H2 `## Filtering by Type` — `blockchain.eventsOfType(type: Type)`. Construct the type with `Type<Counter.Incremented>()` when the event is declared in an imported contract.
5. H2 `## Event Type Strings` — fully qualified format: `A.<8-byte-hex-address>.<Contract>.<EventName>`. For testing addresses (`0x07` etc), the hex is padded: `A.0000000000000007.Counter.Incremented`. Worth knowing when reading failure messages.
6. H2 `## Asserting Single Event` — pattern:
   ```cadence
   let events = blockchain.eventsOfType(Type<Counter.Incremented>())
   Test.expect(events, Test.haveElementCount(1))
   let evt = events[0] as! Counter.Incremented
   Test.assertEqual(1 as Int, evt.newValue)
   ```
7. H2 `## Asserting Ordered Sequences` — take two event types, collect both, compare lengths or field sequences. Show multiplex example.
8. H2 `## Reading Logs` — `blockchain.logs()` returns `[String]`. Logs from inside transactions and scripts appear here. Use for debugging, not as primary test assertion.
9. H2 `## Pitfalls`:
    - Events emitted during `setup()` leak into `events()` in your test — use `eventsOfType` to filter or count post-setup.
    - `reset(height)` rewinds events too — if you reset after deploy, your deploy events will be gone (usually fine).
    - Type string casing — contract names are case-sensitive, event names too.
    - Comparing addresses with `0x` prefix — `event.address` is an `Address` value; use `.toString()` if you need a string comparison.

**Length target:** 200–240 lines.

- [ ] **Step 1: Write the file** following the outline.

- [ ] **Step 2: Verify required APIs are cited**

Run:
```bash
grep -n -E "\.events\(\)|eventsOfType|\.logs\(\)|Type<|A\.[0-9a-f]+\." plugins/flow-dev/skills/cadence-testing/references/events-and-logs.md
```
Expected: every keyword appears at least once.

- [ ] **Step 3: Verify length**

Run: `wc -l plugins/flow-dev/skills/cadence-testing/references/events-and-logs.md`
Expected: 200–300.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/events-and-logs.md
git commit -m "Add cadence-testing events-and-logs reference"
```

---

## Task 6: Write `references/coverage-and-ci.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/coverage-and-ci.md`

**Required content outline:**

1. H1: `# Coverage and CI`
2. Intro — `flow test` runs every `*_test.cdc`, supports targeted runs, coverage, determinism, and network forking. This reference lists flags and shows a minimal CI workflow.
3. H2 `## Running Tests` — basic forms:
   ```bash
   flow test                                     # all test files
   flow test cadence/tests/Counter_test.cdc      # one file
   flow test cadence/tests/                      # a directory
   ```
4. H2 `## Flag Reference` — full table with `--cover`, `--coverprofile`, `--covercode`, `--name`, `--random`, `--seed`, `--fork`, `--fork-host`, `--fork-height`. Describe each in one row.
5. H2 `## Coverage` — `flow test --cover` prints a "Coverage: X% of statements" line. `--coverprofile=coverage.lcov` or `coverage.json`. `--covercode=contracts` restricts measurement to contract code only (excluding transactions/scripts).
6. H2 `## Deterministic Ordering` — `--random` shuffles test order, `--seed <uint64>` reproduces a shuffle. Useful for surfacing order-dependence bugs.
7. H2 `## Fork Mode` — the `#test_fork` pragma:
   ```cadence
   #test_fork(network: "mainnet", height: nil)
   ```
   or via CLI flags (`--fork mainnet --fork-height 100000000`). When to fork: integration-style tests against live contract state.
8. H2 `## Example Output` — paste (or describe) a realistic `flow test` output showing pass/fail lines and the coverage summary.
9. H2 `## GitHub Actions Workflow` — minimal workflow file:
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
10. H2 `## Tips` — local dev loop (`flow test --name <pattern>` while iterating), keeping coverage in PR comments via a coverage bot, flagging regressions by storing `coverage.json` as an artifact.

**Length target:** 200–240 lines.

- [ ] **Step 1: Write the file** following the outline.

- [ ] **Step 2: Verify required flags are cited**

Run:
```bash
grep -n -E "\-\-cover\b|\-\-coverprofile|\-\-covercode|\-\-name\b|\-\-random\b|\-\-seed\b|\-\-fork\b|\-\-fork-host|\-\-fork-height|#test_fork" plugins/flow-dev/skills/cadence-testing/references/coverage-and-ci.md
```
Expected: every flag appears at least once.

- [ ] **Step 3: Verify length**

Run: `wc -l plugins/flow-dev/skills/cadence-testing/references/coverage-and-ci.md`
Expected: 200–300.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/coverage-and-ci.md
git commit -m "Add cadence-testing coverage-and-ci reference"
```

---

## Task 7: Write `references/patterns.md`

**Files:**
- Create: `plugins/flow-dev/skills/cadence-testing/references/patterns.md`

**Required content outline:**

1. H1: `# Testing Patterns`
2. Intro — patterns that make Cadence tests faster to write, easier to read, and less flaky.
3. H2 `## What To Test` — bullet list:
   - Public contract functions and their invariants.
   - Access-control boundaries (authorized vs unauthorized signer).
   - Pre/post-condition violations.
   - Resource ownership transitions (deposit/withdraw).
   - Event emissions (treat events as public API).
   - Failure paths — every happy-path test deserves a sibling failure test.
4. H2 `## What To Skip` — bullet list:
   - Standard-interface plumbing already covered by core contracts (e.g., `NonFungibleToken.Collection.getIDs()`).
   - Framework internals (don't test `Test.assertEqual` itself).
   - Getters that only return a field with no logic.
5. H2 `## Arrange / Act / Assert` — canonical 3-section test body structure. Example:
   ```cadence
   access(all) fun testMintIncreasesSupply() {
       // Arrange
       let preSupply = getSupply()
       // Act
       mint(amount: 10.0)
       // Assert
       Test.assertEqual(preSupply + 10.0, getSupply())
   }
   ```
6. H2 `## Test Isolation` — two patterns:
   - Fresh blockchain per test (create in `beforeEach`) — most isolated, slowest.
   - Shared blockchain + `reset(height)` (snapshot once in `setup`, reset in `beforeEach`) — faster, requires discipline about what's captured in the snapshot.
   Pick one and stick with it in a file.
7. H2 `## Testing Resources Safely` — tests must not leak resources. Every `<-` in a test needs a destination or `destroy`. Show a common mistake (withdrawing and dropping the returned resource) and the fix.
8. H2 `## Testing Access Control` — pattern with `expectFailure`:
   ```cadence
   access(all) fun testNonOwnerCannotPause() {
       let other = blockchain.createAccount()
       let tx = Test.Transaction(
           code: Test.readFile("../transactions/pause.cdc"),
           authorizers: [other.address],
           signers: [other],
           arguments: []
       )
       let result = blockchain.executeTransaction(tx)
       Test.expect(result, Test.beFailed())
       Test.assert(
           result.error!.message.contains("admin entitlement required"),
           message: "unexpected error: ".concat(result.error!.message)
       )
   }
   ```
9. H2 `## Testing Pre/Post Conditions` — trigger a violation by feeding disallowed input, then match on the condition's error substring.
10. H2 `## Treating Events as Public API` — events appear in test assertions because consumers (indexers, UIs) depend on them. Changing or dropping an event is a breaking change; a test locks the contract.
11. H2 `## Flakiness Prevention` — bullet list:
    - Don't read wall-clock time (`getCurrentBlock().timestamp`); use `moveTime` to control it.
    - Don't depend on implicit block height ordering; use `reset` or `commitBlock` explicitly.
    - Pin event counts per type to avoid cross-test bleed.
    - Use `--seed <fixed>` in CI to make random ordering deterministic.
12. H2 `## Anti-Patterns`:
    - Over-mocking (deploying fakes for every dependency) — prefer real contracts when cheap.
    - Assertion-free tests (calls a function, never asserts).
    - Tests that only pass under a specific run order.
    - Very long test functions — split into multiple `testXxx`.
    - Testing Cadence itself instead of the contract (e.g., asserting that `1 == 1`).

**Length target:** 270–300 lines.

- [ ] **Step 1: Write the file** following the outline.

- [ ] **Step 2: Verify coverage**

Run:
```bash
grep -n -E "Arrange|Act|Assert|beforeEach|\.reset\(|moveTime|expectFailure|access control|pre/post" plugins/flow-dev/skills/cadence-testing/references/patterns.md
```
Expected: every keyword appears at least once.

- [ ] **Step 3: Verify length**

Run: `wc -l plugins/flow-dev/skills/cadence-testing/references/patterns.md`
Expected: 200–300.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-testing/references/patterns.md
git commit -m "Add cadence-testing patterns reference"
```

---

## Task 8: Add companion link in `cadence-lang/SKILL.md`

**Files:**
- Modify: `plugins/flow-dev/skills/cadence-lang/SKILL.md` (Companion Skills section)

- [ ] **Step 1: Locate the insertion point**

Run:
```bash
grep -n "Companion Skills" plugins/flow-dev/skills/cadence-lang/SKILL.md
```
Expected: one line number.

- [ ] **Step 2: Add the cadence-testing bullet**

Insert this line as the **first bullet** under the `## Companion Skills` heading (before the existing `cadence-tokens` line):

```markdown
- **`cadence-testing`** — Use alongside when writing tests for Cadence code. Tests are Cadence too and must follow every rule in this skill.
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "cadence-testing" plugins/flow-dev/skills/cadence-lang/SKILL.md
```
Expected: exactly one match, under the Companion Skills section.

- [ ] **Step 4: Commit**

```bash
git add plugins/flow-dev/skills/cadence-lang/SKILL.md
git commit -m "Link cadence-testing from cadence-lang"
```

---

## Task 9: Add companion link in `cadence-audit/SKILL.md`

**Files:**
- Modify: `plugins/flow-dev/skills/cadence-audit/SKILL.md` (Companion Skills section)

The file has a `## Companion Skills` section at the bottom — confirm with:
```bash
grep -n "Companion Skills" plugins/flow-dev/skills/cadence-audit/SKILL.md
```

- [ ] **Step 1: Add the cadence-testing bullet**

Append as the **last bullet** under `## Companion Skills`:

```markdown
- **`cadence-testing`** — Use to follow up on audit findings like "missing test coverage" or "edge case not tested" with concrete test-writing guidance.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "cadence-testing" plugins/flow-dev/skills/cadence-audit/SKILL.md
```
Expected: exactly one match.

- [ ] **Step 3: Commit**

```bash
git add plugins/flow-dev/skills/cadence-audit/SKILL.md
git commit -m "Link cadence-testing from cadence-audit"
```

---

## Task 10: Add companion link in `cadence-scaffold/SKILL.md`

**Files:**
- Modify: `plugins/flow-dev/skills/cadence-scaffold/SKILL.md` (Companion Skills section)

- [ ] **Step 1: Add the cadence-testing bullet**

Append as the **last bullet** under `## Companion Skills`:

```markdown
- **`cadence-testing`** — Use to write tests for any scaffolded contract or transaction before deployment.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "cadence-testing" plugins/flow-dev/skills/cadence-scaffold/SKILL.md
```
Expected: exactly one match.

- [ ] **Step 3: Commit**

```bash
git add plugins/flow-dev/skills/cadence-scaffold/SKILL.md
git commit -m "Link cadence-testing from cadence-scaffold"
```

---

## Task 11: Update `README.md`

**Files:**
- Modify: `README.md`

Three edits: (a) plugin summary table row, (b) flow-dev skill table, (c) Repository Structure tree.

- [ ] **Step 1: Update plugin summary row**

Find the line listing all `flow-dev` skills in the top summary table (line 33 area — the one with `` `cadence-lang`, `cadence-tokens`... ``). Append `` , `cadence-testing` `` to the end of the list, before the closing `|`.

Verify:
```bash
grep -n "cadence-testing" README.md
```
Expected: one match so far.

- [ ] **Step 2: Add row to flow-dev skill table**

Under the `### flow-dev` heading's skill table (starts around line 39), insert this row **immediately after the `cadence-scaffold` row and before `flow-react-sdk`**:

```markdown
| `cadence-testing` | Cadence unit testing: Test contract API, assertions and matchers, blockchain emulation, events, coverage, `flow test`, testing patterns |
```

- [ ] **Step 3: Add to Repository Structure tree**

In the `## Repository Structure` section, insert these lines **immediately after the `cadence-scaffold/` block and before `flow-react-sdk/`**:

```markdown
            cadence-testing/
                SKILL.md    # Testing framework guide
                references/ # 6 reference files
```

(Match the indentation of the surrounding entries.)

- [ ] **Step 4: Verify all three edits landed**

Run:
```bash
grep -n "cadence-testing" README.md
```
Expected: exactly three matches — summary row, skill table row, tree entry.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "List cadence-testing in README"
```

---

## Task 12: Update `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md`

Two edits: (a) Skill Routing Guide table, (b) Repository Structure skills block.

- [ ] **Step 1: Add routing table rows**

In the `## Skill Routing Guide` section's table, append these two rows at the end (after the `flow-tokenomics` row):

```markdown
| Write unit tests for Cadence contracts | `cadence-testing` | `cadence-lang` |
| Debug failing Cadence tests / add coverage | `cadence-testing` | `cadence-lang`, `cadence-audit` |
```

- [ ] **Step 2: Update Repository Structure listing**

In the repository structure block (under `## Repository Structure`), insert this line **immediately after the `cadence-scaffold/` entry and before `flow-project-setup/`**:

```markdown
            cadence-testing/    # Testing framework guide (6 references)
```

- [ ] **Step 3: Verify both edits landed**

Run:
```bash
grep -n "cadence-testing" CLAUDE.md
```
Expected: exactly three matches — two routing rows, one tree entry.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "Add cadence-testing to routing guide and structure"
```

---

## Task 13: Final plugin validation and cross-check

- [ ] **Step 1: Validate the plugin**

Run:
```bash
claude plugin validate .claude-plugin
```
Expected: success message, no errors. If validation reports missing frontmatter or broken references, fix the offending file and re-run.

- [ ] **Step 2: Confirm all six references exist**

Run:
```bash
ls plugins/flow-dev/skills/cadence-testing/references
```
Expected:
```
assertions-and-matchers.md
blockchain-emulation.md
coverage-and-ci.md
events-and-logs.md
patterns.md
setup-and-basics.md
```

- [ ] **Step 3: Confirm every reference is within length bounds**

Run:
```bash
wc -l plugins/flow-dev/skills/cadence-testing/references/*.md
```
Expected: every line count between 200 and 300.

- [ ] **Step 4: Confirm SKILL.md points at every reference**

Run:
```bash
for f in plugins/flow-dev/skills/cadence-testing/references/*.md; do
  name=$(basename "$f")
  grep -q "$name" plugins/flow-dev/skills/cadence-testing/SKILL.md \
    && echo "ok: $name" \
    || echo "MISSING: $name"
done
```
Expected: six `ok:` lines, no `MISSING:`.

- [ ] **Step 5: Confirm companion-skill cross-links landed**

Run:
```bash
grep -l "cadence-testing" plugins/flow-dev/skills/*/SKILL.md
```
Expected: four paths — `cadence-testing/SKILL.md` (self), `cadence-lang/SKILL.md`, `cadence-audit/SKILL.md`, `cadence-scaffold/SKILL.md`.

- [ ] **Step 6: Confirm top-level catalog updates**

Run:
```bash
grep -c "cadence-testing" README.md CLAUDE.md
```
Expected: `README.md:3` and `CLAUDE.md:3`.

- [ ] **Step 7: Review git log**

Run:
```bash
git log --oneline main..HEAD
```
Expected: around 12 commits, all prefixed with a clear action verb (Add / Link / List / Update).

- [ ] **Step 8: Final commit only if fixes were needed**

If any of the checks in steps 1–6 failed and you needed to patch a file, commit the fix with a descriptive message. Otherwise no commit here.

---

## Self-Review Checklist (run after plan is complete)

1. **Spec coverage:**
   - Every H2 in the spec's "Reference File Contents" → mapped to Task 2–7. ✓
   - Spec's companion cross-link list → Tasks 8–10. ✓
   - README + CLAUDE.md → Tasks 11–12. ✓
   - Frontmatter in spec → Task 1 Step 2. ✓
   - Acceptance criteria #3 (200–300 lines, Verified API Surface only) → enforced in every reference task's verify step and Task 13 Step 3.
2. **Placeholders:** None. Every step has exact commands or exact content.
3. **Type consistency:** `Test.Transaction`, `ScriptResult`, `TransactionResult`, `Account`, `Error` used identically across tasks. `Test.expect(result, Test.beSucceeded())` form used consistently.

Plan complete.
