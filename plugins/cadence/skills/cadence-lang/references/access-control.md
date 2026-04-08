# Cadence Access Control

## Core Philosophy: Secure by Default
Default to private, explicitly grant access. All fields and functions start restrictive.

## Access Modifier Hierarchy (Most to Least Restrictive)

1. `access(self)` — Private to current scope only
2. `access(contract)` — Visible within declaring contract only
3. `access(account)` — Visible to all contracts in the same account
4. `access(Entitlement)` — Requires specific entitlement (see [entitlements.md](entitlements.md))
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

### Rule 3: Use Entitlements for Privileged Operations
Any function that modifies state or performs a privileged action must use entitlements, not `access(all)`. See [entitlements.md](entitlements.md) for declaration syntax, sets, and mappings.

```cadence
access(Admin) fun updateSettings(newConfig: Config) { }
access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} { }
```

### Rule 4: Protect Composite-Typed Fields
Resources, structs, and capabilities stored as fields MUST be `access(self)` — even as `let` constants. The underlying object remains mutable through its functions.

```cadence
// ❌ CRITICAL: Anyone can copy this capability
access(all) let adminCapability: Capability<&Admin>

// ✅ CORRECT
access(self) let adminCapability: Capability<&Admin>
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

## Checklist
- [ ] All fields use `access(self)` or `access(contract)` unless explicitly needed
- [ ] Composite-typed fields (resources, structs, capabilities) are always `access(self)`
- [ ] View functions use `access(all)` appropriately
- [ ] Privileged operations use entitlements (see [entitlements.md](entitlements.md))
- [ ] No secrets stored in any access level fields
- [ ] Capabilities only expose non-entitled reference types publicly
