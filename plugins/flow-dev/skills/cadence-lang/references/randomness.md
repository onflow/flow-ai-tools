# Randomness in Cadence

Flow exposes three randomness primitives. Pick the right one for your threat model — they trade off latency against the abort-on-bad-roll attack.

## Decision matrix

| API | Latency | Safe against abort-on-bad-roll? | Use when |
|---|---|---|---|
| `revertibleRandom<T>(modulo:)` | same tx | ❌ NO | result is independent of caller incentives (cosmetic, fair-coin-flip with no payoff revert) |
| `RandomBeaconHistory.sourceOfRandomness(atBlockHeight:)` | 1 block | ✅ YES (committed beacon) | reading randomness derived from a specific past block |
| `RandomConsumer` + `Xorshift128plus` (commit-reveal) | 2 txs | ✅ YES | any user-facing action with economic outcomes — gambling, loot, raffles, NFT trait reveals |
| `useFlowRevertibleRandom` (frontend) | same query | ❌ NO | UI-only seeds (animations, demo dice). Never economic. |

**Default to `RandomConsumer`** for anything that pays out value. Only use the native function when you can prove the caller has no incentive to revert on a bad outcome.

## A. `revertibleRandom<T>()`

Built-in. Returns `T` for any unsigned integer type. Accepts an optional `modulo:` to avoid modulo bias.

```cadence
let a: UInt64  = revertibleRandom<UInt64>()
let b: UInt8   = revertibleRandom<UInt8>()
let c: UInt256 = revertibleRandom<UInt256>()

// Uniform in [0, 100). The built-in modulo is bias-free; do NOT use `r % 100`.
let d: UInt64 = revertibleRandom<UInt64>(modulo: 100)
```

### ❌ Cannot be called from a `view` function

```cadence
access(all) view fun roll(): UInt64 {
    return revertibleRandom<UInt64>() // compile error: impure operation in view context
}
```

### ❌ Modulo bias if you reduce manually

```cadence
let biased = revertibleRandom<UInt64>() % 100  // skewed distribution
```

### ✅ Use the `modulo:` parameter

```cadence
let fair = revertibleRandom<UInt64>(modulo: 100)
```

### Scripts repeat within the same block

A `flow scripts execute` call returns the same value every time until a transaction advances the block height. Three back-to-back script calls in the same block all returned `[13564773934808714830, 60, 3]`. **Don't write tests as scripts** — the freeze hides bugs.

### Multiple calls in one transaction DO advance state

```cadence
transaction {
    execute {
        let a = revertibleRandom<UInt64>()
        let b = revertibleRandom<UInt64>()  // different from a
        let c = revertibleRandom<UInt64>()  // different from a and b
    }
}
```

## B. `RandomBeaconHistory`

Verifiable beacon randomness recorded per block. Read past blocks only.

| Network | Address |
|---|---|
| Mainnet | `0xe467b9dd11fa00df` |
| Testnet | `0x8c5303eaa26202d6` |
| Emulator | `0xf8d6e0586b0a20c7` |

```cadence
import "RandomBeaconHistory"

access(all) fun beaconAt(height: UInt64): [UInt8] {
    return RandomBeaconHistory.sourceOfRandomness(atBlockHeight: height).value
}

access(all) view fun lowest(): UInt64 {
    return RandomBeaconHistory.getLowestHeight()
}
```

### Constraints

- Reading the **current** block panics: `Source of randomness not yet recorded for block height N`. The source for block N exists only at block N+1.
- `getLowestHeight()` returns the earliest available block. On a fresh emulator it is 1; on mainnet/testnet it grows over time as old beacon entries are pruned.
- Pre-deployed on the emulator service account — do NOT try to deploy `RandomBeaconHistory` yourself.

### Use case

Resolving a result that depends on a past block — the user already committed at block N (recorded in storage), and now you read `sourceOfRandomness(atBlockHeight: N)` to derive their outcome deterministically.

## C. `RandomConsumer` + `Xorshift128plus` (commit-reveal)

Standard library for safe randomness. The `Consumer` resource issues a `Request` (commit) that can only be fulfilled at block N+1 or later (reveal). Because the source for block N is undetermined when the commit lands, the user cannot inspect it mid-tx and revert.

| Network | Address |
|---|---|
| Mainnet | `0x45caec600164c9e6` |
| Testnet | `0xed24dbe901028c5c` |

Install via:

```bash
flow dependencies install mainnet://45caec600164c9e6.RandomConsumer
```

This transitively pulls `Burner`, `RandomBeaconHistory`, `Xorshift128plus`. Do NOT use `flow dependencies install RandomConsumer` (bare name) — fails with `invalid dependency format`.

### Setup (one-time)

```cadence
import "RandomConsumer"

transaction {
    prepare(signer: auth(SaveValue, BorrowValue) &Account) {
        let path: StoragePath = /storage/MyConsumer
        if signer.storage.borrow<&RandomConsumer.Consumer>(from: path) == nil {
            signer.storage.save(<-RandomConsumer.createConsumer(), to: path)
        }
    }
}
```

### Commit (block N)

```cadence
import "RandomConsumer"

transaction {
    prepare(signer: auth(BorrowValue, SaveValue) &Account) {
        let consumer = signer.storage
            .borrow<auth(RandomConsumer.Commit) &RandomConsumer.Consumer>(from: /storage/MyConsumer)
            ?? panic("Consumer not initialized")
        let req <- consumer.requestRandomness()
        signer.storage.save(<-req, to: /storage/MyRequest)
    }
}
```

### Reveal (block N+1 or later)

```cadence
import "RandomConsumer"

transaction {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        let consumer = signer.storage
            .borrow<auth(RandomConsumer.Reveal) &RandomConsumer.Consumer>(from: /storage/MyConsumer)
            ?? panic("Consumer not initialized")
        let req <- signer.storage.load<@RandomConsumer.Request>(from: /storage/MyRequest)
            ?? panic("No pending request")
        let result = consumer.fulfillRandomInRange(request: <-req, min: 1, max: 100)
        log("revealed: ".concat(result.toString()))
    }
}
```

### Entitlements

`Commit` and `Reveal` are distinct entitlements. Borrow with the narrowest one for the operation. **Never publish a public capability to `&Consumer`** — it would let anyone request and fulfill on your behalf.

### Fulfillment timing

- `fulfillRandomInRange(min:max:)` panics if called in the same block as the commit: `Cannot fulfill random request before the eligible block height of N`.
- The `Request` stores the commit block; reveal is allowed once `getCurrentBlock().height > request.block`.

### PRG for multi-draw

`Xorshift128plus.PRG(sourceOfRandomness:salt:)` builds a deterministic PRG from a beacon source. Use when one beacon read should produce multiple correlated values (e.g., shuffle 100 cards from one source).

```cadence
import "Xorshift128plus"

access(all) fun draw5(seed: [UInt8], salt: [UInt8]): [UInt64] {
    let prg = Xorshift128plus.PRG(sourceOfRandomness: seed, salt: salt)
    let out: [UInt64] = []
    var i = 0
    while i < 5 {
        out.append(prg.nextUInt64())
        i = i + 1
    }
    return out
}
```

## flow.json deploy order gotcha

The deployments array is NOT topo-sorted. `Xorshift128plus` must appear before `RandomConsumer`:

```json
"deployments": {
    "emulator": {
        "emulator-account": [
            "Xorshift128plus",
            "RandomConsumer"
        ]
    }
}
```

Reverse order fails at startup: `deployment contains nonexisting contract Xorshift128plus`.

## See also

- `cadence-audit/references/randomness-vulns.md` — abort-on-bad-roll, modulo bias, reveal-too-early, missing entitlement
- `cadence-scaffold/references/secure-randomness.md` — copy-paste templates
- `flow-react-sdk/references/use-flow-revertible-random.md` — frontend hook
