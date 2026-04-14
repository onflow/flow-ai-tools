# Connectors and Composition

## Quick Reference (Restaking)
- Rewards Source: `IncrementFiStakingConnectors.PoolRewardsSource(userCertificate, pid, uniqueID?)`
- Zapper (to LP): `IncrementFiPoolLiquidityConnectors.Zapper(token0Type, token1Type, stableMode, uniqueID?)`
- Swap wrapper: `SwapConnectors.SwapSource(swapper, source, uniqueID?)`
- Staking Sink: `IncrementFiStakingConnectors.PoolSink(pid, staker, uniqueID?)`

## Helpers (IncrementFi)
```cadence
IncrementFiStakingConnectors.borrowPool(pid: UInt64): &{Staking.PoolPublic}?
IncrementFiStakingConnectors.borrowPairPublicByPid(pid: UInt64): &{SwapInterfaces.PairPublic}?
IncrementFiStakingConnectors.tokenTypeIdentifierToVaultType(_ tokenKey: String): Type
```

## FungibleToken Connectors

### VaultSource
```cadence
FungibleTokenConnectors.VaultSource(
    min: UFix64?, withdrawVault: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
    uniqueID: DeFiActions.UniqueIdentifier?
)
```

### VaultSink
```cadence
FungibleTokenConnectors.VaultSink(
    max: UFix64?, depositVault: Capability<&{FungibleToken.Vault}>,
    uniqueID: DeFiActions.UniqueIdentifier?
)
```

## Swap Connectors

### SwapSource
```cadence
SwapConnectors.SwapSource(swapper: {DeFiActions.Swapper}, source: {DeFiActions.Source}, uniqueID?)
```
- Size withdraws by sink capacity: `withdrawAvailable(maxAmount: sink.minimumCapacity())`

### SwapSink
```cadence
SwapConnectors.SwapSink(swapper: {DeFiActions.Swapper}, sink: {DeFiActions.Sink}, uniqueID?)
```

### MultiSwapper
```cadence
SwapConnectors.MultiSwapper(inVault: Type, outVault: Type, swappers: [{DeFiActions.Swapper}], uniqueID?)
```

## IncrementFi Staking Connectors

### PoolSink
```cadence
IncrementFiStakingConnectors.PoolSink(pid: UInt64, staker: Address, uniqueID?)
```

### PoolRewardsSource
```cadence
IncrementFiStakingConnectors.PoolRewardsSource(
    userCertificate: Capability<&Staking.UserCertificate>, pid: UInt64, uniqueID?
)
```

## IncrementFi Pool Liquidity

### Zapper
```cadence
IncrementFiPoolLiquidityConnectors.Zapper(token0Type: Type, token1Type: Type, stableMode: Bool, uniqueID?)
```
- `inType()` is token0; `outType()` is LP vault type
- **Token Ordering**: If `source.getSourceType() != token0Type`, reverse token order so reward token becomes token0 (input to zapper)
- `quoteOut(reverse: false)` estimates LP from token0
- `swapBack` converts LP back to token0

## Composition Patterns

### Explicit Instantiation (Preferred)
```cadence
let rewardsSource = IncrementFiStakingConnectors.PoolRewardsSource(...)
let reverse = rewardsSource.getSourceType() != token0Type
let zapper = IncrementFiPoolLiquidityConnectors.Zapper(
    token0Type: reverse ? token1Type : token0Type,
    token1Type: reverse ? token0Type : token1Type,
    stableMode: stableMode, uniqueID: operationID
)
let swapSource = SwapConnectors.SwapSource(swapper: zapper, source: rewardsSource, uniqueID: operationID)
```

### Validate Compatibility
```cadence
assert(source.getSourceType() == swapper.inType(), message: "Source/Swapper type mismatch")
assert(swapper.outType() == sink.getSinkType(), message: "Swapper/Sink type mismatch")
```

### Consistent UniqueIDs
Use same ID for all components in one operation:
```cadence
let operationID = DeFiActions.createUniqueIdentifier()
```
