# Cadence Anti-Patterns

## Anti-Pattern 1: Fully Authorized Account References as Parameters

**Problem**: Passing `auth(...) &Account` to functions grants dangerous privileges.

```cadence
// ❌ CRITICAL: Function can do ANYTHING with the account
access(all) fun processAccount(account: auth(Storage) &Account) { }
```

**Why dangerous**: Malicious contract upgrades can steal resources. No revocation possible.

**Fix**: Use capabilities, references, or keep operations in transaction `prepare` blocks.
```cadence
// ✅ Use capabilities
access(all) fun processVault(vaultCap: Capability<auth(Withdraw) &{FungibleToken.Vault}>) { }

// ✅ Use resource-based authentication
access(all) fun adminFunction(badge: &AdminBadge) { }
```

**Exception**: `auth(...) &Account` is acceptable in transaction `prepare` blocks only.

## Anti-Pattern 2: Public Functions and Fields

**Problem**: Unintentionally using `access(all)` exposes internal implementation.

```cadence
// ❌ Everything public
access(all) var internalCounter: UInt64
access(all) fun resetSystem() { self.internalCounter = 0 }  // Anyone can call!
```

**Fix**: Default to private, explicitly make public only what's necessary.
```cadence
// ✅ Restrictive access
access(self) var internalCounter: UInt64
access(all) view fun getCounter(): UInt64 { return self.internalCounter }
access(Admin) fun resetSystem() { self.internalCounter = 0 }
```

**Never make complex fields public** (arrays, dictionaries, resources, capabilities) — even as constants.

## Anti-Pattern 3: Capability-Typed Public Fields

**Problem**: Public capability fields can be copied by anyone.

```cadence
// ❌ Anyone can copy this capability
access(all) let adminCapability: Capability<auth(Admin) &Admin>
access(all) let minterCapabilities: [Capability<&Minter>]
```

**Why dangerous**: Unrestricted copying, privilege escalation, cannot revoke copies.

**Fix**: Store capabilities privately, expose functionality through controlled interfaces.
```cadence
// ✅ Private storage
access(self) let adminCapability: Capability<auth(Admin) &Admin>

access(Admin) fun executeAdminFunction() {
    if let admin = self.adminCapability.borrow() { admin.execute() }
}
```

## Anti-Pattern 4: Public Admin Resource Creation

**Problem**: Public functions that create admin resources allow anyone to become admin.

```cadence
// ❌ Anyone can call this
access(all) fun createAdmin(): @Admin { return <- create Admin() }
```

**Fix**: Create admin in contract `init()` only. Only existing admins can create new admins.
```cadence
// ✅ Admin created in init only
access(all) contract SecureContract {
    access(all) resource Admin {
        access(all) fun createAdmin(): @Admin { return <- create Admin() }
    }
    init() {
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: /storage/admin)
    }
    // NO public creation function
}
```

## Anti-Pattern 5: State Modification in Public Struct Initializers

**Problem**: Anyone can create structs, so initializers that modify contract state allow state corruption.

```cadence
// ❌ CRITICAL: State modification in struct init
access(all) struct NFTData {
    init() {
        VulnerableContract.totalMinted = VulnerableContract.totalMinted + 1  // Uncontrolled!
        VulnerableContract.nextID = VulnerableContract.nextID + 1
        self.id = VulnerableContract.nextID
    }
}
```

**Real-world example**: This exact pattern existed in NBA Top Shot, allowing anyone to exhaust the ID sequence.

**Fix**: Move state modifications to protected resource functions.
```cadence
// ✅ State modification in protected resource
access(all) struct NFTData {
    init(id: UInt64, serialNumber: UInt64) {
        self.id = id
        self.serialNumber = serialNumber
    }
}

access(all) resource Minter {
    access(all) fun mint(): NFTData {
        SecureContract.totalMinted = SecureContract.totalMinted + 1
        return NFTData(id: SecureContract.nextID, serialNumber: SecureContract.totalMinted)
    }
}
```

Similarly, avoid emitting events from struct initializers.

## Anti-Pattern 6: access(account) in Multi-Contract Accounts

**Problem**: `access(account)` grants access to ALL contracts on the same Flow account — not just the declaring contract. A future contract upgrade or compromised key exposes all `access(account)` state.

```cadence
// ❌ Any contract on this account can read/write this field
access(account) var totalSupply: UFix64
access(account) var adminNonce: UInt64
```

**Real-world risk**: Dec 27, 2025 exploit deployed malicious contracts to an account to amplify access. If sensitive state is `access(account)`, any co-deployed contract is a lateral movement path.

**Fix**: Prefer `access(self)` for fields that only the declaring contract needs. Use `access(account)` only when cross-contract access within the account is genuinely required AND all co-deployed contracts are equally trusted.
```cadence
// ✅ Only this contract can access
access(self) var totalSupply: UFix64

// ✅ If cross-contract access is needed, document why and what contracts share the account
access(account) var sharedNonce: UInt64  // Shared with ContractB on same account (multi-sig upgrades only)
```

**Audit**: For every `access(account)` field, list which contracts share the account and whether any of them can be upgraded independently.

## Anti-Pattern 7: Burner.burn() on External Token Vaults

**Problem**: Accepting arbitrary `FungibleToken` vaults and destroying them via `Burner.burn()` lets an attacker grief the protocol with a malicious `burnCallback()`.

```cadence
// ❌ burnCallback() of unknown token type runs in THIS transaction
access(all) fun rejectDeposit(vault: @{FungibleToken.Vault}) {
    Burner.burn(<-vault)  // Attacker controls burnCallback — can panic or modify state
}
```

**Why dangerous**: Cadence 1.0 `Burner.Burnable` interface lets any token define custom logic on destruction. A maliciously crafted token's `burnCallback()` runs inside the protocol's transaction context, potentially causing panic (DoS) or unexpected state changes.

**Fix**: Validate token type against an allowlist before destroying. Return rejected vaults to the sender rather than destroying them.
```cadence
// ✅ Only destroy known, trusted token types
access(all) fun rejectDeposit(vault: @{FungibleToken.Vault}) {
    assert(vault.isInstance(Type<@FlowToken.Vault>()), message: "Unsupported token type")
    Burner.burn(<-vault)
}

// ✅ Even better: return instead of destroy
access(all) fun rejectDeposit(vault: @{FungibleToken.Vault}): @{FungibleToken.Vault} {
    return <-vault  // Caller handles disposal
}
```

## Detection Checklist

- [ ] Functions accepting `auth(...) &Account` parameters
- [ ] Public fields (especially complex types)
- [ ] Capability-typed public fields
- [ ] Public functions that create admin/privileged resources
- [ ] State modifications in struct initializers
- [ ] Event emissions in struct initializers
- [ ] Over-use of `access(all)` modifier
- [ ] `access(account)` fields without documenting which co-deployed contracts share the account
- [ ] `Burner.burn()` called on externally-supplied vaults without token type validation
