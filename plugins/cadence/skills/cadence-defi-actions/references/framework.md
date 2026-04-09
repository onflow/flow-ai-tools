# DeFi Actions Core Framework

## Imports
```cadence
import "FungibleToken"
import "DeFiActions"
import "SwapConnectors"
import "IncrementFiStakingConnectors"
import "IncrementFiPoolLiquidityConnectors"
import "Staking"
```

## Core Interfaces

### Source
Provides tokens from various sources.
```
getSourceType(): Type
minimumAvailable(): UFix64
withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault}
```

### Sink
Accepts tokens for deposit.
```
getSinkType(): Type
minimumCapacity(): UFix64
depositCapacity(from: auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
```

### Swapper
Converts tokens between types.
```
inType(): Type
outType(): Type
quoteIn(forDesired: UFix64, reverse: Bool): {Quote}
quoteOut(forProvided: UFix64, reverse: Bool): {Quote}
swap(quote: {Quote}?, inVault: @{FungibleToken.Vault}): @{FungibleToken.Vault}
swapBack(quote: {Quote}?, residual: @{FungibleToken.Vault}): @{FungibleToken.Vault}
```

### Quote
Swap estimation data: `inType`, `outType`, `inAmount`, `outAmount`.

### SwapSource
Combines Source + Swapper. Acts as a Source that automatically swaps.
```cadence
SwapConnectors.SwapSource(swapper: {Swapper}, source: {Source}, uniqueID: UniqueIdentifier?)
```
- `getSourceType()` returns swapper's output type
- `minimumAvailable()` estimates tokens after swap

### SwapSink
Combines Swapper + Sink. Acts as a Sink that swaps before depositing.
```cadence
SwapConnectors.SwapSink(swapper: {Swapper}, sink: {Sink}, uniqueID: UniqueIdentifier?)
```

### AutoBalancer
Resource maintaining vault balance within thresholds:
```cadence
DeFiActions.AutoBalancer(
    lower: UFix64, upper: UFix64,
    oracle: {PriceOracle}, vaultType: Type,
    outSink: {Sink}?, inSource: {Source}?,
    uniqueID: UniqueIdentifier?
)
```

### PriceOracle
```
unitOfAccount(): Type
price(ofToken: Type): UFix64?
```

## Base Types

### UniqueIdentifier
Created via `DeFiActions.createUniqueIdentifier()`. Use same ID across all connectors in one operation.

### IdentifiableStruct / IdentifiableResource
Base interfaces for all connectors. Required methods: `id()`, `getComponentInfo()`, `copyID()`, `setID()`.

## Composition Rules

### Basic: Source → Sink
```cadence
let vault <- source.withdrawAvailable(maxAmount: sink.minimumCapacity())
sink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
assert(vault.balance == 0.0, message: "Residual after deposit")
destroy vault
```

### Swap-Enhanced
```
SwapSource(swapper, source) → Sink
Source → SwapSink(swapper, sink)
```

### Multi-Level (chaining SwapSources)
```cadence
let base = VaultSource(...)
let first = SwapSource(swapper1, base)
let final = SwapSource(swapper2, first)  // Chain: base → swap1 → swap2
```

### AutoBalancer Integration
```
AutoBalancerSource → Sink
Source → AutoBalancerSink
```

## Implementing Custom Connectors

Every struct implementing `Source`, `Sink`, or `Swapper` MUST include these from `IdentifiableStruct`:

```cadence
// Required field — access(contract), NOT pub or access(all)
access(contract) var uniqueID: DeFiActions.UniqueIdentifier?

// Required functions
access(all) fun getComponentInfo(): DeFiActions.ComponentInfo
access(contract) view fun copyID(): DeFiActions.UniqueIdentifier?
access(contract) fun setID(_ id: DeFiActions.UniqueIdentifier?)
```

**Common implementation errors:**
- Using `pub` or `access(all)` instead of `access(contract)` for `uniqueID` — compile error
- Listing `IdentifiableStruct` again when inheriting from `Source` (which already extends it) — redundant
- Wrong swap method names (`exchange` instead of `swap`) — interface mismatch
- Using deprecated `quoteIn` — use `quoteOut` for withdrawal sizing
