# DeFi Workflows

## Minimal Restake Workflow (Claim → Zap → Stake)

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
    let expectedStakeIncrease: UFix64

    prepare(acct: auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account) {
        self.pool = IncrementFiStakingConnectors.borrowPool(pid: pid)
            ?? panic("Pool with ID \(pid) not found")
        self.startingStake = self.pool.getUserInfo(address: acct.address)?.stakingAmount
            ?? panic("No user info for address \(acct.address)")
        self.userCertificateCap = acct.capabilities.storage
            .issue<&Staking.UserCertificate>(Staking.UserCertificateStoragePath)

        let operationID = DeFiActions.createUniqueIdentifier()

        let pair = IncrementFiStakingConnectors.borrowPairPublicByPid(pid: pid)
            ?? panic("Pair not found for pool \(pid)")
        let token0Type = IncrementFiStakingConnectors.tokenTypeIdentifierToVaultType(pair.getPairInfoStruct().token0Key)
        let token1Type = IncrementFiStakingConnectors.tokenTypeIdentifierToVaultType(pair.getPairInfoStruct().token1Key)

        let rewardsSource = IncrementFiStakingConnectors.PoolRewardsSource(
            userCertificate: self.userCertificateCap, pid: pid, uniqueID: operationID
        )

        let reverse = rewardsSource.getSourceType() != token0Type

        let zapper = IncrementFiPoolLiquidityConnectors.Zapper(
            token0Type: reverse ? token1Type : token0Type,
            token1Type: reverse ? token0Type : token1Type,
            stableMode: pair.getPairInfoStruct().isStableswap,
            uniqueID: operationID
        )

        let lpSource = SwapConnectors.SwapSource(
            swapper: zapper, source: rewardsSource, uniqueID: operationID
        )

        self.swapSource = lpSource
        self.expectedStakeIncrease = zapper.quoteOut(
            forProvided: lpSource.minimumAvailable(), reverse: false
        ).outAmount
    }

    post {
        self.pool.getUserInfo(address: self.userCertificateCap.address)!.stakingAmount
            >= self.startingStake + self.expectedStakeIncrease:
            "Restake below expected amount"
    }

    execute {
        let poolSink = IncrementFiStakingConnectors.PoolSink(
            pid: pid, staker: self.userCertificateCap.address, uniqueID: nil
        )
        let vault <- self.swapSource.withdrawAvailable(maxAmount: poolSink.minimumCapacity())
        poolSink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
        assert(vault.balance == 0.0, message: "Residual after deposit")
        destroy vault
    }
}
```

## Parameter Mapping
- **pool id** → `pid: UInt64`
- Token types and `stableMode` derived from pool pair
- For single-pool requests, prefer hardcoded `pid` constant for auditability

## AutoBalancer Workflow

### Setup
```cadence
let autoBalancer <- DeFiActions.AutoBalancer(
    lower: 0.95,            // Rebalance when value drops below 95%
    upper: 1.05,            // Rebalance when value exceeds 105%
    oracle: priceOracle,
    vaultType: Type<@FlowToken.Vault>(),
    outSink: excessSink,    // Where to send excess value
    inSource: topUpSource,  // Where to get value shortfall
    uniqueID: operationID
)
```

### Create Sources/Sinks from AutoBalancer
```cadence
let balancerSource = autoBalancer.createBalancerSource()
let balancerSink = autoBalancer.createBalancerSink()
```

### Update Components
```cadence
autoBalancer.setSink(sink: newSink, updateSinkID: true)
autoBalancer.setSource(source: newSource, updateSourceID: true)
```

### Integration in Chain
```cadence
// Rewards → Zap → AutoBalancer (instead of direct staking)
let autoBalancerSink = DeFiActions.AutoBalancerSink(
    autoBalancer: balancerCap, uniqueID: operationID
)
let vault <- swapSource.withdrawAvailable(maxAmount: autoBalancerSink.minimumCapacity())
autoBalancerSink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
```

## Style & Naming
- Use named args and descriptive identifiers: `poolRewardsSource`, `zapper`, `lpSource`, `poolSink`
- Instantiate components explicitly — don't nest constructors
- Keep parameters minimal; avoid protocol addresses unless strictly needed
- Use string imports exactly as shown
- Add short block headers and intent comments for key steps
