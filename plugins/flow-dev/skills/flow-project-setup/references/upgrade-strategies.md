# Contract Upgrade Strategies

## What Cadence Allows and Forbids

Cadence enforces upgrade safety at the protocol level. The CLI will reject invalid upgrades.

| Change | Allowed? |
|--------|----------|
| Add a new function | ✅ |
| Change function body (same signature) | ✅ |
| Add a new field to a struct (with default) | ✅ |
| Remove a field from a struct or resource | ❌ |
| Change a field type | ❌ |
| Remove a public function | ❌ |
| Change a function signature | ❌ |
| Add a field to a resource | ❌ (resource storage incompatible) |

Any forbidden change requires deploying under a **new contract name** — existing storage under the old name is abandoned.

## Upgrade Checklist

Before running `flow project deploy` on an existing contract:

```
[ ] flow project deploy --update --dry-run  (check for rejection before submitting)
[ ] All changed function signatures are backward-compatible
[ ] No struct/resource fields removed or retyped
[ ] New fields on structs have default values in init()
[ ] Tests pass against the upgraded contract on emulator
[ ] Testnet deploy verified before mainnet
```

## New Contract Name Strategy

When a resource schema change is unavoidable:

1. Deploy `MyContractV2` alongside `MyContract` (do not remove the old one).
2. Write a migration transaction that reads resources from the old path, transforms them, and stores under the new path.
3. Give users a migration window — document the cutoff block height.
4. After migration window closes, stop referencing `MyContract` in new transactions.

```cadence
transaction() {
    prepare(signer: auth(LoadValue, SaveValue) &Account) {
        // Load old resource (removes it from storage)
        let old <- signer.storage.load<@MyContract.OldResource>(from: /storage/myResource)
            ?? panic("nothing to migrate")

        // Transform and save under new contract type
        let new <- MyContractV2.wrap(legacy: <- old)
        signer.storage.save(<-new, to: /storage/myResourceV2)
    }
}
```

## Testnet Validation Before Mainnet

Always deploy to testnet first and run the full post-deploy checklist:

```bash
flow project deploy --network testnet

# Smoke test: read initialized state
flow scripts execute cadence/scripts/GetState.cdc --network testnet

# Write test: confirm a transaction seals
flow transactions send cadence/transactions/Ping.cdc --network testnet --signer testnet-account

# Verify round-trip
flow scripts execute cadence/scripts/GetState.cdc --network testnet
```

Only promote to mainnet after all three steps pass.

## Rollback

Cadence has no rollback. Once a contract is deployed to mainnet it cannot be removed, only updated (within the allowed changes above).

Mitigation strategies:
- **Admin pause function**: include an `access(Admin) fun pause()` that gates all state-mutating functions behind a boolean. Deploy with `paused = false`. If a bug is found, call pause to stop damage while a fix is prepared.
- **Emergency contact**: document an on-call address that holds the admin capability.

```cadence
access(all) resource Admin {
    access(all) fun pause() {
        MyContract.paused = true
    }
    access(all) fun unpause() {
        MyContract.paused = false
    }
}

access(all) fun assertNotPaused() {
    assert(!MyContract.paused, message: "contract is paused")
}
```

Add `assertNotPaused()` as the first line of every state-mutating function.

## Multi-Contract Coordinated Deploy

When deploying multiple interdependent contracts, order matters — dependencies must be deployed first.

```json
"deployments": {
  "testnet": {
    "testnet-account": ["FungibleToken", "FlowToken", "MyToken", "MyDEX"]
  }
}
```

`flow project deploy` resolves this order automatically from the import graph. If a contract fails mid-deploy, the remaining contracts are not deployed — fix the error and re-run. Partial deploys do not need manual cleanup because the failed contract simply isn't on-chain yet.
