# Flow Development Workflow

## Development Sequence

### Stage 1: Local Development
```bash
flow emulator          # Start emulator
flow project deploy    # Deploy contracts
flow test              # Run tests
```

### Stage 2: Frontend Integration (Emulator)
Configure FCL for emulator → test auth flow → test transactions → verify error handling

### Stage 3: Testnet Deployment
```bash
flow project deploy --network=testnet --signer testnet-deployer
```

### Stage 4: Frontend Integration (Testnet)
Switch FCL to testnet → verify addresses → test all user flows end-to-end

## Deployment Verification

### Post-Deployment Checks
```bash
flow scripts execute cadence/scripts/verify-deployment.cdc
```

### Verification Script
```cadence
import MyContract from 0xYOUR_ADDRESS

access(all) fun main(): {String: String} {
    let result: {String: String} = {}
    result["StoragePath"] = MyContract.CollectionStoragePath.toString()
    let collection <- MyContract.createEmptyCollection()
    result["createEmptyCollection"] = "OK"
    destroy collection
    return result
}
```

## Debugging Methodology

### Iterative Problem Solving
1. Reference standard contracts — compare against deployed Flow contracts
2. Check official patterns
3. Fix one error at a time
4. Test after each change

### Smallest Test Case Principle
When a transaction fails: reduce scope, simplify arguments, minimize Cadence code, isolate the problem.

### Error Resolution

| Error | Check | Solution |
|-------|-------|----------|
| Computation Limit Exceeded | Loop iterations, string parsing | See optimization below |
| Authorization Error | `prepare()` entitlements | Add missing `auth()` capabilities |
| Unknown Member | Contract deployed? Member public? | Verify deployment, check access |
| Transaction Decode Failed | FCL network, import addresses | Align FCL with deployment |
| Cannot Update Contract | Changes to `init()` or struct fields | Deploy new version (V2) |

## Gas Optimization

### Move Constants Outside Loops
```cadence
// ❌ Parse in every iteration
while i < 250 { let parts = trait.split(separator: ":") }

// ✅ Parse once
let parts = trait.split(separator: ":")
while i < 250 { /* use parts */ }
```

### Use Accumulative Logic
Calculate total effect instead of iterating each step.

### Remove Logging in Production
Use events for critical actions only — `log()` in loops is expensive.

### Process in Chunks
```cadence
access(all) fun evolvePartial(maxSteps: UInt64) {
    let elapsed = calculateElapsedSteps()
    let toProcess = elapsed < maxSteps ? elapsed : maxSteps
    processSteps(toProcess)
}
```

## Contract Updates & Versioning

### Safe Updates
```bash
flow project deploy --network=testnet --update
```
- Add new functions ✅
- Modify function logic ✅
- Add new contract-level fields ✅

### Requires New Version (V2)
- Changing resource/struct field definitions ❌
- Modifying `init()` signature ❌
- Removing/renaming functions ❌
- Changing event definitions ❌

### Lazy Initialization for New Fields
```cadence
access(all) var newField: UFix64?  // Optional, didn't exist in original init
access(all) fun ensureNewFieldInitialized() {
    if self.newField == nil { self.newField = 10.0 }
}
```

## Testnet Validation Checklist

### Functional
- [ ] All user flows work end-to-end
- [ ] Edge cases handled, error messages clear

### Integration
- [ ] Standard contract interactions work
- [ ] FCL integration stable, auth works across wallets

### Performance
- [ ] No gas limit errors
- [ ] Batch operations tested

### Security
- [ ] Access control enforced
- [ ] Capabilities properly restricted
- [ ] No exposed admin functions

### Deployment Preparation
- [ ] Mainnet flow.json ready with correct addresses
- [ ] Signer account funded
- [ ] FCL config updated for mainnet
- [ ] Environment variables set
- [ ] Rollback plan documented

## Essential Commands

```bash
# Development
flow init
flow emulator
flow project deploy
flow project deploy --network=testnet --signer testnet-deployer

# Testing
flow test
flow scripts execute <script>
flow transactions send <tx>
flow config validate

# Network
flow config set env testnet
flow accounts get <address>
flow dependencies install
```

## Documentation Sources
- Flow Standard Contracts: github.com/onflow/flow-nft, flow-ft, flow-core-contracts
- Official Docs: developers.flow.com
- Cadence Reference: cadence-lang.org
- FCL Docs: docs.onflow.org/fcl/
