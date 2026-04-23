# Setup and Test Basics

Targets Cadence 1.0 and the Flow CLI testing framework shipped with recent Flow CLI releases.

## Project Layout

A conventional Flow project places test files next to contracts, transactions, and scripts under the `cadence/` directory. Tests themselves live in `cadence/tests/` by convention, but any path works — `flow test` walks the filesystem to discover test files wherever you put them.

```
my-project/
├── cadence/
│   ├── contracts/
│   │   └── Counter.cdc
│   ├── transactions/
│   │   └── increment.cdc
│   ├── scripts/
│   │   └── get_count.cdc
│   └── tests/
│       └── Counter_test.cdc
└── flow.json
```

Keeping tests grouped under `cadence/tests/` makes the layout predictable and keeps relative paths to sources short. A nested layout (for example `cadence/tests/unit/` and `cadence/tests/integration/`) also works — `flow test` discovers files recursively and the grouping you choose is purely for your own organisation.

The `flow.json` manifest at the project root ties everything together: it names contracts, points at their source files, and declares the aliases that tests use to resolve imports. A project does not need a separate test manifest — the same `flow.json` is consulted during `flow test` and during `flow project deploy`.

## flow.json Aliases for Tests

Every contract that a test imports needs a `testing` alias under the contract's `aliases` block in `flow.json`. Without the alias, `flow test` cannot resolve the import and fails before running any test.

```json
{
  "contracts": {
    "Counter": {
      "source": "cadence/contracts/Counter.cdc",
      "aliases": {
        "testing": "0x0000000000000007"
      }
    }
  }
}
```

The testing framework reserves the address range `0x0000000000000005` through `0x000000000000000E` for user contract aliases. Assign each contract a unique address in that range — collisions cause deployment conflicts in the test environment.

Standard library contracts such as `FungibleToken`, `NonFungibleToken`, `MetadataViews`, and `ViewResolver` get implicit testing aliases. You do not need to add them to `flow.json` aliases to import them from a test file — the framework deploys the standard contracts into the test blockchain automatically when they are imported.

If a contract your project depends on was installed via `flow dependencies install`, its generated `flow.json` entry typically already includes network aliases (`emulator`, `testnet`, `mainnet`) but not `testing`. Add the `testing` alias manually the first time you import the dependency from a test.

A multi-contract project assigns each of its own contracts a distinct testing address:

```json
{
  "contracts": {
    "Counter": {
      "source": "cadence/contracts/Counter.cdc",
      "aliases": {
        "testing": "0x0000000000000007"
      }
    },
    "CounterRegistry": {
      "source": "cadence/contracts/CounterRegistry.cdc",
      "aliases": {
        "testing": "0x0000000000000008"
      }
    }
  }
}
```

The addresses have no meaning beyond identity — the framework uses them internally to route imports. Pick them once and leave them alone.

## File Naming

Test files must end with `_test.cdc`. `flow test` uses this suffix to auto-discover test files — a file named `Counter.cdc` in `cadence/tests/` is ignored, while `Counter_test.cdc` is picked up.

You can pass a specific path to `flow test` to run a single file, or run `flow test` with no path to execute every `_test.cdc` file in the project. The discovery walk recurses into subdirectories, so nested test folders are fine.

Group related tests in one file rather than sharding them across many: every file pays the fixed cost of `setup()` (deploying contracts, creating accounts), so consolidating tests that share a fixture is usually faster and easier to reason about than splitting them.

## Test File Lifecycle

A test file can define up to five lifecycle functions. All are optional, but a file is only useful if it defines at least one `testXxx` function.

- `setup()` — runs once before any test in the file. Typical work: create accounts, deploy contracts under test.
- `beforeEach()` — runs before every `testXxx` function. Typical work: reset mutable state established in `setup()`, or re-seed a clean fixture.
- `afterEach()` — runs after every `testXxx` function. Typical work: teardown or invariant checks.
- `testXxx()` — a test case. The name must begin with `test`. Takes no parameters and returns no value. Each `testXxx` is reported independently.
- `tearDown()` — runs once after all tests in the file have finished. Typical work: final cleanup.

Lifecycle functions run in the order shown: `setup` → (`beforeEach` → `testXxx` → `afterEach`)* → `tearDown`. Errors in `setup` or `beforeEach` prevent the associated tests from running but are not themselves reported as test failures unless you assert on them explicitly.

Test functions are discovered by name. Any top-level `access(all) fun` whose name begins with `test` is treated as a test case — `testDepositIncreasesBalance` is a test, `verifyDeposit` is not. Helper functions can be named anything else and called from tests; they are simply not invoked by the framework on their own.

Prefer a few well-named tests over many tiny ones. A test named `testWithdrawRejectsZeroAmount` documents its intent far better than a generic `testWithdraw1`, and failure messages in the CLI output include the test name verbatim.

A lifecycle skeleton looks like this:

```cadence
import Test

access(all) fun setup() {
    // Deploy contracts and build the shared fixture.
}

access(all) fun beforeEach() {
    // Restore state that individual tests are allowed to mutate.
}

access(all) fun testFoo() { /* ... */ }
access(all) fun testBar() { /* ... */ }

access(all) fun afterEach() {
    // Optional: assert invariants or emit cleanup logs.
}

access(all) fun tearDown() {
    // Final teardown, runs once.
}
```

## Imports

Every test file starts with `import Test`. The `Test` contract is built into Cadence, so you do not need to add it to `flow.json` — the import just brings its types and helpers into scope. Without this line, references like `Test.createAccount` and `Test.expect` will not resolve.

Contracts under test are imported by name using the string-import form:

```cadence
import "Counter"
```

The `import` statement resolves against the `testing` alias when the test file is parsed. Calls into the contract (from `executeScript` or `executeTransaction`) only work after `Test.deployContract` has run, typically in `setup()`.

To load a Cadence source file from disk without deploying it (for example, a script or a transaction file to run through the blockchain), use `Test.readFile`:

```cadence
let source = Test.readFile("../scripts/get_count.cdc")
```

The path is relative to the test file's own location, not the project root. A test at `cadence/tests/Counter_test.cdc` loading `cadence/scripts/get_count.cdc` uses the path `../scripts/get_count.cdc`.

Once a contract is deployed via `deployContract`, you can `import "ContractName"` from the test file itself and call its public API directly — useful for assertions that inspect type-level state without round-tripping through a script.

## Minimal Example

```cadence
import Test

access(all) let admin = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "Counter",
        path: "../contracts/Counter.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testInitialCountIsZero() {
    let script = Test.readFile("../scripts/get_count.cdc")
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    Test.assertEqual(0 as Int, result.returnValue! as! Int)
}
```

A few things to notice. The admin account is declared as a file-level `access(all) let` binding so every lifecycle function in the file can reach it. `setup()` deploys the contract and asserts the deployment error is `nil` — without this assertion a silent deployment failure would surface later as a confusing script error. The `testInitialCountIsZero` test loads a script from disk, runs it against the blockchain, checks the execution succeeded, and then unwraps the return value with a forced cast.

The value returned by `Test.createAccount()` has type `Test.TestAccount`. Use that type name when you need to declare a typed parameter or field — for example, a helper that accepts an account argument should be written `fun fund(account: Test.TestAccount)` rather than the chain-runtime `Account` type.

`TestAccount` exposes the `address`, `publicKey`, and other fields needed to construct transactions and scripts during a test run.

## Running the Example

```
flow test cadence/tests/Counter_test.cdc
```

The CLI prints per-test results and a summary line of the form `X tests, Y passed, Z failed`. Failures include the file, the test function name, and the failing assertion's message. Omitting the path runs every `_test.cdc` file in the project.

A passing run of the example above looks roughly like:

```
Test results: "cadence/tests/Counter_test.cdc"
- PASS: testInitialCountIsZero
1 tests, 1 passed, 0 failed
```

A failing assertion shows the matcher's rendered message, so descriptive matchers (such as `Test.beSucceeded` versus a raw equality check on a transaction result) produce far more useful failure output.

Use `flow test --cover` to enable coverage reporting; the framework tracks which lines of your contracts executed during tests and prints a percentage per contract. Coverage is off by default because it slows test runs — turn it on in CI and leave it off during the tight local edit-test loop.

## Common Setup Pitfalls

- Forgetting the `testing` alias in `flow.json`. The test fails at import resolution with a message like "cannot find contract" before any lifecycle function runs. Add the contract to `aliases.testing` with an address in the `0x5`–`0xE` range.
- Paths passed to `Test.readFile` and `Test.deployContract` are relative to the test file itself, not to the project root. From `cadence/tests/Counter_test.cdc`, the contract lives at `../contracts/Counter.cdc`. Running `flow test` from a different working directory does not change this.
- `setup()` and `beforeEach()` errors are not automatically reported as test failures. Always capture the result of `deployContract` (and similar operations) and assert with `Test.expect(err, Test.beNil())` so a broken fixture surfaces as a clear failure rather than a cascade of unrelated test errors later.
- Not resetting state between tests — mutations from one test leak into the next. Either use `beforeEach()` to restore state, or call `Test.reset(to: setupHeight)` to rewind to a clean snapshot.
- Naming a test function something other than `testXxx`. The framework silently skips it. If a "test" never seems to run, check that its name starts with the literal prefix `test`.
- Mixing up file-level `let` bindings with per-test state. Anything declared `access(all) let` at the top of the file is initialized once when the file is loaded and shared by every test. For per-test scratch state, declare locals inside the `testXxx` function instead.
