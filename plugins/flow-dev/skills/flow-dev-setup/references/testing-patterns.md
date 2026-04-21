# Flow Testing Patterns

Complements [testing.md](testing.md) with framework selection, adversarial test design, and coverage interpretation.

## CDC Native vs Go/Overflow Decision Tree

```
Requires FlowToken transfers, FlowTransactionScheduler,
RandomConsumer, or any system contract?
  YES → Go/overflow (emulator with real system contracts)
  NO  → CDC native (flow test --cover, pure Cadence sandbox)

Requires 2+ accounts signing the same transaction?
  YES → Go/overflow
  NO  → CDC native (multi-account sequential txs are supported)

Verifying scheduled/delayed execution or commit-reveal?
  YES → Go/overflow only
```

## Adversarial Test Categories

Every contract needs tests in all applicable categories before deploy:

| Category | What to test |
|----------|-------------|
| Privilege escalation | Non-admin calling admin functions; user calling artist-only functions |
| Resource manipulation | Deposit+withdraw cycles; double-spend; force-unwrap paths |
| Arithmetic | UFix64 subtraction below zero; overflow on counters; 100% royalty cut |
| Storage attacks | Overwriting another account's path; claiming capabilities not addressed to caller |
| Loyalty/points farming | Repeated deposit-withdraw cycles inflating score beyond expected ceiling |
| Capability abuse | Using capability after revocation; copying from `access(all)` fields |
| Scheduling attacks | Calling scheduled transaction handlers directly without scheduler entitlement |

## CDC Native — Adversarial Pattern

```cadence
import Test
import "MyContract"

access(all) fun setup() {
    Test.expect(
        Test.deployContract(name: "MyContract", path: "../contracts/MyContract.cdc", arguments: []),
        Test.beNil()
    )
}

access(all) fun testUnauthorizedWithdrawFails() {
    let attacker = Test.createAccount()
    let result = Test.executeTransaction(
        code: "../transactions/Withdraw.cdc",
        args: [],
        signers: [attacker]
    )
    Test.expect(result, Test.beFailed())
}

access(all) fun testLoyaltyFarmingBlocked() {
    let attacker = Test.createAccount()
    // deposit multiple times, withdraw once
    // ...
    let points = Test.executeScript(
        code: "import \"MyContract\"; access(all) fun main(addr: Address): UFix64 { return MyContract.getPoints(addr) }",
        args: [Test.Matcher.any()]
    ).returnValue! as! UFix64
    Test.assert(points <= 10.0, message: "points should not exceed ceiling after farming attempt")
}
```

## Go/Overflow — Integration Test Pattern

Use [overflow](https://github.com/bjartek/overflow) for tests that need system contracts.

```go
import (
    "testing"
    "github.com/bjartek/overflow/v2"
    "github.com/stretchr/testify/assert"
)

func TestEscrowReleasesToSeller(t *testing.T) {
    o, _ := overflow.New(overflow.WithNetwork("testing"))

    o.Tx("transactions/fund_account.cdc").
        SignProposeAndPayAs("service").
        Args(o.Arguments().Account("seller").UFix64(100.0)).
        RunPanic(t)

    o.Tx("transactions/create_escrow.cdc").
        SignProposeAndPayAs("buyer").
        Args(o.Arguments().UFix64("10.0").Account("seller")).
        RunPanic(t)

    sellerBalance := o.ScriptFromFile("scripts/get_flow_balance.cdc").
        Args(o.Arguments().Account("seller")).
        RunReturnsInterface(t)

    assert.Greater(t, sellerBalance.(float64), 100.0)
}

// Test expected to fail — use RunE
func TestUnauthorizedMintFails(t *testing.T) {
    o, _ := overflow.New(overflow.WithNetwork("testing"))
    err := o.Tx("transactions/MintNFT.cdc").
        SignProposeAndPayAs("attacker").
        RunE()
    assert.Error(t, err)
}
```

## Coverage Interpretation

`flow test --cover` output:

| Symbol | Meaning |
|--------|---------|
| ✅ covered | Function called at least once |
| ❌ uncovered | Function never called — write a test |
| ⚠️ partial | Called but some branches (if/else, pre/post) not exercised |

**Known limitation:** `flow test --cover` cannot instrument contracts that import system contracts (`FlowToken`, `FlowTransactionScheduler`, `RandomConsumer`). For these, coverage comes only from Go/overflow tests. Document this gap explicitly — do not attempt workarounds.

## Output Format for Test Results

```
SUITE: <name>
FRAMEWORK: CDC native | Go/overflow
TESTS: <N total> — <N positive> positive, <N adversarial> adversarial
COVERAGE: <N>% — uncovered: <list of function names>
KNOWN GAPS: <functions not coverable due to system contract dependency>

RESULTS:
  ✅ <N> passed
  ❌ <N> failed — <function name>: <reason>

For each adversarial test:
  EXPLOIT TESTED: <finding ID or description>
  EXPECTED: reverts | state unchanged | event not emitted
  RESULT: ✅ blocked | ❌ EXPLOITABLE
```
