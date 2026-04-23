# Scaffold: DeFi Actions Transaction

## Interview the User

Before generating, ask for:
1. **DeFi operation type** — restake, swap, auto-balance, transfer
2. **Pool/protocol details** — pool IDs, addresses (will be parameters)
3. **Token types involved** — or derive from pool
4. **Minimum output amounts** — for post-condition safety

## Composition Pattern Selection

Identify the required flow:
- `Source → Sink` — simple transfer
- `SwapSource → Sink` — swap then deposit
- `Source → SwapSink → Sink` — withdraw then swap then deposit
- Canonical restake: `PoolRewardsSource → SwapSource(Zapper) → PoolSink`

## Critical Safety Rules (Blocking)

1. **Import syntax**: `import "ContractName"` — never `from 0x...`
2. **Pre/post**: single boolean expressions only — no variable declarations
3. **Accept addresses as parameters** — never hardcode
4. **Zapper token ordering**: source token MUST be token0; reverse if `source.getSourceType() != token0Type`
5. **Validate vault empty** (`balance == 0.0`) before destruction
6. **Nil-check** all borrowed capabilities
7. **Single uniqueID** across all composed connectors

## Transaction Physical Order
```
prepare → pre → execute → post
```

## Canonical Restake Template

```cadence
import "FungibleToken"
import "DeFiActions"
import "SwapConnectors"
import "IncrementFiStakingConnectors"
import "IncrementFiPoolLiquidityConnectors"
import "Staking"

transaction(pid: UInt64) {
    let userCertificateCap: Capability<&Staking.UserCertificate>
    let pool: &{Staking.PoolPublic}
    let startingStake: UFix64
    let swapSource: SwapConnectors.SwapSource
    let poolSink: IncrementFiStakingConnectors.PoolSink
    let expectedStakeIncrease: UFix64

    prepare(acct: auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account) {
        // Create operation ID — passed to all connectors for traceability
        let operationID = DeFiActions.createUniqueIdentifier()

        self.pool = IncrementFiStakingConnectors.borrowPool(pid: pid)
            ?? panic("Pool with ID \(pid) not found")
        self.startingStake = self.pool.getUserInfo(address: acct.address)?.stakingAmount
            ?? panic("No user info for \(acct.address)")
        self.userCertificateCap = acct.capabilities.storage
            .issue<&Staking.UserCertificate>(Staking.UserCertificateStoragePath)

        let pair = IncrementFiStakingConnectors.borrowPairPublicByPid(pid: pid)
            ?? panic("Pair not found for pool \(pid)")
        let token0Type = IncrementFiStakingConnectors.tokenTypeIdentifierToVaultType(pair.getPairInfoStruct().token0Key)
        let token1Type = IncrementFiStakingConnectors.tokenTypeIdentifierToVaultType(pair.getPairInfoStruct().token1Key)

        // Build connector chain with descriptive names
        let rewardsSource = IncrementFiStakingConnectors.PoolRewardsSource(
            userCertificate: self.userCertificateCap, pid: pid, uniqueID: operationID
        )

        // Reverse token order so source token becomes token0 (Zapper requirement)
        let reverse = rewardsSource.getSourceType() != token0Type
        let zapper = IncrementFiPoolLiquidityConnectors.Zapper(
            token0Type: reverse ? token1Type : token0Type,
            token1Type: reverse ? token0Type : token1Type,
            stableMode: pair.getPairInfoStruct().isStableswap,
            uniqueID: operationID
        )

        // SwapSource wraps Zapper + Source into composable connector
        let lpSource = SwapConnectors.SwapSource(
            swapper: zapper, source: rewardsSource, uniqueID: operationID
        )
        self.swapSource = lpSource
        self.expectedStakeIncrease = zapper.quoteOut(
            forProvided: lpSource.minimumAvailable(), reverse: false
        ).outAmount

        // Build PoolSink in prepare — operationID must be in scope (local var, not accessible in execute)
        self.poolSink = IncrementFiStakingConnectors.PoolSink(
            pid: pid, staker: self.userCertificateCap.address, uniqueID: operationID
        )
    }

    execute {
        // Size withdrawal by sink capacity
        let vault <- self.swapSource.withdrawAvailable(maxAmount: self.poolSink.minimumCapacity())
        self.poolSink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
        assert(vault.balance == 0.0, message: "Residual after deposit")
        destroy vault
    }

    post {
        // Optional chaining avoids a panic if getUserInfo returns nil (safer than force-unwrap)
        self.pool.getUserInfo(address: self.userCertificateCap.address)?.stakingAmount ?? 0.0
            >= self.startingStake + self.expectedStakeIncrease:
            "Restake below expected amount"
    }
}
```

## Post-Generation

After generating, add comments explaining:
- Intent and safety rationale for each connector
- Why token order was reversed (if applicable)
- What the post-condition verifies

Also add `///` doc comments for the transaction and helper functions so the generated code is self-documenting.
