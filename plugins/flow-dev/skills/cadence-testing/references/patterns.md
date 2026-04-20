# Testing Patterns

The other references in this skill cover mechanics — how the blockchain object works, which matchers exist, how events surface, how coverage and CI are wired up. This one is about the patterns that sit on top of those mechanics and make Cadence tests faster to write, easier to read, and less flaky. None of it is enforced by the tooling; these are conventions that pay off over a year of maintenance rather than over a single afternoon of writing tests.

A test suite is a long-lived artefact. The tests you write this week will be read, re-read, and modified by whoever touches the contract next — possibly you, possibly someone who joins the project a year from now. The patterns below bias toward readability and resilience over cleverness, because a test that reads cleanly survives refactors and a test that hides behind indirection does not. The more a test's structure matches the structure of the behaviour it exercises, the less mental translation its next reader has to do.

## What To Test

The point of a test is to lock in observable behaviour so a future change cannot silently break it. The observables worth locking in are the same for every Cadence contract:

- Public contract functions and their invariants — every entry point that a transaction, script, or other contract can reach, including the invariants the function is meant to uphold.
- Access-control boundaries — for every admin-gated entry point, a happy-path test with an authorised signer and a failure-path test with an unauthorised signer.
- Pre/post-condition violations — if a function declares a `pre` or `post` block, assert that illegal inputs trip it with the expected message substring.
- Resource ownership transitions — every `<-` move between accounts, collections, or vaults deserves a test that observes both sides of the move.
- Event emissions — treat events as part of the public API. Any off-chain consumer (indexer, UI, another contract's client) that depends on an event will break silently if the contract stops emitting it.
- Failure paths — every happy-path test deserves a sibling failure test. A suite that only exercises success paths proves the contract can succeed, not that it can reject bad input.

The list is deliberately short. Exhaustive combinatorial coverage of every possible input is not the target; the target is confidence that every externally observable promise the contract makes is backed by a regression test.

A contract with ten public functions and three admin-gated ones might end up with twenty-five tests — five or six happy paths per function, plus paired failure tests for the gates and the preconditions — and that is a healthy ratio. A thousand tests for the same contract is almost certainly full of duplication and low-value assertions that slow the suite down without catching anything.

Invariants are the highest-value assertions in the set. An invariant assertion checks a property that must hold across many different inputs (total supply equals the sum of balances, a vault's stored resource count equals its declared length, a collection's `getIDs()` returns the same set as the keys of its internal dictionary). A suite that names and checks its invariants after every mutating operation catches whole classes of bug that per-operation assertions miss.

## What To Skip

Writing tests for everything is a tax, not a safety net. Skip the checks where the value per line is near zero:

- Standard-interface plumbing covered by core contracts. `NonFungibleToken.Collection.getIDs()` is tested in the core repo; re-testing it against your concrete collection buys nothing and couples your suite to the core contract's internals.
- Framework internals. `Test.assertEqual` itself is not your code, and a regression in it would surface in every test at once rather than requiring a dedicated assertion.
- Getters that only return a field with no logic. A `access(all) view fun owner(): Address { return self.owner }` carries no branching to cover; a test for it asserts that Cadence's field-access compiles, which it will.

The heuristic: if a test would fail only when Cadence itself or the standard library regresses, that test belongs in Cadence's repository, not in yours. The same heuristic applied from the opposite direction: if a test's failure would only be caught when the contract author introduces a bug, it belongs in your suite, full stop.

A corollary worth naming explicitly: do not write tests that shadow the type system. Cadence's type checker already catches the case where a function expects `UFix64` and the caller passed `String`; a test that hand-constructs a type mismatch just to assert the compiler rejected it is exercising Cadence, not your contract. Trust the compiler for the checks the compiler performs, and spend test budget on the invariants the compiler cannot see.

## Arrange / Act / Assert

Every test body fits the same three-section skeleton: set up the inputs, perform the action under test, assert on the result. Separating the three sections with a blank line or a comment makes a failing test readable at a glance without reverse-engineering which line was the interesting one.

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

If a test needs a second Act/Assert pair, that is a signal to split it into two tests. A test body that performs two unrelated actions hides which one regressed when it fails, and the CLI output names only the parent test function — you lose the per-scenario granularity that makes the suite useful as a debugging tool.

The comment labels are optional but helpful for longer tests. Skip them in a three-line test where the structure is obvious; keep them in a twenty-line test where the sections would otherwise blur together.

When the Arrange section itself runs to more than a handful of lines, that is a hint to extract a helper function — the test reads better when the scenario-specific setup fits in a few lines and the shared mechanics live in a named helper. A helper named `mintFiveTokensTo(_ addr: Address)` makes the Arrange line in every test that uses it self-documenting; an inline sequence of ten transaction submissions does not.

The Assert section is the only place where a failure message should surface, which means it is also the only place where careful assertion choice matters. An assertion that fails with "expected true, got false" is a symptom without a diagnosis; an assertion built from `Test.expect` and a named matcher renders a message that points at the specific invariant the test was protecting.

## Test Isolation

Two isolation patterns exist, each with a clear tradeoff. Pick one per file and stick with it — mixing them inside a single file is a common source of order-dependent bugs.

**Fresh blockchain per test.** Create a new `Test.newEmulatorBlockchain()` in `beforeEach()` and redeploy every contract. Most isolated option available — no state leaks between tests because nothing carries over. Slowest, because the deployment cost is paid on every test. Right when the test file has only a handful of tests, or when the contracts are small and fast to deploy.

**Shared blockchain + `reset(height)`.** Create the blockchain at file scope, deploy contracts in `setup()`, capture the height at the end of `setup()`, and call `blockchain.reset(height: setupHeight)` in `beforeEach()`. The fixture is built once and then rewound between tests, which is typically an order of magnitude faster than redeploying. Requires discipline: anything declared `access(all) let` at file scope (accounts, capability bindings) must be created before the snapshot height, or the reset invalidates it.

Snapshot-per-test is the default for files with more than a handful of cases. Fresh-per-test is the default for tiny files or for tests that deliberately mutate the contract set itself.

Once you have picked a pattern, resist the temptation to reach for the other one in a single "just this one test" exception — the exception is how order-dependent bugs enter the file. If a particular test genuinely needs a different isolation model, promote it to its own file with its own lifecycle functions rather than forking the convention mid-file.

A useful sanity check: run the file with `flow test --random --seed <any-number>` occasionally. If the tests pass under a random order, the isolation is working; if they start failing, the suite has a state leak that deterministic ordering was masking.

## Testing Resources Safely

Cadence's resource system enforces conservation: every `<-` needs a destination or an explicit `destroy`. A test that loses track of a resource fails to type-check and never runs, but one that writes resources into unused scratch variables still compiles and silently leaks them across the test's scope.

A common mistake, usually when sketching the happy path before the assertions are added:

```cadence
// Wrong: the withdrawn vault is never consumed.
let vault <- admin.vault.withdraw(amount: 5.0)
```

The fix is either to deposit the resource into its destination (which is what the scenario actually tested) or to `destroy` it when the test only cared about the withdrawal side:

```cadence
let vault <- admin.vault.withdraw(amount: 5.0)
recipient.vault.deposit(from: <-vault)
```

Either form leaves nothing dangling. Prefer the real destination when the test is exercising a transfer; prefer `destroy` only when the specific assertion is about the source side and the sink is not interesting.

The same principle applies to resources that flow through a test's helper functions — a helper that takes a resource parameter must either consume it, return it, or destroy it, with no third option available to the compiler. A helper signature like `fun topUp(vault: @Vault, amount: UFix64): @Vault` is self-documenting about ownership; a helper that takes a resource and returns nothing is telling the caller "I destroyed this" and deserves a name that reflects that.

Resources that come out of `executeTransaction` do not return to the test closure — the transaction executes inside the blockchain, and any resources it moves stay inside the blockchain's state. A test file that appears to manipulate resources directly is usually calling contract functions through `import`, not running transactions; be careful to route the mutations the scenario actually models through the right layer (direct call vs. transaction) rather than mixing them.

A test that wants to assert on the state of a resource it just moved can usually read back the relevant state through a script rather than inspecting the resource itself. The script runs against the post-transaction blockchain, returns a scalar projection (balance, id list, owner address), and sidesteps the conservation issue entirely.

## Testing Access Control

The canonical shape for a negative access-control test is a transaction signed by the wrong account, an assertion that the result failed, and a substring check on the error message. Use `executeTransaction` and inspect the `TransactionResult` directly — blockchain reverts do not propagate as in-process panics, so `Test.expectFailure` would pass for the wrong reason.

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

Match on the shortest stable fragment of the error message. A long substring couples the test to an implementation detail of the contract's phrasing and generates churn the next time the error is reworded.

Pair the negative test with a positive one that runs the same transaction from the admin account and asserts it succeeds — the pair is what proves the gate is actually gating, rather than rejecting every caller regardless of authority. A gate that rejects every caller is usually caught at contract-author time, but a gate that accepts every caller is exactly the kind of regression that a thoughtful pair of tests catches.

For entitlements specifically, test both the authorised path (caller holds the entitlement, transaction succeeds) and the unauthorised path (caller lacks the entitlement, transaction reverts with an entitlement-related message). The entitlement system is the primary access-control mechanism in Cadence 1.0, and a contract whose tests exercise only one side of that boundary is leaving the security-critical path uncovered.

When a contract has multiple admin roles (minter, pauser, upgrader), spell out one test per role per gate. Bundling "any non-admin cannot call X" into a single test saves keystrokes but hides which specific rejection path is broken when the contract's access logic regresses.

Access control tests are also the place where a dedicated `attacker` account binding earns its name. A file-level `access(all) let attacker = blockchain.createAccount()` used as the signer of every negative test reads as documentation in the test body — the reader sees `signers: [attacker]` and knows immediately which role the test is exercising.

## Testing Pre/Post Conditions

The pre/post blocks declared on a function are the contract's guard rails; a test that never fires them leaves the rails untested. Trigger each one by constructing an input that is legal to the type system but illegal to the condition, run the call, assert failure, and match on a substring of the condition's message.

```cadence
access(all) fun testWithdrawRejectsZeroAmount() {
    let tx = Test.Transaction(
        code: Test.readFile("../transactions/withdraw.cdc"),
        authorizers: [user.address],
        signers: [user],
        arguments: [0.0 as UFix64]
    )
    let result = blockchain.executeTransaction(tx)
    Test.expect(result, Test.beFailed())
    Test.assert(
        result.error!.message.contains("amount must be positive"),
        message: "unexpected error: ".concat(result.error!.message)
    )
}
```

Keep one test per condition. A single test that bundles a dozen illegal inputs makes the failure legible only if the first input was the one that broke; every subsequent input is shadowed by the first failure and never actually exercised.

Post-conditions deserve the same treatment — a post-condition that checks an invariant on the function's output is a promise to the caller, and the only way to prove the promise holds is a test that exercises the edge case the post-condition is meant to catch. The practical difficulty with post-conditions is that the only way to trip one from a test is to corrupt the function's internal state mid-execution, which is rarely reachable from the outside. When a post-condition cannot be exercised in a test, document that limitation in a comment on the contract itself rather than leaving a gap in the suite silent.

## Treating Events as Public API

Events look like an internal detail — they do not return values, they do not block execution, and they do not affect state. But off-chain consumers (indexers, UIs, cross-contract clients) depend on them to reconstruct what happened on chain. Changing an event's name, removing a field, or dropping an `emit` silently breaks every such consumer.

A test that asserts an event was emitted with the expected fields turns that silent break into a loud one. The contract cannot change the event without updating the test, which forces the author to confront the break before it ships. Treat every event the contract emits as a public API contract, and assert on it exactly like you would assert on a return value.

Concretely, pair every state-changing assertion with an event assertion from the same transaction. The state assertion proves the change happened; the event assertion proves the change was announced. A contract that mutates state without announcing it, or announces a change that did not happen, passes a single-sided test but fails real consumers.

Use `eventsOfType(Type<Contract.EventName>())` for the filter — it keeps the assertion pinned to the specific event the test cares about and ignores the bootstrap noise from standard contracts. Assert on the element count before dereferencing, and cast the entries to the concrete event type before reading fields. Both steps are mechanical but skipping either turns a "no event emitted" bug into a confusing runtime panic instead of a readable assertion failure.

The corollary is that adding a new event to a contract rarely requires a new test — existing tests that used `haveElementCount` on a different event type will keep passing, because the filter ignores the new type. Removing an event or changing its fields, on the other hand, breaks every test that asserted on it. That asymmetry is exactly what you want from a regression test: cheap to add observations, expensive to drop them.

Field assertions on events should be narrow. Assert on the fields the test specifically cares about; do not mirror every field of the event just because you can. A test that checks only the `newValue` field survives a future change that adds a `timestamp` or `caller` field to the event, where an exhaustive test would need to be updated alongside the contract change for no real gain.

## Flakiness Prevention

Flaky tests are tests that pass sometimes and fail sometimes for reasons unrelated to the code under test. A few habits keep the suite deterministic:

- Do not read wall-clock time from tests. `getCurrentBlock().timestamp` inside a test closure returns real time and drifts between runs; use `blockchain.moveTime(by:)` to set the clock to a known value before the assertion runs.
- Do not depend on implicit block height ordering. Two transactions queued through `addTransaction` land in the same block until an explicit `commitBlock` closes the block; rely on `reset` or `commitBlock` to pin the block boundary your assertion cares about.
- Pin event counts per type, not totals. `eventsOfType(...)` filters out the bootstrap events that the framework emits during setup, and those counts can change when the Flow CLI ships a new version. Raw `events()` counts will drift; typed counts will not.
- Use `--seed <fixed>` in CI to make random ordering deterministic. Pair it with `--random` locally to catch order-dependent bugs before they reach CI.

The common thread across these habits is the same: anything implicit (wall time, block boundaries, bootstrap events, iteration order) is a source of non-determinism, and the fix is to make it explicit. A test that reads a value it did not set, or that makes an assertion against a number it did not compute, is a test whose outcome depends on something outside the test body. Bring that something inside the test, and the flakiness goes with it.

Flakiness also hides behind shared file-level state. An `access(all) var` binding that one test mutates and another test reads creates a hidden dependency that neither test declares. Prefer `access(all) let` for fixture values that should never change, and keep per-test state inside the test function.

When a test does occasionally fail, resist the temptation to re-run it until it passes and consider the diagnosis done. A flaky test is a bug report about the suite's assumptions; silencing it with a retry loop hides the bug until it shows up in production. Fix the source of non-determinism and the "flake" goes away permanently.

## Anti-Patterns

A handful of patterns look reasonable up close but corrode the suite over time:

- **Over-mocking.** Deploying a fake for every dependency makes the test setup balloon and hides integration bugs that only appear when real contracts compose. Prefer real contracts when they are cheap to deploy; reach for a mock only when the real dependency has heavy setup (oracles, external price feeds) or when the test specifically needs to control the dependency's return value.
- **Assertion-free tests.** A test that runs a transaction and checks only that it did not panic is barely a test — it catches type errors the compiler already caught. Every test body should contain at least one assertion on the observable it actually cares about.
- **Tests that only pass in a specific run order.** If rearranging two tests makes one of them fail, the file has leaked state between them. Fix the leak with `reset` or a fresh blockchain; do not paper over it by documenting a required order.
- **Very long test functions.** A test that performs five distinct scenarios is five tests masquerading as one. Split them — each scenario's failure then names itself in the CLI output instead of hiding behind a generic parent name.
- **Testing Cadence itself.** Assertions like `Test.assertEqual(1, 1)` or `Test.assert(true)` test nothing about the contract under review. If the body of a test does not mention a symbol from the contract or a result from the blockchain, it does not belong in the suite.

The common thread under all of these is a misalignment between what the test says it covers and what it actually covers. A test named `testWithdraw` that never calls `withdraw`, a test named `testAccessControl` that never runs a transaction from an unauthorised signer, a test named `testEmitsEvent` that does not filter `eventsOfType` — each one gives false confidence while covering nothing.

Read every test one more time after writing it and ask whether the failure message would tell the next engineer something useful about the contract. If the answer is no, the test is not yet doing its job. The goal is not to have a green CI badge; the goal is to catch the next bug before it ships, and a test that cannot fail for the reason its name suggests will not catch anything.

A practical loop: write the test, watch it pass, then temporarily break the contract in the way the test claims to guard against. If the test turns red, the assertion is meaningful. If the test stays green, the assertion is decorative — rewrite it until a real regression trips it, then undo the contract change.

This is the Cadence equivalent of mutation testing without the tooling overhead. It takes a few extra minutes per test and pays back every time the contract is refactored, because the tests that survived the check continue to catch the bugs they were written to catch.
