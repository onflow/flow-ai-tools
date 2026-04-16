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
    access(all) fun updateValue(newValue: AnyStruct)
    access(all) view fun getDisplayName(): String
    // Return value may be discarded by callers (e.g. EvolvingNFT)
    access(all) fun evolveAccumulative(seeds: {String: UInt64}, steps: UInt64, nftOwner: Address?, nftUUID: UInt64): AnyStruct?
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

access(all) contract MyToken: FungibleToken {
    // Uses FungibleToken.Withdraw entitlement (declared in the FungibleToken standard contract)

    access(all) var totalSupply: UFix64

    // FungibleToken.Vault interface auto-emits Withdrawn/Deposited events via its post conditions.
    // Only declare custom events for operations not covered by the standard (mint, burn).
    access(all) event TokensMinted(amount: UFix64)
    access(all) event TokensBurned(amount: UFix64)

    access(all) resource Vault: FungibleToken.Vault {
        access(all) var balance: UFix64

        access(all) view fun getBalance(): UFix64 { return self.balance }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @MyToken.Vault
            self.balance = self.balance + vault.balance
            destroy vault
            // FungibleToken.Vault interface post condition auto-emits FungibleToken.Deposited
        }

        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre { self.balance >= amount: "Insufficient balance" }
            self.balance = self.balance - amount
            return <- create Vault(balance: amount)
            // FungibleToken.Vault interface post condition auto-emits FungibleToken.Withdrawn
        }

        // Required: FungibleToken.Vault inherits Burner.Burnable via the Balance interface.
        // Burner.burn(<-vault) calls this before destroying — update totalSupply here.
        // deposit() uses plain `destroy vault` (bypasses burnCallback) because transfers
        // are not burns and must not decrement totalSupply.
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                MyToken.totalSupply = MyToken.totalSupply - self.balance
            }
            self.balance = 0.0
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

    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <- create Vault(balance: 0.0)
    }

    init() {
        self.totalSupply = 0.0
        self.account.storage.save(<- create Minter(), to: /storage/myTokenMinter)
    }
}
```

### FT Key Rules
- Implement `FungibleToken.Vault` interface (Provider, Receiver, Balance, Burner.Burnable)
- Use `access(FungibleToken.Withdraw)` entitlement for withdraw operations
- `deposit` should be `access(all)` (anyone can deposit)
- Use `destroy vault` in `deposit()` — NOT `Burner.burn()` — to avoid decrementing totalSupply during transfers
- Implement `burnCallback()` to decrement `totalSupply` (called by `Burner.burn()` in explicit burn operations)
- Do NOT emit custom Deposited/Withdrawn events — the FungibleToken interface post conditions auto-emit `FungibleToken.Deposited` and `FungibleToken.Withdrawn`
- DO emit custom events for mint and burn (not covered by the standard)
- Store vault at well-known storage path
- Publish receiver capability publicly (no entitlements)
