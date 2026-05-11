# Cadence Smart Contract Audit Checklist

## Security Vulnerabilities

### Access Control
- Are privileged operations behind entitlements (not `access(all)`)?
- Are `auth(...) &Account` references never passed to contract functions?
- Are capabilities stored in `access(self)` fields (never public)?
- Are capabilities in arrays/dictionaries also `access(self)`?
- Do public functions only perform safe operations (view, deposit)?

### Resource Safety
- Are all resources explicitly moved or destroyed in every code path?
- Is `vault.balance == 0.0` asserted before destroying vaults after transfers?
- Are resources handled before any `panic()` calls?
- Do conditional branches all handle resources?

### Capability Security
- Are public capabilities issued without entitlements?
- Are entitled capabilities stored privately (never published)?
- Are pre-existing capabilities checked before issuance to avoid proliferation? (Principle of Least Authority: issue minimum entitlements needed)
- Are controllers stored for later revocation?
- Is `borrow()` used with optional handling (never force unwrap `!`)?

### Struct Exploitation
- Do struct initializers avoid modifying contract state?
- Do struct initializers avoid emitting events?
- Can anyone construct a struct to perform authorized functions?

### Time-of-Check to Time-of-Use
- Storage references work like symbolic links — the stored value may be swapped between check and use
- Ensure the same value is checked and used, or that it cannot be replaced

### Checks-Effects-Interactions Pattern
- Are state changes made before external calls?
- Are inputs validated before any effects?

### Emergency Controls
- Is there an option to disable critical functionality in emergencies?
- Can admin pause/unpause the contract?

### Transactions
- Is transaction code reviewed with the same rigor as contracts?
- Does `prepare` only access account storage and capabilities (no business logic)?
- Is all business logic in `execute` (not `prepare`)?
- Are requested entitlements minimal for the operation (Principle of Least Authority)?
- Are `pre`/`post` conditions used where they add safety guarantees?
- Does each `pre`/`post` condition evaluate to a single boolean expression (no side effects, no assignments, no control flow inside a condition)?

## Bug Detection

### Nil Dereference
- Replace `if opt != nil { ... opt! ... }` with `if let value = opt { ... }`
- Never force unwrap without prior validation

### Infinite Loops
- Could any loop cause DoS if given unexpected input?
- Are loop bounds checked?

### Number Operations
- All number type operations perform under/overflow checks (e.g., `UInt8.max + 1` panics)
- Number type conversion functions panic if out of range
- Always multiply before dividing (unless multiplication could overflow)

### Input Validation
- Are all function parameters validated with pre-conditions?
- Are results verified with post-conditions?
- Are external addresses/capabilities validated before use?

## Code Quality

### Documentation
- Is there file-level documentation?
- Are all public functions documented?
- Is non-obvious logic commented with the "why"?
- Do comments explain intent, not just what the code does?

### Naming
- Use descriptive names (not abbreviations): `recipientAddress` not `addr`
- Use plural names for arrays/dictionaries: `accounts` not `account`
- Does the function name match its logic?
- Use argument labels for functions with many parameters

### Access Modifiers
- Can the field be `let` instead of `var`?
- Can the function be `view`?
- Can the field/function have more restrictive access?
  - `access(self)` for internal state
  - `access(contract)` for contract helpers
  - Entitled access for privileged operations
  - `access(all)` only for genuinely public APIs

### Patterns and Anti-Patterns
- Follow Cadence design patterns (named constants, report structs, borrow over load/save)
- Avoid anti-patterns (public admin creation, state modification in struct init, public capability fields)
- No debug code, TODOs, or commented-out logic in critical paths
- Use constants instead of magic numbers (use built-in like `UInt128.max` where possible)

### Expressions and Logic
- Expressions passed to logical/comparison operators should not have side-effects
- Use ternary expressions to simplify branching where possible
- No `if-else` chains that could be ternaries

### Error Messages
- Are panic messages descriptive with context?
- Do they include interpolated values (`\(amount)`, `\(id)`)?
- Do pre/post condition messages explain what went wrong?

## DeFi-Specific Concerns

### Oracle and Price Manipulation
- Don't use spot price from an AMM as an oracle
- Don't trade on AMMs without a price target from off-chain or an oracle
- Use sanity checks to prevent oracle/price manipulation

### Accounting
- Don't mix internal accounting with actual balances
- Don't rely on raw token balance of a contract to determine earnings
- Contracts that recover directly-sent assets can mess up share price functions

### External Contracts
- Check assumptions about what other contracts do and return
- If your contract handles token approvals, don't make arbitrary calls from user input

### Token Transfers
- Verify complete transfers (assert residual balance == 0.0)
- Size withdrawals by sink capacity when immediately depositing

## Cross-VM and DeFi Advanced Checks

### Stuck State / Missing Emergency Exit
- Does any `burnCallback` or `closeCallback` assert against an external system (EVM vault, bridge, oracle)?
- If that external system fails permanently, can the vault ever be closed? Is there an admin emergency exit with a grace period (e.g., >7 days stuck → force close)?
- Pattern: closing a vault asserts a pending operation is nil, but cancelling that operation also calls EVM → if EVM is paused, both close and cancel fail, funds are permanently trapped.

### Cross-VM Timing Races
- In deferred operations (request phase → claim phase): is the timelock or deadline captured once at request time and never re-queried?
- If the external system changes its timelock after the request but before the claim, the stored timestamp is stale — claim executes too early (EVM reverts) or too late (user waits unnecessarily).
- Fix: re-query the current external timelock at claim time and use `max(storedTimestamp, currentTime + currentTimelock)`.

### Lingering EVM Approvals
- After completing an EVM-side redemption or transfer, is the ERC20 approval (`approve(spender, amount)`) explicitly revoked?
- ERC4626 `redeem()` does not consume ERC20 allowance — an unrewoked approval persists. If the user later deposits more shares and the spender COA is compromised, unauthorized redemption becomes possible.
- Fix: send a zero-approval call immediately after a successful EVM redemption completes.

### EVM Call Result Not Validated
- Every `coa.call()` and `EVM.dryCall()` returns `EVM.Result`. Is `result.status == EVM.Status.successful` checked before trusting `result.data`?
- Unchecked EVM failure = silent state divergence between Cadence and EVM.

### Bridge Precision Loss (UFix64 ↔ uint256)
- UFix64 has 8 decimal places. EVM ERC20 tokens typically use 18. Conversion without explicit ×10^10 scaling truncates or inflates amounts.
- Dust accumulates across calls into exploitable value at volume.
- Fix: explicit scaling on every Cadence↔EVM conversion. Round against the user (floor on deposit, ceiling on withdrawal).
- HackenProof Flow bug bounty classifies this as Critical.

### Fixed-Point Overflow in AMM Liquidity (Cetus-class)
- Cetus DEX (Sui, May 2025, $223M): unchecked bit-shift in liquidity delta math. Same pattern applies to any Cadence AMM with custom fixed-point scaling.
- Does any bit-shift or scaling operation have a correct bit-width guard (not just value bounds)?
- Can a flash-add max liquidity + immediate remove expose a divergence between deposit requirement and withdrawal entitlement?

### access(account) Co-Deploy Escalation
- `access(account)` exposes fields to ALL contracts on the same Flow account.
- A future contract upgrade on that account (or compromised key) gains full read/write access to all `access(account)` state across every co-deployed contract.
- Dec 27, 2025 exploit deployed ~40 malicious contracts to amplify this vector.
- Audit: enumerate all `access(account)` fields. Verify all contracts on that account are equally trusted. Verify upgrade requires multi-sig.

### Burnable.burnCallback() Griefing via External Token
- Any protocol that accepts arbitrary `FungibleToken` vaults and destroys them can be griefed by a token whose `burnCallback()` panics or executes unexpected state changes inside the protocol's own transaction.
- Is `Burner.burn(<-vault)` called on vaults received from external sources without type verification?
- Fix: only destroy vaults of explicitly allowlisted token types. Never call `Burner.burn()` on caller-supplied vaults without type verification.

### Cross-VM Bridge as Exploit Exit — No Rate Limit
- Dec 27, 2025 ($3.9M): attacker minted counterfeit FLOW → bridged to Flow EVM → bridged to Ethereum before validators halted. All in one block sequence.
- Does the protocol interact with the EVM bridge? Is there a per-block or per-transaction volume cap? Is there an admin pause callable within seconds?
- Any mint/inflate exploit can exit via the bridge faster than governance can react.

### Contract Initializer Argument Type Smuggling
- Dec 27, 2025: `account.contracts.add()` accepted arguments where calling context treated them as value types but initializer treated them as resources → resources copied instead of moved → infinite mint. Patched in Cadence v1.8.9.
- Audit: any deployment/upgrade transaction that passes attachments, `PublicKey` wrappers, or nested composites as initializer arguments. Verify static type == dynamic type for all complex arguments.

### Use-After-Free via Retained Reference After Resource Destroy
- Halborn 2021: Cadence allowed method calls on a resource reference after the resource was destroyed. Runtime-patched.
- In multi-contract systems: if contract A holds a borrowed reference from contract B's storage, and B destroys the resource via a separate path, the reference in A is stale.
- Verify no live cross-contract reference exists to a resource before it is destroyed.

## Optimization

### Storage Operations
- Avoid unnecessary `load` and `save` — use `borrow` for in-place mutations
- Prefer in-place mutations over copies for arrays and dictionaries
- Check storage path before saving (avoid accidental overwrites)

### Copies
- Avoid copying large data structures (arrays, dictionaries)
- Use references instead of loading resources when possible

### Gas Efficiency
- Move constants outside loops
- Use accumulative logic instead of step-by-step iteration
- Remove `log()` calls from production code
- Process large operations in chunks

## Cadence-Specific Gotchas

- Cadence does NOT have `defer`
- Cadence does NOT have if-expressions (`if` blocks cannot be used as expressions that return a value); use the ternary operator (`condition ? a : b`) instead
- Fields cannot have initial values in declarations — must initialize in `init()`
- Owning a value (struct/resource) gives full access to all methods regardless of entitlements — entitlements only gate access through references
- Reserved keywords cannot be used as identifiers (see Cadence language reference)
- Cadence linter should report no issues: `flow cadence lint`

## Audit Report Template

For each finding, document:
1. **Severity**: Critical / High / Medium / Low / Informational
2. **Location**: File, line, function
3. **Description**: What the issue is
4. **Impact**: What could go wrong
5. **Recommendation**: How to fix it
6. **Code**: Before/after examples

## Cross-Skill References for Auditing

When auditing, consult these `cadence-lang` references for the specific rules being checked:
- **Access control** → `access-control.md` and `entitlements.md`
- **Resource handling** → `resources.md`
- **Capability security** → `capabilities.md`
- **Anti-patterns** → `anti-patterns.md`
- **Design patterns** → `design-patterns.md`
- **Pre/post conditions** → `conditions.md`
- **Security rules** → `security-best-practices.md`

For token-specific audits, consult `cadence-tokens` skill → `nft-standards.md`.
