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

## Detection Checklist

- [ ] Functions accepting `auth(...) &Account` parameters
- [ ] Public fields (especially complex types)
- [ ] Capability-typed public fields
- [ ] Public functions that create admin/privileged resources
- [ ] State modifications in struct initializers
- [ ] Event emissions in struct initializers
- [ ] Over-use of `access(all)` modifier
