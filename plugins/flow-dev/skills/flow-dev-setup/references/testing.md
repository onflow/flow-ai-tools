# Flow Testing Framework

The Flow CLI includes a Cadence-native testing framework. Tests are written in Cadence and run with `flow test`.

## Prerequisites

- Flow CLI installed (see [flow-cli.md](flow-cli.md))
- A project initialized with `flow init`

## Test File Convention

Test files must end with `_test.cdc` and live in `cadence/tests/`:

```
cadence/
  tests/
    MyContract_test.cdc
```

## Testing Aliases

Contracts deployed in tests need a `testing` alias in `flow.json`:

```json
"contracts": {
  "Counter": {
    "source": "cadence/contracts/Counter.cdc",
    "aliases": {
      "testing": "0x0000000000000007"
    }
  }
}
```

Valid testing addresses: `0x0000000000000005` through `0x000000000000000E`.

## Writing Tests

```cadence
import Test
import "Counter"

access(all) let account = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "Counter",
        path: "../contracts/Counter.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testIncrement() {
    let result = Test.executeScript(code: "import Counter from 0x0000000000000007; access(all) fun main(): Int { return Counter.count }", args: [])
    Test.expect(result, Test.beSucceeded())
    Test.assertEqual(0, result.returnValue! as! Int)
}
```

## Test Standard Library

| Function | Purpose |
|----------|---------|
| `Test.createAccount()` | Create a test account |
| `Test.deployContract(name, path, arguments)` | Deploy a contract |
| `Test.executeScript(code, args)` | Run an inline script |
| `Test.expect(result, matcher)` | Assert with matcher |
| `Test.assertEqual(expected, actual)` | Assert equality |
| `Test.beNil()` | Match nil values |
| `Test.beEmpty()` | Match empty collections |
| `Test.contain(element)` | Match collection containment |
| `Test.beSucceeded()` | Match successful execution |

## Running Tests

```bash
# Run all tests
flow test

# Run a specific test by name
flow test --name testIncrement

# Randomize test order
flow test --random

# Reproducible random order
flow test --random --seed=42
```

## Code Coverage

```bash
# Enable coverage
flow test --cover

# Scope to contracts only (excludes test code)
flow test --cover --covercode=contracts

# Output coverage report
flow test --cover --coverprofile="coverage.json"    # JSON format
flow test --cover --coverprofile="coverage.lcov"    # LCOV format
```

## Fork Testing

Test against real network state:

```bash
# Fork from mainnet
flow test --fork mainnet

# Fork from testnet
flow test --fork testnet

# Pin to a specific block height
flow test --fork mainnet --fork-height 85432100

# Custom fork host
flow test --fork --fork-host access.mainnet.nodes.onflow.org:9000
```

You can also use a pragma in test files:
```cadence
#test_fork(network: "mainnet", height: nil)
```

## Common Mistakes That Silently Drop Tests

These errors cause the framework to skip tests without a clear error message — the test count in output will be less than the number of `test*` functions in the file.

### ❌ `Test.newBlockchain()` — does not exist
```cadence
// WRONG — API does not exist; compile fails silently
access(all) let blockchain = Test.newBlockchain()
```
```cadence
// CORRECT — use Test functions directly at module level
access(all) let account = Test.createAccount()
```

### ❌ Multi-line inline Cadence strings (heredocs)
Cadence does not support triple-quoted strings. Embedding long Cadence code inline as a string literal will fail to parse.
```cadence
// WRONG — Cadence has no triple-quote syntax
let code = """
    access(all) fun main(): Int { return 1 }
"""
```
```cadence
// CORRECT — use Test.readFile() for transactions and scripts
let result = Test.executeTransaction(
    code: Test.readFile("../transactions/Mint.cdc"),
    args: [],
    signers: [signer]
)
```
If you must inline a script, keep it to a single short line:
```cadence
let result = Test.executeScript(code: "access(all) fun main(): Int { return 1 }", args: [])
```

### ❌ Wrong module-level variable type for accounts
`Test.createAccount()` returns an opaque value — store the `.address` if you only need the address later:
```cadence
// CORRECT — store full account for use as signer
access(all) let owner = Test.createAccount()

// CORRECT — store only address if you don't need to sign
access(all) let ownerAddr: Address = Test.createAccount().address
```

### Verification rule — count must match
After writing N test functions, `flow test` output must list exactly N test names.
If you wrote 8 tests and only 3 appear, the file has a parse or check error — run:
```bash
flow test --name testSpecificName   # isolate which test fails to load
```
Do not report a test suite as complete until the reported count equals the written count.

## Documentation

- Official docs: https://developers.flow.com/tools/flow-cli/tests
