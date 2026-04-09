# Token Patterns

## Modular NFT Design

For NFTs with dynamic traits, evolution, or complex behaviors, use a modular architecture.

### Core NFT Contract
Manages lifecycle, basic metadata, and coordinates trait modules:
```cadence
// Trait Registry
access(self) var registeredModules: {String: Address}
access(self) var moduleContracts: {String: String}
access(self) var moduleOrder: [String]

access(account) fun registerModule(moduleType: String, contractAddress: Address, contractName: String) { }
access(all) view fun getModuleFactory(moduleType: String): &{TraitModule}? { }
```

### NFT Resource with Traits
```cadence
access(all) resource NFT {
    access(self) var traits: @{String: {TraitModule.Trait}}
    access(all) let nftUUID: UInt64
    access(self) var lastEvolutionTimestamp: UFix64
    access(self) var accumulatedEP: UFix64
}
```

### Lazy Trait Initialization
Initialize traits on-demand to save gas:
```cadence
access(contract) fun ensureTraitExists(traitType: String): Bool {
    if self.traits.containsKey(traitType) { return true }
    if let factory = EvolvingCreatureNFT.getModuleFactory(moduleType: traitType) {
        let defaultTrait <- factory.createDefaultTrait(nftUUID: self.uuid)
        let oldTrait <- self.traits.insert(key: traitType, <-defaultTrait)
        destroy oldTrait
        return true
    }
    return false
}
```

### Evolution
The core NFT `evolve()` function:
1. Calculates elapsed time/steps since last evolution
2. Generates seeds using timestamps and UUID
3. Iterates through registered modules (respecting order)
4. Calls each module's `evolveAccumulative()` with seeds and step count
5. Updates global NFT state

### Reproduction
Core contract hosts `reproduceSexual()` and `reproduceAsexual()` functions that iterate through trait modules, calling `createChildTrait()` or `createMitosisChild()`.

## Trait Module Interface
```cadence
access(all) resource interface Trait {
    access(all) view fun getRawValue(): AnyStruct
    access(all) view fun getValueAsString(): String
    access(contract) fun updateValue(newValue: AnyStruct)
    access(all) view fun getDisplayName(): String
    access(contract) fun evolveAccumulative(seeds: {String: UInt64}, steps: UInt64, nftOwner: Address?, nftUUID: UInt64): AnyStruct?
    access(all) view fun canEvolve(): Bool
}
```

### Factory Functions (per module)
```cadence
access(all) fun createDefaultTrait(nftUUID: UInt64): @{TraitModule.Trait}
access(all) fun createTraitWithSeed(seed: UInt64, nftUUID: UInt64): @{TraitModule.Trait}
access(all) fun createChildTrait(parent1Trait: &{TraitModule.Trait}, parent2Trait: &{TraitModule.Trait}, seed: UInt64, nftUUID: UInt64): @{TraitModule.Trait}
access(all) fun createMitosisChild(parentTrait: &{TraitModule.Trait}, seed: UInt64, nftUUID: UInt64): @{TraitModule.Trait}
```

## Advanced Genetic Systems
- **Genetic Markers**: Arrays of `UFix64` or named gene structs
- **Dominance/Recessive**: Implement within `createChildTrait`
- **Fertility & Maturity**: Module or global NFT state
- **Mutations**: Algorithmic rare mutations based on seed
- **Heritability**: Per-module rules (averaging, blending, discrete selection)

## Benefits of Modular Design
- **Scalability**: Add new traits by creating new modules
- **Maintainability**: Organized, easy to debug
- **Flexibility**: Different NFTs use different module combinations
- **Testability**: Test modules in isolation
- **Gas Efficiency**: Lazy init + accumulative evolution

## FT Token Patterns

### Basic Vault with Entitlements
```cadence
import "FungibleToken"
import "Burner"

access(all) contract MyToken: FungibleToken {
    entitlement Withdraw

    access(all) var totalSupply: UFix64

    access(all) event TokensMinted(amount: UFix64)
    access(all) event TokensBurned(amount: UFix64)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    access(all) resource Vault: FungibleToken.Vault {
        access(self) var balance: UFix64

        access(all) view fun getBalance(): UFix64 { return self.balance }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let amount = from.balance
            Burner.burn(<-from)
            self.balance = self.balance + amount
            emit TokensDeposited(amount: amount, to: self.owner?.address)
        }

        access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre { self.balance >= amount: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <- create Vault(balance: amount)
        }

        init(balance: UFix64) { self.balance = balance }
    }

    access(all) resource Minter {
        access(all) fun mintTokens(amount: UFix64): @Vault {
            MyToken.totalSupply = MyToken.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <- create Vault(balance: amount)
        }
    }

    access(all) fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    init() {
        self.totalSupply = 0.0
        self.account.storage.save(<- create Minter(), to: /storage/myTokenMinter)
    }
}
```

### FT Key Rules
- Implement `FungibleToken.Vault` interface (Provider, Receiver, Balance)
- Use `access(Withdraw)` entitlement for withdraw operations
- `deposit` should be `access(all)` (anyone can deposit)
- Use named constants for total supply
- Emit events for minting, burning, transfers
- Store vault at well-known storage path
- Publish receiver capability publicly (no entitlements)
