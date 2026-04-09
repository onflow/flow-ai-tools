# Safety Rules and Testing

## Critical Rules

### String Imports Only (BLOCKING)
```cadence
import "FungibleToken"     // ✅
import "DeFiActions"        // ✅
import FungibleToken from 0x123  // ❌ COMPILE ERROR
```

### Transaction Layout Order
Write blocks in this order for reviewability: `prepare` → `pre` → `post` → `execute`

### Single Expression in Pre/Post (BLOCKING)
```cadence
// ✅ Single boolean expression
pre { amount > 0.0: "Amount must be positive" }

// ❌ Multiple statements NOT ALLOWED
pre { let isValid = amount > 0.0; isValid: "msg" }
```

### Post-Condition Guards (HIGH)
For restaking: derive `expectedStakeIncrease` from connector quotes:
```cadence
post {
    self.pool.getUserInfo(address: self.userCertificateCap.address)!.stakingAmount
        >= self.startingStake + self.expectedStakeIncrease:
        "Restaked amount below expected"
}
```

### Resource Handling (HIGH)
Always verify complete transfer before destroying:
```cadence
let vault <- source.withdrawAvailable(maxAmount: amount)
sink.depositCapacity(from: &vault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
assert(vault.balance == 0.0, message: "Transfer incomplete: ".concat(vault.balance.toString()))
destroy vault
```

### Capability Validation (HIGH)
```cadence
let pool = poolCap.borrow() ?? panic("Could not access pool \(poolId)")
```

## Medium Priority

### Capacity Checking
```cadence
let available = source.minimumAvailable()
let capacity = sink.minimumCapacity()
assert(available > 0.0, message: "No tokens available")
```

### Type Validation
```cadence
let vaultType = CompositeType(vaultTypeString)
    ?? panic("Invalid vault type: ".concat(vaultTypeString))
```

## Safety Invariants (Do Not Relax)

1. Size withdraws by sink capacity: `withdrawAvailable(maxAmount: sink.minimumCapacity())`
2. Always assert residuals: `vault.balance == 0.0` before `destroy`
3. Use `source.minimumAvailable()` and `sink.minimumCapacity()` instead of manual math
4. Prefer protocol helpers (e.g., `borrowPool(pid:)`) over raw address params
5. Match types: `source.getSourceType() == swapper.inType()`
6. Use a single `uniqueID` across all connectors in one operation
7. Pre/Post blocks contain exactly one boolean expression

## Required Account Entitlements

```cadence
auth(BorrowValue) &Account                          // Read storage
auth(BorrowValue, SaveValue) &Account                // Most transactions
auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account  // Setup
```

## Quick Checklist

- [ ] String imports only
- [ ] Transaction order: prepare → pre → post → execute
- [ ] Post-condition guards outcome
- [ ] Residual vault asserted == 0.0 before destroy
- [ ] Capability validated before use (no force unwrap)
- [ ] Types match across Source → Swapper → Sink chain
- [ ] Single uniqueID for all connectors
- [ ] Minimal account entitlements
- [ ] Descriptive error messages with context

## Testing

### Test Directory Structure
```
tests/
  unit/         # Individual component tests
  integration/  # Full workflow tests (multi-account, multi-contract)
  performance/  # Gas cost, max values
  helpers/      # Shared utilities
```

### Naming Convention
`test[Component][Scenario]` — e.g., `testVaultSourceZeroAmount`, `testZapperTokenOrdering`

### Required Test Matrix
| Component | Zero Amount | Max Amount | Invalid Cap | Inactive Pool |
|-----------|------------|------------|-------------|---------------|
| VaultSource | ✓ | ✓ | ✓ | N/A |
| VaultSink | ✓ | ✓ | ✓ | N/A |
| PoolSink | ✓ | ✓ | ✓ | ✓ |
| SwapSource | ✓ | ✓ | ✓ | ✓ |

### Additional Required Test Cases
- Token ordering edge cases (source type matches / doesn't match token0)
- Capacity limit handling via `depositCapacity()` / `withdrawAvailable()`
- Minimum balance protection (source doesn't over-withdraw)
- Event ordering — verify events emitted in correct sequence

### Integration Tests
Must validate complete workflows: deploy contracts → setup pools → advance time (generate rewards) → execute restake → verify final stake > initial stake.

### Event Validation
```cadence
let events = Test.eventsOfType(Type<DeFiActions.EventType>())
Test.expect(events.length, Test.equal(expectedCount))
```

> **See also:** `cadence-lang` skill → `resources.md` for resource destruction rules, `security-best-practices.md` for capability validation patterns, `conditions.md` for pre/post condition syntax. Use `cadence-audit` skill to review DeFi transactions before deployment.
