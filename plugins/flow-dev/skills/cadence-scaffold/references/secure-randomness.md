# Secure Randomness Templates

Copy-paste templates for the four common randomness patterns. All examples are Cadence 1.0 and verified on the Flow emulator.

## Decision: which template?

| Use case | Template |
|---|---|
| Cosmetic / non-economic | T1 — Native roll |
| Past-block lookup | T2 — Beacon read |
| Game payout, raffle, NFT mint reveal | T3+T4 — Commit-reveal pair |
| Many correlated draws from one commit | T5 — PRG multi-draw |

Anything with economic outcomes uses T3+T4. **Never use T1 for payouts.**

## flow.json setup

Run once before deploying anything that uses `RandomConsumer`:

```bash
flow dependencies install mainnet://45caec600164c9e6.RandomConsumer
```

Pulls `Burner`, `RandomBeaconHistory`, `Xorshift128plus`, `RandomConsumer` transitively. The bare-name form `flow dependencies install RandomConsumer` fails with `invalid dependency format`.

In `flow.json`, ensure the deployments list keeps `Xorshift128plus` BEFORE `RandomConsumer` (the array is not topo-sorted):

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

## T1 — Native roll (cosmetic only)

```cadence
access(all) contract MyGame {
    access(all) event Rolled(value: UInt64)

    /// Cosmetic die roll. NOT safe if the caller can revert on a bad outcome.
    access(all) fun roll(sides: UInt64): UInt64 {
        let r = revertibleRandom<UInt64>(modulo: sides) + 1
        emit Rolled(value: r)
        return r
    }
}
```

Use this for visual effects, randomized UI, demo dice — never for outcomes that pay value.

## T2 — Beacon read (past block)

```cadence
import "RandomBeaconHistory"

access(all) contract Lottery {
    /// Resolve a draw whose seed was determined at `commitBlock`.
    /// Caller must save commitBlock at request time and pass it here.
    access(all) fun resolve(commitBlock: UInt64): [UInt8] {
        return RandomBeaconHistory.sourceOfRandomness(atBlockHeight: commitBlock).value
    }
}
```

Panics if `commitBlock` is the current or future block. Always read past blocks only.

## T3 — Commit transaction (request)

```cadence
import "RandomConsumer"

transaction {
    prepare(signer: auth(BorrowValue, SaveValue, LoadValue) &Account) {
        let consumerPath: StoragePath = /storage/MyConsumer
        let requestPath: StoragePath  = /storage/MyRequest

        let consumer = signer.storage
            .borrow<auth(RandomConsumer.Commit) &RandomConsumer.Consumer>(from: consumerPath)
            ?? panic("Consumer not initialized — run setup_consumer first")

        // Discard any stale request
        if let stale <- signer.storage.load<@RandomConsumer.Request>(from: requestPath) {
            destroy stale
        }

        let req <- consumer.requestRandomness()
        signer.storage.save(<-req, to: requestPath)

        // LOCK ALL WAGERS / STATE CHANGES HERE — at commit, not reveal.
        // e.g. transfer the bet vault into escrow now.
    }
}
```

## T4 — Reveal transaction (fulfill)

```cadence
import "RandomConsumer"

transaction {
    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        let consumerPath: StoragePath = /storage/MyConsumer
        let requestPath: StoragePath  = /storage/MyRequest

        let consumer = signer.storage
            .borrow<auth(RandomConsumer.Reveal) &RandomConsumer.Consumer>(from: consumerPath)
            ?? panic("Consumer not initialized")

        let req <- signer.storage.load<@RandomConsumer.Request>(from: requestPath)
            ?? panic("No pending request — run commit first")

        // Range-bounded reveal (handles modulo bias internally)
        let result = consumer.fulfillRandomInRange(request: <-req, min: 1, max: 100)

        // Settle outcome here. State was already locked at commit; this only PAYS OUT.
        log("revealed: ".concat(result.toString()))
    }
}
```

Must run at block height > commit block. The Consumer enforces this.

## T5 — Setup transaction (one-time)

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

## T6 — PRG multi-draw

When a single commit needs to produce N correlated values (shuffle a deck, generate traits for one mint):

```cadence
import "Xorshift128plus"

access(all) contract DeckShuffle {
    /// Build a PRG from a beacon-sourced seed and crank it N times.
    access(all) fun shuffle(seed: [UInt8], salt: [UInt8], count: Int): [UInt64] {
        let prg = Xorshift128plus.PRG(sourceOfRandomness: seed, salt: salt)
        let out: [UInt64] = []
        var i = 0
        while i < count {
            out.append(prg.nextUInt64())
            i = i + 1
        }
        return out
    }
}
```

Pair with T2 (read the seed from a past block via `RandomBeaconHistory`) or T4 (extract the source from a fulfilled `Request`).

## Anti-template — DO NOT USE

```cadence
// ❌ ABORT-ON-BAD-ROLL — vulnerable
transaction(targetMin: UInt64) {
    execute {
        let roll = MyGame.roll(sides: 6)
        // Pays out value on win, reverts on loss.
        // Attacker keeps every win for free.
        assert(roll >= targetMin, message: "bad roll, retry")
        MyGame.payout(amount: 100.0)
    }
}
```

The fix is structural, not a tweak: replace with T3 + T4. Lock the wager at commit, settle at reveal.

## Storage path conventions

| Path | Purpose |
|---|---|
| `/storage/<Project>Consumer` | The user's `RandomConsumer.Consumer` resource |
| `/storage/<Project>Request` | The pending `RandomConsumer.Request` between commit and reveal |

Do not publish public capabilities to either. Both are private.

## See also

- `cadence-lang/references/randomness.md` — API reference and decision matrix
- `cadence-audit/references/randomness-vulns.md` — what the audit will look for
