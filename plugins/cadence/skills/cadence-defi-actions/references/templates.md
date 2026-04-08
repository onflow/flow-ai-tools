# Transaction Templates & AI Generation Guide

## AI Generation Principles

1. **Start from the entrypoint**: Use the restake workflow as the canonical pattern
2. **Derive types from pool**: Don't add extra params — get token types from pool pair
3. **Size by sink capacity**: `withdrawAvailable(maxAmount: sink.minimumCapacity())`
4. **Assert residuals**: Always `vault.balance == 0.0` before destroy
5. **Single uniqueID**: Share across all connectors in one operation
6. **Explicit instantiation**: Create each connector separately with descriptive names

## Template: Generic Source → Sink Transfer

```cadence
import "FungibleToken"
import "DeFiActions"

transaction() {
    let source: {DeFiActions.Source}
    let sink: {DeFiActions.Sink}

    prepare(acct: auth(BorrowValue) &Account) {
        // Initialize source and sink
    }

    execute {
        let vault <- self.source.withdrawAvailable(maxAmount: self.sink.minimumCapacity())
        self.sink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
        assert(vault.balance == 0.0, message: "Transfer incomplete")
        destroy vault
    }
}
```

## Template: Swap and Deposit

```cadence
import "FungibleToken"
import "DeFiActions"
import "SwapConnectors"

transaction(amount: UFix64) {
    let swapSource: SwapConnectors.SwapSource
    let sink: {DeFiActions.Sink}

    prepare(acct: auth(BorrowValue) &Account) {
        let operationID = DeFiActions.createUniqueIdentifier()
        let source = SomeSource(..., uniqueID: operationID)
        let swapper = SomeSwapper(..., uniqueID: operationID)
        self.swapSource = SwapConnectors.SwapSource(
            swapper: swapper, source: source, uniqueID: operationID
        )
        self.sink = SomeSink(..., uniqueID: operationID)
    }

    execute {
        let vault <- self.swapSource.withdrawAvailable(maxAmount: self.sink.minimumCapacity())
        self.sink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
        assert(vault.balance == 0.0, message: "Residual after deposit")
        destroy vault
    }
}
```

## Template: Multi-Swap Chain

```cadence
// Chain: Vault → Swap A→B → Swap B→LP → Stake
let vaultSource = FungibleTokenConnectors.VaultSource(min: 10.0, withdrawVault: cap, uniqueID: opID)
let firstSwap = SwapConnectors.SwapSource(swapper: aToBSwapper, source: vaultSource, uniqueID: opID)
let secondSwap = SwapConnectors.SwapSource(swapper: bToLPSwapper, source: firstSwap, uniqueID: opID)
let stakingSink = IncrementFiStakingConnectors.PoolSink(pid: pid, staker: addr, uniqueID: opID)

let vault <- secondSwap.withdrawAvailable(maxAmount: stakingSink.minimumCapacity())
stakingSink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
assert(vault.balance == 0.0, message: "Residual")
destroy vault
```

## Connector API Quick Reference

| Connector | Constructor | Type |
|-----------|------------|------|
| VaultSource | `(min?, withdrawVault, uniqueID?)` | Source |
| VaultSink | `(max?, depositVault, uniqueID?)` | Sink |
| SwapSource | `(swapper, source, uniqueID?)` | Source |
| SwapSink | `(swapper, sink, uniqueID?)` | Sink |
| MultiSwapper | `(inVault, outVault, swappers, uniqueID?)` | Swapper |
| PoolRewardsSource | `(userCertificate, pid, uniqueID?)` | Source |
| PoolSink | `(pid, staker, uniqueID?)` | Sink |
| Zapper | `(token0Type, token1Type, stableMode, uniqueID?)` | Swapper |

## Common Patterns

### Claim-Zap-Stake (Restaking)
1. Borrow pool, record starting stake
2. Issue UserCertificate capability
3. Derive token types from pair
4. Create PoolRewardsSource → Zapper → SwapSource → PoolSink
5. Compute expectedStakeIncrease from quote
6. Post-condition: new stake >= starting + expected

### AutoBalancer Deposit
1. Create Source (rewards/vault)
2. Optionally wrap with SwapSource
3. Create AutoBalancerSink from capability
4. Execute standard Source → Sink transfer

### Vault-to-Vault Transfer
1. Create VaultSource with min balance protection
2. Create VaultSink with max capacity
3. Execute Source → Sink transfer
