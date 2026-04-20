# Assertions and Matchers

The testing framework exposes two styles of assertion. The direct style — `Test.assert`, `Test.assertEqual`, and `Test.fail` — reads like plain imperative code and produces terse failure output. The matcher-based style — `Test.expect(value, matcher)` and `Test.expectFailure(closure, errorMessageSubstring)` — composes small, reusable predicates and renders richer failure messages that name the matcher that rejected the value.

Matchers compose with `and`, `or`, and `Test.not`, so a single `Test.expect` call can describe compound conditions without nesting ifs. The two styles coexist in the same test file — most tests reach for direct assertions by default and escalate to matchers only when composition or richer error output would pay off.

## Direct Assertions

| Function | Purpose | Example |
|---|---|---|
| `Test.assert(cond, msg?)` | Fails if `cond` is false; optional message is printed on failure. | `Test.assert(balance > 0, message: "balance must be positive")` |
| `Test.fail(msg?)` | Unconditionally fails the current test. | `Test.fail(message: "unreachable branch hit")` |
| `Test.assertEqual(expected, actual)` | Fails if the two values are not equal. | `Test.assertEqual(42 as Int, result.returnValue! as! Int)` |

Direct assertions are the right choice when the check is a single comparison and you want the failure output to be short. They do not combine with the matcher combinators described below — if you need `and` / `or` / `not`, reach for `Test.expect` and a matcher.

`Test.assert` takes a boolean expression first and an optional `message` as the second argument. The message is evaluated only when the assertion is about to fail, so computing a descriptive message (for example by interpolating runtime values) is cheap on the happy path.

`Test.fail` is the form to use inside an otherwise-unreachable branch — for example the `default` of a `switch` that is meant to be exhaustive, or after a panicking helper call where the compiler does not know the control flow has ended.

`Test.assertEqual` takes the expected value first and the actual value second; the rendered failure message is sensitive to that order, so swapping the arguments produces a confusing "expected <actual>, got <expected>" error.

## Matcher-Based Assertions

`Test.expect(value, matcher)` feeds `value` into `matcher` and fails the test if the matcher rejects it. The matcher itself is responsible for describing the failure, so the rendered error tends to be more descriptive than a raw `assertEqual`.

```cadence
Test.expect(result, Test.beSucceeded())
Test.expect(balances, Test.haveElementCount(3))
```

`Test.expectFailure(closure, errorMessageSubstring)` runs a closure that is expected to panic and asserts that the panic message contains the given substring. Use it to assert that a helper function, a pre/post condition, or any code that runs directly in the test's own call stack reverts for the right reason:

```cadence
Test.expectFailure(fun(): Void {
    // code expected to fail
    panic("not authorized")
}, errorMessageSubstring: "not authorized")
```

If the closure runs to completion without panicking, `expectFailure` fails the test. If it panics with a message that does not contain the substring, `expectFailure` fails and reports both the expected substring and the actual panic message. The closure must have signature `fun (): Void` — it takes no arguments and returns nothing. Capture any state you need from the surrounding scope via ordinary variable references; the closure is a first-class value and closes over its enclosing bindings.

## Built-in Matchers

The Cadence testing framework ships a small set of matchers covering the cases that come up most often: equality, ordering, nil/empty, membership, element count, and success/failure of a blockchain call. Anything outside that set is best handled by a custom matcher rather than by stretching a built-in one.

### `Test.equal(value)`

Matches when the candidate is equal to `value`. Equivalent in effect to `assertEqual` but composable with the other matcher combinators.

```cadence
Test.expect("hello", Test.equal("hello"))
```

### `Test.beGreaterThan(number)`

Matches when the candidate is strictly greater than `number`. The comparison is strict — use `Test.not(Test.beLessThan(x))` (or two separate assertions) for "greater than or equal to".

```cadence
Test.expect(balance, Test.beGreaterThan(0 as UFix64))
```

### `Test.beLessThan(number)`

Matches when the candidate is strictly less than `number`. Pairs naturally with `beGreaterThan` via `and` to express open intervals.

```cadence
Test.expect(feeBps, Test.beLessThan(100 as UInt16))
```

### `Test.beNil()`

Matches when the candidate is `nil`. This is the canonical check after `deployContract` or after any helper that returns an optional error — a `nil` return means success.

```cadence
let err = blockchain.deployContract(name: "Counter", path: "../contracts/Counter.cdc", arguments: [])
Test.expect(err, Test.beNil())
```

### `Test.beEmpty()`

Matches when the candidate (an array, dictionary, or string) has no elements. Prefer `beEmpty` over `haveElementCount(0)` when the intent is "nothing happened" — the rendered failure message reads more naturally.

```cadence
let events = blockchain.eventsOfType(Type<Counter.Incremented>())
Test.expect(events, Test.beEmpty())
```

### `Test.haveElementCount(int)`

Matches when the candidate has exactly the given number of elements. Useful for asserting how many events a transaction emitted or how many entries a script returned.

```cadence
let events = blockchain.eventsOfType(Type<Counter.Incremented>())
Test.expect(events, Test.haveElementCount(2))
```

### `Test.contain(element)`

Matches when the candidate (an array, dictionary, or string) contains the given element. For dictionaries, the element is the key; to assert on a value, project the value out and compare it directly.

```cadence
let names = ["alice", "bob"]
Test.expect(names, Test.contain("alice"))
```

### `Test.beSucceeded()`

Matches a `ScriptResult` or `TransactionResult` whose status is success. Prefer this over inspecting `result.status` by hand — the failure message includes the underlying error, which turns an otherwise opaque "assertion failed" into a line pointing at the revert reason.

```cadence
let result = blockchain.executeScript(source, [])
Test.expect(result, Test.beSucceeded())
```

### `Test.beFailed()`

Matches a `ScriptResult` or `TransactionResult` whose status is failure. Typically followed by an assertion on `result.error!.message` to pin down which failure mode you were expecting.

```cadence
let result = blockchain.executeScript(badSource, [])
Test.expect(result, Test.beFailed())
```

## Combinators

Composition is the single biggest reason to prefer the matcher style over direct assertions. A custom-matcher-like effect can almost always be achieved by combining the built-ins with the three combinators below, which saves the overhead of writing a `Test.newMatcher` predicate.

Matchers compose with three combinators. `Test.not(m)` inverts a matcher. The instance methods `m.and(other)` and `m.or(other)` build short-circuiting conjunctions and disjunctions.

```cadence
let positive = Test.beGreaterThan(0)
let small = Test.beLessThan(100)
Test.expect(42, positive.and(small))

// negation
Test.expect(result, Test.not(Test.beFailed()))

// disjunction
let empty = Test.beEmpty()
let single = Test.haveElementCount(1)
Test.expect(events, empty.or(single))
```

Combinators produce ordinary matcher values — you can bind them to a `let` and reuse them across tests, which is the usual reason to reach for `Test.expect` over `assertEqual`. `and` short-circuits: if the left matcher rejects the value, the right matcher never runs and its failure message never appears. `or` short-circuits symmetrically — the right matcher runs only if the left rejects. For that reason, put the cheaper or more informative matcher on the left of `and`, and the more restrictive matcher on the left of `or`.

Combinators also chain. `a.and(b).and(c)` produces a single matcher that accepts values satisfying all three constituents, and `a.or(b).or(c)` produces a matcher accepting any of the three. Parenthesise explicitly if you mix `and` and `or` — Cadence has no special precedence rules for these methods, they associate left-to-right like any other method chain, which is rarely what you want when expressing a boolean formula.

## Custom Matchers

`Test.newMatcher<T>(testFn)` builds a matcher from a predicate `fun (T): Bool`. Use it for project-specific checks that do not map onto a built-in matcher.

```cadence
access(all) fun startsWith(_ prefix: String): Test.Matcher {
    return Test.newMatcher<String>(fun (value: String): Bool {
        return value.length >= prefix.length
            && value.slice(from: 0, upTo: prefix.length) == prefix
    })
}

access(all) fun testErrorMessagePrefix() {
    Test.expect("denied: caller not admin", startsWith("denied:"))
}
```

A custom matcher is just a regular `access(all) fun` returning `Test.Matcher`, so you can parameterise it, reuse it across files (by putting it in a helper file and importing its symbols via the test harness), and combine it with the standard combinators exactly like a built-in matcher.

The type parameter on `Test.newMatcher<T>` is not optional. If you skip it, the matcher accepts `AnyStruct` and your predicate ends up with a less useful signature and surprise runtime cast failures. Always spell out the concrete type that your predicate consumes — it is the type the matcher will accept on the left-hand side of a `Test.expect` call.

A custom matcher is the right tool when the assertion involves more than a single equality or ordering check. For example, asserting that two balance values differ by exactly a fee amount:

```cadence
access(all) fun differBy(_ expected: UFix64): Test.Matcher {
    return Test.newMatcher<[UFix64; 2]>(fun (pair: [UFix64; 2]): Bool {
        let delta = pair[0] > pair[1] ? pair[0] - pair[1] : pair[1] - pair[0]
        return delta == expected
    })
}
```

Wrapping this logic in a named matcher keeps the individual test assertions short and lets the failure message name the invariant (`differBy`) rather than spelling out the arithmetic each time.

## assertEqual vs expect(x, Test.equal(y))

The framework offers two equivalent ways to spell an equality check, and newcomers reasonably wonder which one they should use. They truly do check the same condition; the choice is purely stylistic, but the style has consequences for readability and for how the failure renders in the CLI output.

`assertEqual` and `expect(x, Test.equal(y))` check the same condition. Choose based on what you plan to do with the check:

- **`assertEqual`** — plain equality with no composition. The failure output is a compact "expected X, got Y". This is the default for single-shot checks inside a test body.
- **`Test.expect(x, Test.equal(y))`** — when the equality check is one half of a compound condition (`equal(y).or(equal(z))`), when you want to bind the matcher to a `let` and reuse it, or when you want the matcher-style failure message.

A mechanical rule: if the next thing you would write is `.and(...)` or `.or(...)`, use `Test.expect`; otherwise use `assertEqual`.

A secondary consideration is readability for someone scanning the test. `Test.assertEqual(expected, actual)` puts the expected value first and matches the convention most developers already have from other testing frameworks. `Test.expect(actual, Test.equal(expected))` reverses that order, which trips up readers who expect the traditional "expected, actual" placement. Reserve the matcher form for cases where composition genuinely earns the reordering, and keep `assertEqual` as the default.

## Testing Reverts

Tests that only cover the happy path miss half the contract's behaviour. Contracts spend a lot of their complexity budget on guard rails — access checks, invariant assertions, balance validations — and those guard rails deserve direct test coverage. The framework offers two distinct ways to assert "this was supposed to fail", and picking the wrong one silently makes the test useless.

A Cadence call that panics inside a test file propagates the panic and fails the test with that message. There are two idioms for asserting that a revert happened, and the right choice depends on where the panic originates.

**In-process panics** — use `Test.expectFailure`. The closure runs in the test's own call stack, so a direct call to a helper or a Cadence call that panics is caught by the framework:

```cadence
Test.expectFailure(fun(): Void {
    panic("not authorized")
}, errorMessageSubstring: "not authorized")
```

**Blockchain panics** — a transaction or script that reverts on the blockchain returns a `TransactionResult` or `ScriptResult` whose `status` is failure; it does not propagate a panic into the test. Inspect the result directly:

```cadence
let result = blockchain.executeScript(source, [])
Test.expect(result, Test.beFailed())
Test.assert(result.error!.message.contains("not authorized"),
    message: "unexpected error: ".concat(result.error!.message))
```

Match on a stable substring only. Contract error messages often embed addresses, nonces, or resource IDs that change between runs, so a full-string `assertEqual` against an error message is brittle. Picking a short, intention-revealing fragment ("not authorized", "insufficient balance") keeps the test readable and resilient.

If the test body does not care why the call failed — only that it did — stop after `Test.beFailed()` and skip the substring check. Adding a substring check you don't need couples the test to an implementation detail of the contract and creates churn the next time the error message is reworded.

Across all of these idioms, the rule of thumb is the same: assert on the smallest stable thing that still proves the behaviour you care about. A narrow assertion survives refactors; a broad one becomes a maintenance burden within a few sprints.

## Common Mistakes

- **Comparing addresses as strings without normalising the `0x` prefix.** `0x01` and `01` are not equal as `String` but refer to the same `Address`. Compare `Address` values as `Address`, not as strings — if you must stringify, strip the `0x` on both sides before the compare. The same caveat applies to event field values read out of `AnyStruct` maps, which the framework returns with the canonical `0x`-prefixed form.
- **Using `assertEqual` across types that don't implement `Equatable`.** The framework compares with `==`, so non-`Equatable` composite types (structs without an explicit conformance, resources) will not compare usefully. Assert on a scalar projection of the value instead, or write a `Test.newMatcher` that extracts the fields you care about and compares each one explicitly.
- **Overly specific `expectFailure` substrings.** A substring like `"not authorized: 0xabcdef0123456789 attempted to withdraw 100.0"` breaks the moment the contract changes its error formatting — or worse, the moment a different caller runs the test. Match on the shortest substring that identifies the specific failure mode ("not authorized") and leave the rest out.
- **Forgetting to unwrap `result.error`.** After `Test.expect(result, Test.beFailed())`, `result.error` is non-`nil` — but still typed as an optional. Use `result.error!.message` (or bind it with `if let err = result.error`) when building the substring assertion, otherwise the test fails with a confusing optional-dereference error rather than the matcher message you intended.
- **Using `Test.expectFailure` for a blockchain call.** `blockchain.executeScript` and `blockchain.executeTransaction` return a result — they do not panic from the test's perspective even when the underlying call reverts. Wrapping them in `expectFailure` makes the test pass for the wrong reason: the closure returns normally, which is itself a failure of `expectFailure`. Use `Test.expect(result, Test.beFailed())` for blockchain calls and reserve `expectFailure` for code that panics in the test process itself.
- **Re-running the same matcher inside a loop without rebinding.** Matchers are plain values; they hold no per-call state. But if you assemble a matcher inside a loop with `and`/`or`, make sure you reset the accumulator between iterations, otherwise the conjunction grows with each pass and eventually rejects everything.
- **Omitting the `message` on `Test.assert` for compound predicates.** A bare `Test.assert(a > 0 && b < 100 && c.contains("x"))` failure says only "assertion failed". Supply a short message that names the expectation so a CI failure is legible without opening the test file — or, better, convert the compound into a `Test.expect` with combined matchers so the matcher renders the failure for you.
