# NFT Advanced Patterns

Advanced patterns for NFTs with dynamic traits, evolution, genetic systems, and complex behaviors. For standard interface conformance and basic collection patterns, see `token-patterns.md`.

## TraitModule Interface — Full Definition

Each trait module is a separate contract implementing the `TraitModule` interface:

```cadence
// In TraitModule.cdc (shared interface contract)
access(all) contract interface TraitModule {

    access(all) resource interface Trait {
        // Read current value
        access(all) view fun getRawValue(): AnyStruct
        access(all) view fun getValueAsString(): String
        access(all) view fun getDisplayName(): String

        // Check before evolving
        access(all) view fun canEvolve(): Bool

        // Accumulative evolution — called by core NFT contract
        // access(all) required: called cross-contract from EvolvingNFT
        // @discardableResult: callers may discard the return value
        @discardableResult
        access(all) fun evolveAccumulative(
            seeds: {String: UInt64},
            steps: UInt64,
            nftOwner: Address?,
            nftUUID: UInt64
        ): AnyStruct?

        // Internal update — access(all) required for cross-contract use
        access(all) fun updateValue(newValue: AnyStruct)
    }

    // Factory functions — implemented by each module contract
    access(all) fun createDefaultTrait(nftUUID: UInt64): @{Trait}
    access(all) fun createTraitWithSeed(seed: UInt64, nftUUID: UInt64): @{Trait}
    access(all) fun createChildTrait(
        parent1Trait: &{Trait},
        parent2Trait: &{Trait},
        seed: UInt64,
        nftUUID: UInt64
    ): @{Trait}
    access(all) fun createMitosisChild(
        parentTrait: &{Trait},
        seed: UInt64,
        nftUUID: UInt64
    ): @{Trait}
}
```

---

## Module Registry Pattern

The core NFT contract maintains a registry mapping module type strings to their deployed contracts:

```cadence
// ✅ Module registry in core NFT contract
access(all) contract EvolvingNFT: NonFungibleToken {

    // Module type → (contract address, contract name)
    access(self) var registeredModules: {String: Address}
    access(self) var moduleContracts: {String: String}

    // Ordered list — determines evolution processing order
    access(self) var moduleOrder: [String]

    // Admin-only registration
    access(account) fun registerModule(
        moduleType: String,
        contractAddress: Address,
        contractName: String
    ) {
        self.registeredModules[moduleType] = contractAddress
        self.moduleContracts[moduleType] = contractName
        if !self.moduleOrder.contains(moduleType) {
            self.moduleOrder.append(moduleType)
        }
    }

    // Public read — used by trait lazy init
    access(all) view fun getModuleFactory(
        moduleType: String
    ): &{TraitModule}? {
        if let address = self.registeredModules[moduleType],
           let name = self.moduleContracts[moduleType] {
            return getAccount(address).contracts.borrow<&{TraitModule}>(name: name)
        }
        return nil
    }
}
```

---

## Lazy Trait Initialization — ❌ / ✅

### ❌ Eager initialization wastes gas for unused traits
```cadence
// Bad: Creates all trait resources at mint time
access(all) fun mint(): @NFT {
    let nft <- create NFT(uuid: self.nextID)
    // Force-creates every possible trait upfront
    nft.traits["strength"] <-! StrengthModule.createDefaultTrait(nftUUID: nft.uuid)
    nft.traits["speed"] <-! SpeedModule.createDefaultTrait(nftUUID: nft.uuid)
    nft.traits["magic"] <-! MagicModule.createDefaultTrait(nftUUID: nft.uuid)
    return <- nft
}
```

### ✅ Lazy initialization — create only when accessed
```cadence
// Good: Trait created on first access
access(contract) fun ensureTraitExists(traitType: String): Bool {
    if self.traits.containsKey(traitType) { return true }
    if let factory = EvolvingNFT.getModuleFactory(moduleType: traitType) {
        let defaultTrait <- factory.createDefaultTrait(nftUUID: self.uuid)
        let old <- self.traits.insert(key: traitType, <-defaultTrait)
        destroy old  // destroy nil placeholder
        return true
    }
    return false
}

// Caller pattern
access(all) fun getTraitValue(traitType: String): AnyStruct? {
    if self.ensureTraitExists(traitType: traitType) {
        return self.traits[traitType]?.getRawValue()
    }
    return nil
}
```

---

## Module Ordering — Controls Evolution Sequence

```cadence
// ✅ Order matters: earlier modules can affect later ones
// e.g., "strength" feeds into "combatPower" calculation

access(all) fun evolve() {
    let elapsed = getCurrentBlock().timestamp - self.lastEvolutionTimestamp
    let steps = UInt64(elapsed / self.evolutionInterval)
    if steps == 0 { return }

    // Seeds derived from unpredictable state
    let seeds: {String: UInt64} = {
        "time": UInt64(getCurrentBlock().timestamp),
        "height": getCurrentBlock().height,
        "uuid": self.uuid
    }

    // Process in registered order — dependency-safe
    for moduleType in EvolvingNFT.moduleOrder {
        if self.ensureTraitExists(traitType: moduleType) {
            self.traits[moduleType]?.evolveAccumulative(
                seeds: seeds,
                steps: steps,
                nftOwner: self.owner?.address,
                nftUUID: self.uuid
            )
        }
    }

    self.lastEvolutionTimestamp = getCurrentBlock().timestamp
}
```

---

## Genetic Systems

### Dominance / Recessive in `createChildTrait`
```cadence
access(all) fun createChildTrait(
    parent1Trait: &{TraitModule.Trait},
    parent2Trait: &{TraitModule.Trait},
    seed: UInt64,
    nftUUID: UInt64
): @{TraitModule.Trait} {
    let p1 = parent1Trait.getRawValue() as? UInt64 ?? 0
    let p2 = parent2Trait.getRawValue() as? UInt64 ?? 0

    // Dominant allele wins; 25% chance of recessive expression
    let isDominantExpressed = (seed % 4) != 0  // 75% dominant
    let value = isDominantExpressed
        ? (p1 > p2 ? p1 : p2)    // dominant = higher value
        : (p1 < p2 ? p1 : p2)    // recessive = lower value

    // Rare mutation (1 in 256)
    let mutated = (seed % 256) == 0
        ? value + (seed % 10) + 1  // small positive mutation
        : value

    return <- create Trait(value: mutated, nftUUID: nftUUID)
}
```

### Averaging / Blending
```cadence
// For continuous traits (e.g., height, speed)
let blended = (p1 + p2) / 2
// Optional variance: ± (seed % varianceRange)
let withVariance = blended + (seed % 5) - 2  // ±2 variance
```

---

## Common Mistakes

### ❌ Forgetting to destroy the old value in insert
```cadence
// Bad: resource leak if key already exists
self.traits[traitType] = <-newTrait  // ❌ Can't assign resource this way
self.traits.insert(key: traitType, <-newTrait)  // ❌ Old resource leaked if key exists
```

### ✅ Always capture and destroy the displaced value
```cadence
let old <- self.traits.insert(key: traitType, <-newTrait)
destroy old  // Destroys nil (placeholder) or the previous trait resource
```

### ❌ Using block timestamp as sole randomness source
```cadence
// Bad: validators know block timestamp, predictable
let seed = UInt64(getCurrentBlock().timestamp)
```

### ✅ Mix multiple entropy sources
```cadence
let seed = UInt64(getCurrentBlock().timestamp) ^ getCurrentBlock().height ^ self.uuid
// For strong randomness, use Flow's VRF: RandomBeaconHistory contract
```

### ❌ Accessing all modules during a read (MetadataViews)
```cadence
// Bad: evolveAccumulative called in a view function via MetadataViews
access(all) fun resolveView(_ view: Type): AnyStruct? {
    if view == Type<MetadataViews.Traits>() {
        self.evolve()  // ❌ State mutation in view context
    }
}
```

### ✅ Separate read from write
```cadence
// Traits view returns current stored values (no mutation)
access(all) view fun resolveView(_ view: Type): AnyStruct? {
    if view == Type<MetadataViews.Traits>() {
        return self.buildTraitsView()  // pure read
    }
    return nil
}

// Evolution is a separate transaction
access(all) fun evolve() { /* state mutation */ }
```

> **See also:** `token-patterns.md` for the full `TraitModule.Trait` interface definition, the core NFT resource structure, and FT patterns.
