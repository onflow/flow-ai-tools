# Randomness Vulnerabilities

Six classes of bugs specific to randomness on Flow. Severity ratings reflect what auditors observed in real contracts.

## V1 — Abort-on-bad-roll (Critical)

**The pattern:** a transaction calls `revertibleRandom()` (or any same-tx randomness), evaluates the result, and reverts via `panic` or `assert` if the result is unfavorable. The user pays only gas; they keep every win and discard every loss.

### Vulnerable

```cadence
transaction(targetMin: UInt64) {
    execute {
        let roll = MyContract.rollDie(sides: 6)
        log("rolled: ".concat(roll.toString()))
        assert(roll >= targetMin, message: "bad roll")
    }
}
```

Reproduced on emulator with `targetMin: 6`: 10 attempts, 2 commits, 8 reverts. Attacker keeps a perfect 6 every time without paying for the misses.

### Fix

Use the commit-reveal pattern via `RandomConsumer`. The reveal transaction's outcome is fully determined by `(beacon[N], request.uuid)` — re-running the reveal yields the same number, so reverting is pointless. Lock all wagers/state changes at commit time, not reveal time.

### Detection

Grep heuristic: any `.cdc` file that contains `revertibleRandom` AND (`panic(` OR `assert(`) in the same scope, AND has state mutation in the same `execute` block. Manual review required — not every same-tx use of `revertibleRandom` is exploitable, only those where the caller has incentive to revert.

## V2 — Modulo bias (Medium)

**The pattern:** reducing a uniform integer to a smaller range with `%` produces a non-uniform distribution unless the range divides the integer's modulus.

### Vulnerable

```cadence
let r = revertibleRandom<UInt64>() % 100  // values 0..15 are slightly more likely
```

### Fix

Use the built-in `modulo:` parameter:

```cadence
let r = revertibleRandom<UInt64>(modulo: 100)
```

Or for `RandomConsumer`, use `getNumberInRange(min:max:)` / `fulfillRandomInRange(request:min:max:)` — both handle bias correctly.

### Severity

Medium for most uses (skew is ~0.0001%). Critical for cryptographic schemes or large-scale games where small biases compound.

## V3 — Reveal too early (High)

**The pattern:** calling `Request._fulfill()` or `fulfillRandomInRange()` in the same block as the commit. The Consumer enforces this and panics, but a bad implementation might catch the error and retry, opening a same-block reveal vector.

### Symptom

Emulator panic: `Cannot fulfill random request before the eligible block height of N`.

### Fix

Always reveal in a separate transaction submitted at block height > commit block. Do not wrap fulfillment in `try`/recover patterns — let the panic propagate.

## V4 — Public Consumer capability (Critical)

**The pattern:** publishing a public capability to `&RandomConsumer.Consumer`. Anyone can call `requestRandomness()` and `_fulfill()` against the user's Consumer, draining their state or front-running their reveals.

### Vulnerable

```cadence
let cap = signer.capabilities.storage.issue<&RandomConsumer.Consumer>(/storage/MyConsumer)
signer.capabilities.publish(cap, at: /public/MyConsumer)  // ❌
```

### Fix

`Consumer` is a private resource. Borrow it directly from `signer.storage` in transactions; never expose via public capability. If you need third-party access for fulfillment, use a controlled wrapper resource that only exposes the specific operations you trust.

### Entitlement narrowing

Borrow with the minimum entitlement set required:
- Commit transaction: `auth(RandomConsumer.Commit) &Consumer`
- Reveal transaction: `auth(RandomConsumer.Reveal) &Consumer`

Never borrow `auth(RandomConsumer.Commit, RandomConsumer.Reveal) &Consumer` unless the same transaction must do both (rare and usually wrong).

## V5 — Single-Request misuse (Medium)

**The pattern:** treating a `RandomConsumer.Request` as a multi-use source. Each Request fulfills exactly once. To get multiple correlated values, use the PRG path:

```cadence
let prg = Xorshift128plus.PRG(sourceOfRandomness: source, salt: salt)
let v1 = prg.nextUInt64()
let v2 = prg.nextUInt64()  // correlated to v1, derived from same seed
```

### Vulnerable

Calling `fulfillRandomInRange()` on the same Request twice. The second call panics or returns a stale value depending on Consumer version.

### Fix

For one outcome: one Request, one fulfill. For N correlated outcomes from a single commit: read the source via Request, build a `Xorshift128plus.PRG`, and call `nextUInt64()` N times.

## V6 — Script-based randomness in tests (Low)

**The pattern:** writing tests that read `revertibleRandom` via `flow scripts execute` and asserting different values across calls. Scripts within the same block return identical values — the test will silently freeze on a single roll.

### Symptom

Three back-to-back script invocations all return `[13564773934808714830, 60, 3]`. Test passes accidentally because every assertion sees the same value.

### Fix

Test randomness via transactions, not scripts. Each transaction advances the block and produces a fresh value. For deterministic test values, use `RandomBeaconHistory.sourceOfRandomness(atBlockHeight:)` against a known past block.

## Audit checklist additions

When auditing a contract that uses randomness, add these to the checklist:

- [ ] Every `revertibleRandom` call traced to its caller — caller has no incentive to revert?
- [ ] Modulo reductions use `revertibleRandom<T>(modulo:)` or `getNumberInRange(min:max:)`, not `%`?
- [ ] No same-block fulfillment paths (no `try`/recover wrapping `_fulfill`)?
- [ ] `RandomConsumer.Consumer` is private — no public capability published?
- [ ] Borrow entitlements narrowed to `Commit` xor `Reveal`?
- [ ] State changes (wagers, locks, escrows) happen at commit, not reveal?
- [ ] Tests exercise randomness via transactions, not scripts?

## See also

- `cadence-lang/references/randomness.md` — full API reference
- `cadence-scaffold/references/secure-randomness.md` — safe templates
