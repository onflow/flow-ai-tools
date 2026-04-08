# Cadence Access Control and Entitlements

## Core Philosophy: Secure by Default
Default to private, explicitly grant access. All fields and functions start restrictive.

## Access Modifier Hierarchy (Most to Least Restrictive)

1. `access(self)` — Private to current scope only
2. `access(contract)` — Visible within declaring contract only
3. `access(account)` — Visible to all contracts in the same account
4. `access(Entitlement)` — Requires specific entitlement
5. `access(all)` — Public access (use sparingly)

## Rules

### Rule 1: Default Access Levels
- **Fields**: `access(self)` or `access(contract)` by default
- **Functions**: `access(self)` or `access(contract)` by default

```cadence
// ✅ CORRECT
access(contract) var balance: UFix64
access(self) fun updateInternalState() { }

// ❌ WRONG
access(all) var balance: UFix64
```

### Rule 2: When to Use `access(all)`
Only for: view functions, public interfaces (deposit, transfer), public getters.

```cadence
access(all) view fun getBalance(): UFix64 { return self.balance }
access(all) fun deposit(from: @{FungibleToken.Vault}) { }

// ❌ WRONG: Admin function made public
access(all) fun setBalance(newBalance: UFix64) { self.balance = newBalance }
```

### Rule 3: Entitlements for Privileged Access

Entitlement names should be a verb (what it grants) or noun (who should have it), capitalized.

```cadence
access(all) entitlement Admin
access(all) entitlement Withdraw
access(all) entitlement Mint

access(Admin) fun updateSettings(newConfig: Config) { }
access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} { }
```

### Rule 4: Mixed-Access Resources
Use entitlements to separate public and privileged operations:

```cadence
access(all) resource Vault {
    access(self) var balance: UFix64
    access(all) view fun getBalance(): UFix64 { return self.balance }
    access(all) fun deposit(from: @{FungibleToken.Vault}) { /* ... */ }
    access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} { /* ... */ }
    access(Admin) fun forceSetBalance(newBalance: UFix64) { self.balance = newBalance }
}
```

### Rule 5: Built-in Mutability Entitlements
- `Insert` — Add elements
- `Remove` — Delete elements
- `Mutate` — Both insert and remove

```cadence
access(Insert) fun addItem(_ item: @NFT) { }
access(Remove) fun removeItem(id: UInt64): @NFT { }
access(Mutate) fun replaceItem(id: UInt64, with: @NFT): @NFT { }
```

## Entitlement Combinators

```cadence
// Conjunction (requires ALL)
access(Admin, Withdraw) fun adminWithdraw(): @{FungibleToken.Vault} { }

// Disjunction (requires ANY)
access(Admin | Owner) fun privilegedAction() { }
```

## Critical Security Warnings

### Warning 1: Public Functions Are Completely Open
`access(all)` on a resource with a public capability means **anyone** can call it.

### Warning 2: Private ≠ Secret
`access(self)` controls programmatic access, NOT data visibility. All account storage is publicly readable on-chain. **Never store secrets in account storage.**

### Warning 3: Accidental Exposure in Capabilities
```cadence
// ❌ WRONG: Exposing entitled access publicly
let vaultCap = account.capabilities.storage
    .issue<auth(Admin, Withdraw) &Vault>(/storage/vault)
account.capabilities.publish(vaultCap, at: /public/vault)

// ✅ CORRECT: Non-entitled reference
let vaultCap = account.capabilities.storage
    .issue<&Vault>(/storage/vault)
account.capabilities.publish(vaultCap, at: /public/vault)
```

## Common Patterns

### Public View + Entitled Mutate
```cadence
access(all) resource Counter {
    access(self) var count: UInt64
    access(all) view fun getCount(): UInt64 { return self.count }
    access(Increment) fun increment() { self.count = self.count + 1 }
    access(Admin) fun reset() { self.count = 0 }
}
```

### Interface with Entitlements
```cadence
access(all) resource interface VaultInterface {
    access(all) view fun getBalance(): UFix64
    access(Deposit) fun deposit(from: @{FungibleToken.Vault})
    access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault}
}
```

### Admin Resource with Multiple Entitlements
```cadence
access(all) entitlement Configure
access(all) entitlement Pause

access(all) resource ProtocolManager {
    access(self) var isPaused: Bool
    access(Pause) fun pause() { self.isPaused = true }
    access(Pause) fun unpause() { self.isPaused = false }
    access(Configure) fun updateConfig(newConfig: Config) { self.config = newConfig }
    access(Admin) fun emergencyShutdown() { /* ... */ }
}
```

## Checklist
- [ ] All fields use `access(self)` or `access(contract)` unless explicitly needed
- [ ] View functions use `access(all)` appropriately
- [ ] Privileged operations use entitlements
- [ ] No secrets stored in any access level fields
- [ ] Capabilities only expose intended reference types
- [ ] Entitlements are defined at contract level before use
