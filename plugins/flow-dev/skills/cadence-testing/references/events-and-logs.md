# Events and Logs

Events are the contract's public log of state changes. Every `emit SomeEvent(...)` statement a contract executes becomes part of the permanent record of the block it ran in, and clients (indexers, frontends, other contracts) depend on that record to reconstruct what happened. A test that only asserts on return values or storage state is missing half the story — if the contract claims a transaction should emit `Deposited`, the test should say so. Events are the observable API that external consumers rely on, so treating them as first-class assertions keeps the test honest about what the contract is supposed to expose.

Logs, produced by `log(...)` calls inside transactions, scripts, or contract functions, are for debugging. The testing framework captures them alongside events and exposes them through `blockchain.logs`, but a production contract rarely relies on them and neither should your tests — reserve log inspection for diagnosing why a test is misbehaving, not for encoding the behaviour under test.

The distinction between the two is enforced purely by convention, not by the runtime. Both survive through a full block commit, both accumulate across the whole test run, and both get rewound by `blockchain.reset`. What separates them is intent: events document durable contract-level behaviour and are part of the contract's external interface, while logs are ephemeral diagnostic output that might change or disappear during any refactor. Testing that respects this distinction produces assertions that survive refactors and break only when the contract's actual externally observable behaviour changes.

## Reading All Events

```cadence
let all = blockchain.events()
Test.expect(all, Test.haveElementCount(3))
```

`blockchain.events()` returns `[AnyStruct]` — every event emitted since the blockchain was created, in the order they were emitted. The entries are the event structs themselves; to read fields, cast each entry to its concrete event type. Events accumulate across the entire history of the blockchain unless you call `blockchain.reset(height:)`, which rewinds them along with the rest of the state.

Because the standard contracts deployed during the framework's bootstrap (`FungibleToken`, `NonFungibleToken`, account setup) also emit events, a raw `events()` call at the start of a test typically includes a dozen or more entries that have nothing to do with your contract. Use `eventsOfType` instead whenever the assertion cares about a specific event — it keeps the test from coupling to framework internals that can change between Flow CLI releases.

The return type `[AnyStruct]` is the same regardless of how many distinct event types the entries cover. Cadence has no variant or union type to express "array of these specific event types", so the framework hands you the widest possible container and trusts you to downcast. That design is fine for focused filtering through `eventsOfType`, but it makes raw `events()` inspection tedious: every entry needs a `switch` or a chain of `as?` casts before its fields are accessible, which is another reason most test code never touches `events()` directly.

One legitimate use of raw `events()` is a sanity-check at the very top of a new test file. Run the test, print `events()`, inspect the output, and use it to decide which event types are worth asserting on. That is a one-time exploratory step, not a permanent assertion — replace the `events()` print with targeted `eventsOfType` assertions before the test lands in the repository.

## Filtering by Type

```cadence
let incs = blockchain.eventsOfType(Type<Counter.Incremented>())
Test.expect(incs, Test.haveElementCount(1))
```

`blockchain.eventsOfType(type:)` returns only the events whose runtime type matches the given `Type` value. Construct the type with `Type<Contract.EventName>()` when the event is declared inside an imported contract — the test file must have `import "Counter"` at the top for `Counter.Incremented` to resolve as a type.

The returned array is `[AnyStruct]`, same as `events()`, so each entry still needs an explicit downcast before you can read its fields. The cast is safe because the filter already narrowed the type; the downcast is mechanical.

`eventsOfType` is the right default for event assertions. It filters out the bootstrap noise described above and keeps the test focused on the behaviour under test. Reach for raw `events()` only when the assertion genuinely cares about cross-event ordering across contracts the test doesn't own.

The `Type<...>()` form is a compile-time expression, not a runtime lookup — the compiler needs to resolve the event's declaring contract at parse time, which is why the surrounding `import` matters. If a test needs to filter on an event declared in a contract that is loaded dynamically (for example a mock that is swapped in under a different name per test), the type expression will not compile; route through `events()` with an explicit downcast chain instead, and keep that awkwardness contained to the one test that genuinely needs dynamic dispatch.

## Event Type Strings

Every Cadence event has a canonical, fully qualified string identifier:

```
A.<8-byte-hex-address>.<Contract>.<EventName>
```

The address is the contract's deployed address, written as 16 hex characters (eight bytes) with leading zeros. For a contract deployed under the testing alias `0x0000000000000007`, the event `Counter.Incremented` has the type string `A.0000000000000007.Counter.Incremented`. The leading `A.` is a literal prefix the runtime uses to disambiguate event types from other identifier forms.

Most of the time you do not need to write this string by hand — `Type<Counter.Incremented>()` produces the correct type value automatically. You do need to know the format when you're parsing event output from the CLI, comparing against a string field, or debugging a mismatched filter. The format is case-sensitive: `counter.incremented` and `Counter.Incremented` are different types, and a test that expects one while the contract emits the other silently returns an empty array from `eventsOfType`.

The hex-padding convention is also worth internalising because it surfaces in log output, block explorer URLs, and off-chain event consumers. A short address like `0x7` is cosmetic: Flow always stores and serialises it as `0x0000000000000007`, and the event type string uses the 16-character form unconditionally. When a test assertion compares a type string against the output of another tool, that other tool almost certainly emitted the padded form, so padding both sides (or constructing the type through `Type<...>()`) keeps the comparison stable.

The contract address in a testing-framework event type string comes from the `testing` alias in `flow.json`, not from wherever the contract is deployed on testnet or mainnet. A contract at `0x0000000000000007` in the test harness may live at `0xaabbccdd...` on mainnet; the event types are technically different by fully-qualified name, even though the underlying Cadence declaration is identical. This is rarely a problem for tests — you are asserting on the testing-harness version of the type — but it matters when a test cross-references an event type string captured from a live network.

## Asserting a Single Event

The canonical shape for "this transaction emitted exactly one `Incremented` event with `newValue: 1`":

```cadence
let events = blockchain.eventsOfType(Type<Counter.Incremented>())
Test.expect(events, Test.haveElementCount(1))
let evt = events[0] as! Counter.Incremented
Test.assertEqual(1 as Int, evt.newValue)
```

Assert on the element count first, then downcast and assert on fields. The order matters: downcasting `events[0]` when the array is empty panics with an index-out-of-range error rather than a legible matcher message, so letting `haveElementCount` run first turns a "no event was emitted" bug into a clear failure.

The same ordering principle applies in reverse — if the test expects the transaction to emit zero events of a given type, assert that expectation explicitly with `Test.expect(events, Test.beEmpty())`. That produces a clear failure if the contract unexpectedly starts emitting the event, and documents the intent better than a silent absence of any check at all.

Casting to the concrete event type (`as! Counter.Incremented`) gives you typed access to every field the event declared. The event struct's fields are whatever the contract defined — `newValue`, `previousValue`, `from`, `to`, and so on — and each field has the Cadence type it was declared with. No `AnyStruct` unwrapping is needed after the cast.

Use forced casts (`as!`) rather than optional casts (`as?`) in this setting. The preceding `haveElementCount` check has already proved that the element is exactly the type you filtered for, so an optional cast would add a layer of optional-handling for a case that cannot arise. A forced cast that panics on type mismatch is the right signal if the framework ever returns an entry that does not match the filter — that would be a bug in the framework worth failing loudly over, not a runtime condition the test should silently handle.

Keep the assertions on fields narrow. Assert on the fields that the test specifically cares about; do not mirror every field of the event just because you can. A test that checks only `newValue` survives a future change that adds a new field to the event, where an exhaustive test would need to be updated.

Pair the event check with a state check when the event's purpose is to announce a state change. Asserting only on the event verifies that the contract said something happened, not that something actually did; asserting only on the state verifies the change but not the announcement. Doing both — check the event was emitted with the right fields, then run a script that reads the resulting state and assert it matches — covers the contract's observable surface from both sides and catches mismatches where the state changed without the event, or vice versa.

Concretely:

```cadence
let tx = Test.Transaction(
    code: Test.readFile("../transactions/increment.cdc"),
    authorizers: [admin.address],
    signers: [admin],
    arguments: []
)
let result = blockchain.executeTransaction(tx)
Test.expect(result, Test.beSucceeded())

let events = blockchain.eventsOfType(Type<Counter.Incremented>())
Test.expect(events, Test.haveElementCount(1))
let evt = events[0] as! Counter.Incremented
Test.assertEqual(1 as Int, evt.newValue)

let script = Test.readFile("../scripts/get_count.cdc")
let readBack = blockchain.executeScript(script, [])
Test.expect(readBack, Test.beSucceeded())
Test.assertEqual(1 as Int, readBack.returnValue! as! Int)
```

The extra script call is cheap and catches the class of bugs where a contract emits the "right" event but fails to actually persist the state change — a real failure mode when an author refactors a function and forgets to update the storage mutation alongside the event.

When the transaction emits the same event type multiple times, compare against the full list in one step. Build an array of expected field values and assert that the emitted events' fields match, in order. Avoid a hand-rolled loop that asserts field-by-field on each index — the loop obscures the shape of the expected data and a single off-by-one hides the real intent. A clean array comparison makes the test self-documenting and lets the matcher render a clear failure when the shapes diverge.

## Asserting Ordered Sequences

When a transaction emits several events and the test cares about their relative order or joint contents:

```cadence
let incs = blockchain.eventsOfType(Type<Counter.Incremented>())
let rsts = blockchain.eventsOfType(Type<Counter.Reset>())
Test.expect(incs, Test.haveElementCount(2))
Test.expect(rsts, Test.haveElementCount(1))

let firstInc = incs[0] as! Counter.Incremented
let secondInc = incs[1] as! Counter.Incremented
Test.assertEqual(1 as Int, firstInc.newValue)
Test.assertEqual(2 as Int, secondInc.newValue)

let resetEvt = rsts[0] as! Counter.Reset
Test.assertEqual(0 as Int, resetEvt.newValue)
```

`eventsOfType` preserves emission order within a single type, so `incs[0]` is always the first `Incremented` the blockchain saw. Cross-type ordering (did the `Reset` happen before or after the first `Incremented`?) requires reading from raw `events()` and comparing positions, which is almost always a sign the assertion is over-specified. If the contract's correctness depends on the interleaving, assert on the resulting state instead of on the event order — state is what users observe, and event ordering can change during benign refactors.

A multiplex test that exercises two transactions in sequence and asserts on the combined event trail reads cleanly with per-type filters: each filter gives a clean list, each list is asserted independently, and the test stays readable even as the number of event types grows.

Order-sensitive assertions are most useful when the sequence is part of the contract's advertised behaviour — for example a vesting contract that promises to emit `Unlocked` before `Transferred` so an indexer can attribute the transfer to the unlock. In those cases, document the expectation in the test's name or a short comment so a future reader understands that the order is intentional, not incidental. A test called `testUnlockEmitsBeforeTransfer` communicates the invariant at a glance; a test called `testEvents` that silently depends on order is a refactor hazard waiting to happen.

A closely related pattern is asserting on event field sequences across related events. When a transaction emits several `Transferred` events as part of a batch operation, the sequence of `amount` values or `recipient` addresses is often the assertion the test wants to make:

```cadence
let xfers = blockchain.eventsOfType(Type<Counter.Transferred>())
Test.expect(xfers, Test.haveElementCount(3))
let first = xfers[0] as! Counter.Transferred
let second = xfers[1] as! Counter.Transferred
let third = xfers[2] as! Counter.Transferred
Test.assertEqual(10 as Int, first.amount)
Test.assertEqual(20 as Int, second.amount)
Test.assertEqual(30 as Int, third.amount)
```

Project the field of interest out of each event and compare the resulting scalar sequence against the expected values. The per-event downcast is mechanical but unavoidable — Cadence's type system cannot widen `[AnyStruct]` to `[Counter.Transferred]` without the explicit cast.

## Reading Logs

```cadence
let lines = blockchain.logs()
Test.expect(lines, Test.contain("counter incremented"))
```

`blockchain.logs()` returns `[String]` — every `log(...)` line emitted by transactions, scripts, and contract functions since the blockchain was created (or since the last `reset`). Logs are useful during development: sprinkle `log(...)` calls in a contract under investigation, run the test, inspect `blockchain.logs()` to see what the runtime printed.

Do not promote logs to primary test assertions. Logs are a debugging affordance, not a contract's public API — a refactor that removes a stray `log` call silently breaks a test that asserts on it, and the fix is always to delete the assertion rather than to restore the log. When the test needs to observe a state change, emit an event for it and assert on the event instead.

Like events, logs accumulate across the whole blockchain history and are cleared by `reset`. Framework bootstrap rarely logs anything, so `logs()` is usually quieter than `events()`, but that is not a guarantee — filter by substring (`Test.contain`) rather than by exact element count if you want the assertion to be resilient.

A practical workflow for using logs as a debugging aid: add a `log("value: ".concat(x.toString()))` inside the contract function you are investigating, run the failing test, print `blockchain.logs()` from the test body, and read the captured output. Once the bug is understood, remove the `log` call before committing — leaving debug logs in production Cadence code bloats every transaction that invokes the function and adds nothing at runtime that an event could not already express. The testing framework does not enforce this discipline; it's a convention you enforce with code review.

Logs can also be handy when the test runner itself needs a breadcrumb. Calling `log` from inside a test body prints the message to `blockchain.logs()` alongside contract logs, which is useful in a long test where the failure does not pin down which phase produced it. Treat this as temporary scaffolding rather than a permanent part of the test — once the test passes reliably, the log calls should come out.

The `Test.contain` matcher checks substring membership when applied to a `String` array, so an assertion like `Test.expect(lines, Test.contain("counter incremented"))` accepts any log line whose text contains the substring `counter incremented`. This is more forgiving than a full-string match and usually the right level of specificity for logs, which tend to embed runtime values that change between runs. If the test genuinely needs an exact-match assertion on a log line, pair the substring check with a count check or a direct `assertEqual` against a specific index — but prefer the substring idiom when the intent is "something like this was logged" rather than "exactly this was logged".

## Resetting Between Tests

The interaction between `reset` and the event log is worth stating separately because it is the single most common source of confusion for tests that use `beforeEach`. The sketch below is the same pattern described in the emulation reference, applied specifically to events:

```cadence
access(all) let blockchain = Test.newEmulatorBlockchain()
access(all) var setupHeight: UInt64 = 0

access(all) fun setup() {
    let err = blockchain.deployContract(
        name: "Counter",
        path: "../contracts/Counter.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    setupHeight = getCurrentBlock().height
}

access(all) fun beforeEach() {
    blockchain.reset(height: setupHeight)
}
```

After the `reset` call, `blockchain.events()` still contains every event emitted during `setup()` — the contract's `ContractInitialized` event, any bootstrap events from standard library setup, anything the test file's file-level `createAccount` calls produced. Those events are at heights at or before `setupHeight`, so the reset preserves them. Events emitted during the previous `testXxx` are at heights after `setupHeight` and are discarded.

This means the event assertions inside a test only need to worry about the events that test itself produced, plus any deploy-time events from `setup()`. Filter with `eventsOfType` or count against a baseline captured at the end of `setup()` to skip over the latter cleanly.

A baseline-delta pattern is worth spelling out because it comes up whenever the deploy-time count for an event type is non-zero. Capture the count at the end of `setup()`, then compare the post-test count against that baseline:

```cadence
access(all) var baselineIncs: Int = 0

access(all) fun setup() {
    // ... deploy contracts ...
    baselineIncs = blockchain.eventsOfType(Type<Counter.Incremented>()).length
    setupHeight = getCurrentBlock().height
}

access(all) fun testIncrementEmits() {
    // ... run the transaction ...
    let incs = blockchain.eventsOfType(Type<Counter.Incremented>())
    Test.assertEqual(baselineIncs + 1, incs.length)
}
```

Most tests avoid this complexity by using `reset` in `beforeEach` so each test starts from the same baseline, which makes the per-test delta trivially equal to the observed count after the test's own transactions.

## Pitfalls

- **Events emitted during `setup()` leak into `events()` in your tests.** Contract `init` blocks often emit events (`ContractInitialized`, mint events, capability publication), and the standard library bootstrap emits several of its own. A naked `events()` call at the top of a test sees all of them. Use `eventsOfType` to focus on the contract under test, or capture the event count at the end of `setup()` and compare deltas in each test.
- **`reset(height)` rewinds events too.** If your test calls `blockchain.reset(height: 0)` (or any height earlier than the deployment height), the deploy-time events are gone along with the deployment itself. Capture `setupHeight` at the end of `setup()` and reset to that height in `beforeEach()` — the deployment events stay, and only per-test events are discarded.
- **Type string casing matters.** `A.0000000000000007.Counter.Incremented` and `A.0000000000000007.counter.incremented` are different types. `Type<Counter.Incremented>()` handles this for you, so prefer it over constructing type strings by hand. If you must write a type string manually, match the contract's declared casing exactly — a silent mismatch produces an empty filtered array, not an error.
- **Comparing addresses with the `0x` prefix.** An event field declared `from: Address` is an `Address` value, not a `String`, and `Address` equality works without string manipulation — prefer `Test.assertEqual(admin.address, evt.from)` over any string form. If you must stringify (for logging or interop), use `.toString()`, which returns the canonical `0x`-prefixed form, and make sure both sides of the comparison use the same prefix and leading-zero convention.
- **Forgetting to downcast before reading fields.** An entry pulled from `events()` or `eventsOfType` is still typed as `AnyStruct` — a direct `.newValue` access on the `AnyStruct` value fails to compile. The `as! Counter.Incremented` step is required; once the cast succeeds, every field is typed and accessible.
- **Asserting on the full `events()` list when `eventsOfType` would do.** A raw `events()` assertion couples the test to unrelated bootstrap events and breaks the next time the framework adds or removes one. Filter first, assert second — the test becomes an order of magnitude more stable.
- **Confusing `log` output with event output.** `log("a value was set")` does not emit an event, even if the message looks like an event name. It only writes to `blockchain.logs()`. If the intent is for off-chain consumers to observe the state change, the contract must declare an event and `emit` it; no amount of log-level message crafting substitutes for a real event.
