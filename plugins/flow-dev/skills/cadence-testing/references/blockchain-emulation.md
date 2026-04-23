# Blockchain Emulation

Emulation is what makes the Cadence testing framework more than a unit-test harness: every test file runs against a full in-process Flow runtime with real accounts, real contracts, real transactions, real events, and a clock you can advance at will. The `Test` contract exposes this runtime directly; everything else in this reference is a method called on `Test`.

The runtime is deliberately deterministic. Block production is driven by explicit calls, time only moves when you tell it to, and nothing schedules itself in the background. That determinism is what makes the framework useful for regression tests — a passing run today will still pass a year from now unless the contract changes.

The emulator lives entirely in the test process. It has no network, no mempool, and no staking; it does not talk to testnet or mainnet, does not persist state between `flow test` invocations, and never exposes an RPC endpoint. Think of it as a pure function from "sequence of `Test.*` calls" to "final chain state" — which is why the same test file always produces the same result on the same code.

## The Test API

```cadence
import Test
```

Every method in this reference is called directly on the `Test` contract — there is no `blockchain` binding to create or pass around. One implicit emulator instance exists per test file; it persists across every `setup`, `beforeEach`, and `testXxx` in that file until the file ends, or until `Test.reset(to:)` rewinds it to an earlier height.

A single emulator instance is reusable across every test in the file. Reset state between tests with `Test.reset(to:)` rather than trying to spin up a clean instance per test — redeploying the same fixture on every test adds seconds to every run.

## Accounts

```cadence
access(all) let admin = Test.createAccount()
access(all) let user = Test.createAccount()
```

`Test.createAccount()` returns a `TestAccount` value with two fields: `address: Address` and `publicKey: PublicKey`. The address is allocated deterministically from the blockchain's service account, and each call hands out the next address in sequence. Bind accounts at the file level when they participate in every test, or inside a test when they are only relevant to that case.

`Test.serviceAccount()` returns the implicit account that owns the protocol contracts and holds the testing framework's privileged keys. Transactions signed by the service account can deploy core contracts or manipulate accounts that user accounts cannot; most tests only need it when setting up fixtures that rely on system-level authority.

Accounts are just keys plus an address — storage and capabilities live on them only after a transaction writes to them. A freshly created account has no fungible token vault, no NFT collection, and no resources at all until your test (or the contract's `init`) puts something there.

A common pattern is to give every persistent role its own file-level account binding (`admin`, `minter`, `user`, `attacker`) and keep one-off accounts as locals inside the test that needs them. The names then read as documentation in the test body — `Test.Transaction(..., signers: [attacker], ...)` is self-explanatory in a way that `signers: [account3]` is not.

The address that `createAccount` returns is determined by the order of allocation across the lifetime of the blockchain, not by the test that triggered the allocation. Two test files that each call `createAccount` first see the same address for their respective `admin` accounts, but a single file that creates two accounts in `setup()` sees those two addresses in the order they were created. Do not hard-code those addresses in tests — read them from the `TestAccount` value's `address` field and the test stays correct as the fixture evolves.

### Looking Up an Existing Account

```cadence
let service = Test.serviceAccount()
let sameAccount = Test.getAccount(address: service.address)
```

`Test.getAccount(address: Address)` returns the `TestAccount` for a previously-created address. It is useful inside helper functions that only have an `Address` to work with — a transaction result, an event payload, or the service account's address pulled from a configuration — and need to re-acquire the full `TestAccount` value to pass into a subsequent `Test.Transaction`. The account must already exist; `getAccount` does not create one.

## Deploying Contracts

```cadence
let err = Test.deployContract(
    name: "Counter",
    path: "../contracts/Counter.cdc",
    arguments: []
)
Test.expect(err, Test.beNil())
```

`Test.deployContract(name:path:arguments:)` returns an optional `Error?`. A `nil` return means the deployment succeeded; a non-`nil` value carries the compile or runtime error. Always assert on the result — a silent deployment failure surfaces later as a confusing "contract not found" error from `executeScript` or `executeTransaction`, and debugging that is far more painful than a clear `Test.beNil` failure at setup.

The `path` is relative to the test file, not to the project root. The `arguments` array is passed to the contract's `init` in declaration order, typed as `[AnyStruct]`. The deployed contract is registered under the `testing` alias declared in `flow.json`, so it becomes importable by name (`import "Counter"`) from the test file and from any scripts or transactions the test runs.

When a contract under test imports another contract, the dependency must be deployed first. The framework deploys standard library contracts (`FungibleToken`, `NonFungibleToken`, `MetadataViews`, `ViewResolver`) automatically when they are imported, but anything else — including third-party contracts your project depends on — needs an explicit `deployContract` call earlier in `setup()`. Order the deployments by their dependency graph: leaves first, roots last.

Cyclic imports are not legal at deployment time — Cadence resolves a contract's imports before its `init` runs, so two contracts that import each other cannot both be deployed in any order. If you find yourself wanting that, the right fix is almost always to extract the shared types or interfaces into a third contract that both import.

## Executing Scripts

```cadence
let script = Test.readFile("../scripts/get_count.cdc")
let result = Test.executeScript(script, [])
Test.expect(result, Test.beSucceeded())
let count = result.returnValue! as! Int
Test.assertEqual(0, count)
```

`Test.executeScript(code:arguments:)` runs a Cadence script against the current blockchain state and returns a `ScriptResult` with `status`, an optional `returnValue`, and an optional `error`. Assert on success first with `Test.expect(result, Test.beSucceeded())` — that matcher renders the underlying error if the script reverted, which makes failures diagnosable without re-running.

The `code` argument is the script's source as a `String`. Most tests load it from disk with `Test.readFile`, which keeps the script under version control alongside the rest of the project. For one-off assertions, an inline string literal is fine, but anything reused across tests should live in its own `.cdc` file so the same script can be exercised from `flow scripts execute` against the emulator or a live network without divergence.

Unwrap `returnValue` with a forced cast (`as!`) only after asserting success. The cast itself panics on a type mismatch, so the preceding `beSucceeded` assertion is what ensures the cast only runs on a real value. Casts match the script's declared return type — use `as! Int`, `as! [Address]`, `as! {String: UFix64}`, and so on.

Scripts are read-only: they observe the blockchain but cannot modify it. That makes them ideal for assertions that inspect contract state, balances, or the contents of a collection. Anything that needs to mutate state — minting, transferring, calling an admin method — must go through `executeTransaction`. A common test shape is a transaction that performs the action followed by a script that reads back the new state and asserts on it.

## Executing Transactions

```cadence
let tx = Test.Transaction(
    code: Test.readFile("../transactions/increment.cdc"),
    authorizers: [admin.address],
    signers: [admin],
    arguments: []
)
let result = Test.executeTransaction(tx)
Test.expect(result, Test.beSucceeded())
```

`Test.Transaction` bundles the source, the authorizer addresses, the signer accounts, and the arguments. The `authorizers` list matches the `prepare` block of the transaction; the `signers` list is the set of accounts whose keys authorise the transaction (often the same set). For a transaction with a single `prepare(acct: auth(Storage) &Account)`, pass `authorizers: [admin.address]` and `signers: [admin]`.

A transaction whose `prepare` block declares two parameters needs two entries in `authorizers` (in order) and the matching `TestAccount` values in `signers`. Multi-authorizer transactions are uncommon outside of escrow and atomic-swap patterns, but when they appear the symmetry between the two lists is what the framework checks — a length mismatch fails the transaction with an authorisation error before any contract code runs.

`Test.executeTransaction` submits the transaction, commits a block, and returns a `TransactionResult` that behaves the same as a `ScriptResult` for assertion purposes: `Test.beSucceeded`, `Test.beFailed`, and `result.error!.message` all work identically. Events emitted by the transaction become visible via `Test.events` and `Test.eventsOfType` after the call returns, and any `log` statements the transaction or its callees executed surface in `Test.logs`.

Argument values in the `arguments` array must match the transaction's declared parameter types exactly. Cadence does not coerce between numeric widths, so a transaction expecting a `UInt64` rejects a plain `42` (which the parser infers as `Int`). Cast at the call site — `42 as UInt64` — to keep type errors at the test boundary instead of hidden inside the transaction prelude.

## Batch Execution

```cadence
let results = Test.executeTransactions([tx1, tx2, tx3])
Test.expect(results[0], Test.beSucceeded())
Test.expect(results[1], Test.beSucceeded())
Test.expect(results[2], Test.beSucceeded())
```

`Test.executeTransactions(transactions: [Transaction])` runs every transaction in order, commits a single block containing all of them, and returns a `[TransactionResult]` aligned by index with the input. Use it when the test cares that a group of transactions lands in the same block — for example, asserting that a later transaction in the batch sees state written by an earlier one — without managing the queue manually.

## Queued Execution

```cadence
Test.addTransaction(tx1)
Test.addTransaction(tx2)
let r1 = Test.executeNextTransaction()
let r2 = Test.executeNextTransaction()
Test.commitBlock()
```

`addTransaction` enqueues a transaction without running it. `executeNextTransaction` pops the head of the queue, executes it, and returns its `TransactionResult`. `commitBlock` finalises the current block, producing a block boundary that the transactions ran inside.

Reach for the queued API when a test needs to observe ordering or block-level invariants — for example, asserting that two transactions in the same block see each other's state changes, or that a transaction which depends on a prior one runs only after it. Most tests do not care about ordering and should use `executeTransaction` directly.

Note that `executeTransaction` is shorthand for `addTransaction` followed by `executeNextTransaction` followed by `commitBlock`, with each transaction in its own block. The queued API's value is precisely the freedom to deviate from that one-transaction-per-block default — call `commitBlock` only at the boundary your test cares about, and the intervening transactions all share a block.

Note also that `executeNextTransaction` returns the result for the popped transaction, not for the entire queue. To process every queued transaction in one go, call it in a loop until the queue is empty (or call `executeTransaction` shorthand instead, if per-transaction inspection is not needed).

## State Reset (Snapshot Isolation)

```cadence
access(all) var setupHeight: UInt64 = 0

access(all) fun setup() {
    let err = Test.deployContract(
        name: "Counter",
        path: "../contracts/Counter.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    setupHeight = getCurrentBlock().height
}

access(all) fun beforeEach() {
    Test.reset(to: setupHeight)
}
```

`Test.reset(to:)` rewinds the blockchain to the given block height, discarding every transaction, event, and storage change that happened after it. Capturing the height at the end of `setup()` and resetting to it in `beforeEach()` gives each test a clean fixture without redeploying contracts — a meaningful speedup for test files with many cases that share one deployment.

Without a reset, state from one test leaks into the next. A test that mutates a counter to 5 and runs before a test that asserts the counter starts at 0 silently makes both tests meaningless.

The snapshot-per-test pattern composes well with `Test.expectFailure` and revert tests: even a test that intentionally fails halfway through cannot leave state behind to confuse the next test, because the next `beforeEach` rolls everything back. That isolation is what lets a single test file cover many independent scenarios without a combinatorial explosion of fixtures.

## Time Manipulation

```cadence
// Advance one day.
Test.moveTime(by: 86400.0)
// Optionally commit a block so getCurrentBlock().height advances too.
Test.commitBlock()
```

`Test.moveTime(by:)` advances the blockchain's clock by the given number of seconds, expressed as `Fix64`. The parameter label is `by`, and the argument is in seconds — not milliseconds, not blocks. Use it to test vesting schedules, expiration deadlines, rate limits, and anything else that reads `getCurrentBlock().timestamp`.

`moveTime` and `commitBlock` are complementary, not interchangeable. `commitBlock` advances the block height but not the wall clock — it's the right tool when a contract cares about block numbers. `moveTime` advances the wall clock but not the block height — it's the right tool when a contract cares about timestamps. If the contract reads both `getCurrentBlock().height` and `getCurrentBlock().timestamp`, move time and then commit a block, in that order.

`Fix64` accepts negative values, so `Test.moveTime(by: -3600.0)` rewinds the clock by an hour. That can be useful for testing a contract's behaviour around boundary conditions, but it can also surprise contracts that assume time only moves forward — use it with care, and only for the specific assertion that needs it.

## Mocking via Contract Substitution

Cadence has no traditional mocking framework — no monkey-patching, no interface stubbing, no method spies. The idiomatic substitute is to deploy a simplified test-only contract under the same import name as the production contract and let the framework's import resolution do the rest.

A price-oracle consumer, for example, can be tested against a stub oracle that returns a constant price:

```cadence
let err = Test.deployContract(
    name: "PriceOracle",
    path: "../tests/mocks/ConstantPriceOracle.cdc",
    arguments: [42.0 as UFix64]
)
Test.expect(err, Test.beNil())
```

Any transaction or script that imports `"PriceOracle"` now resolves to the constant-price stub. The production implementation never enters the test process, so the test can focus on the consumer's logic — "what does the caller do when the price is X?" — without standing up the real oracle's dependencies.

Keep mock contracts minimal: expose the exact API surface the consumer imports, and nothing more. A bloated mock is easy to get wrong and obscures which behaviour the test actually depends on.

A second pattern, complementary to substitution, is the configurable mock: a test-only contract that exposes setters allowing each test to dictate the value the mock will return. A configurable price oracle, for example, can offer a `setPrice(_ price: UFix64)` admin method, and each test sets the price to whatever the scenario demands before invoking the consumer. This keeps one mock contract per dependency rather than one per scenario, at the cost of a setup step inside every test that uses it.

Mocks live alongside tests, not alongside production code — a conventional location is `cadence/tests/mocks/`. Keep the directory out of the production deployment path so the mock can never reach mainnet by accident. The `flow.json` deployments block, which controls what `flow project deploy` ships, should not list mock contracts at all.

## Common Pitfalls

- **Forgetting to assert `Test.beNil()` on the `deployContract` return.** Silent deploy failures surface later as "contract not found" errors during `executeScript`, which are hard to trace back to the real cause. Every `deployContract` call deserves a matching `Test.expect(err, Test.beNil())` immediately after it.
- **Reusing the emulator across tests without `reset`.** State from one test bleeds into the next, turning a passing suite into an order-dependent mess. Capture a snapshot height at the end of `setup()` and call `Test.reset(to:)` in `beforeEach()` so every test starts from the same known fixture.
- **Assuming `moveTime` advances block height.** It does not. If the contract reads `getCurrentBlock().height`, call `commitBlock()` after `moveTime` to advance both clocks. Likewise, `commitBlock` on its own does not move the wall clock, so a contract reading `timestamp` will see the same value across many committed blocks unless `moveTime` is used explicitly.
- **Mixing file-level and per-test accounts carelessly.** A file-level `access(all) let admin = Test.createAccount()` is created once when the test file loads, before any `setup()` runs. That is usually fine, but any storage the admin has is wiped the first time `Test.reset(to:)` rolls the chain back to a height earlier than the account's creation — make sure accounts you want to persist are created before the height you later reset to.
- **Relative paths that point at the wrong directory.** `Test.readFile` and `Test.deployContract` resolve paths relative to the test file itself, not the `flow test` invocation directory. Running the same tests from `cadence/tests/` and from the project root produces identical results — but a path written with the project root in mind breaks as soon as a test file moves into a subfolder.
- **Forgetting that `executeTransaction` already commits a block.** A test that calls `executeTransaction` and then immediately calls `commitBlock` ends up with an extra empty block at the end, which usually does no harm but can throw off assertions that count blocks. Reach for the queued API only when the explicit block-boundary control is the point.
