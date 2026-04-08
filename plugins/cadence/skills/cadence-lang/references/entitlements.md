# Cadence Entitlements

Entitlements provide fine-grained permission control for accessing members through references and capabilities.

## Declaring Entitlements

```cadence
access(all) entitlement Admin
access(all) entitlement Withdraw
access(all) entitlement Mint
```

Entitlement names should be a verb (what it grants) or noun (who should have it), capitalized. Entitlements share the same namespace as types and can be imported from other contracts (`C.E`).

## Using Entitlements on Members

```cadence
access(all) resource Vault {
    access(self) var balance: UFix64
    access(all) view fun getBalance(): UFix64 { return self.balance }
    access(all) fun deposit(from: @{FungibleToken.Vault}) { /* ... */ }
    access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} { /* ... */ }
    access(Admin) fun forceSetBalance(newBalance: UFix64) { self.balance = newBalance }
}
```

## Entitlement Sets

### Conjunction (requires ALL) — comma-separated
```cadence
access(Admin, Withdraw) fun adminWithdraw(): @{FungibleToken.Vault} { }
// Caller must hold BOTH Admin AND Withdraw
```

### Disjunction (requires ANY) — pipe-separated
```cadence
access(Admin | Owner) fun privilegedAction() { }
// Caller must hold EITHER Admin OR Owner
```

**Cannot mix `,` and `|` in the same set.** Choose one form per declaration.

## Owned Values Are Fully Entitled

**Critical rule**: Owning a value (struct or resource) gives full access to all methods regardless of entitlements. Entitlements only gate access through **references**.

```cadence
let vault <- create Vault(balance: 100.0)
vault.withdraw(amount: 10.0)  // ✅ Works — owned value, no entitlement needed

let ref = &vault as &Vault     // Unauthorized reference
ref.withdraw(amount: 10.0)     // ❌ ERROR — needs auth(Withdraw) &Vault

let authRef = &vault as auth(Withdraw) &Vault
authRef.withdraw(amount: 10.0) // ✅ Works — authorized reference
```

This means entitlements protect against unauthorized access through capabilities and references, not against the resource owner.

## Built-in Mutability Entitlements

Three built-in entitlements for collection operations:

- `Insert` — Add elements
- `Remove` — Delete elements
- `Mutate` — Equivalent to the conjunction `(Insert, Remove)`

```cadence
access(Insert) fun addItem(_ item: @NFT) { }
access(Remove) fun removeItem(id: UInt64): @NFT { }
access(Mutate) fun replaceItem(id: UInt64, with: @NFT): @NFT { }
```

Used by array and dictionary built-in functions, but available for any declaration.

## Entitlement Mappings

Mappings declare how entitlements propagate from parent to child objects in nested hierarchies.

### Declaring a Mapping
```cadence
entitlement mapping OuterToInnerMap {
    OuterAdmin -> InnerAdmin
    OuterReader -> InnerReader
}
```

Domain (left) entitlements map to range (right) entitlements. Mappings need not be 1:1 — multiple inputs can map to one output, or one input to many.

### Using Mappings on Fields
```cadence
access(all) resource Container {
    access(mapping OuterToInnerMap) let inner: @InnerResource

    access(mapping OuterToInnerMap) fun getInner(): auth(mapping OuterToInnerMap) &InnerResource {
        return &self.inner as auth(mapping OuterToInnerMap) &InnerResource
    }
}
```

When borrowing with `auth(OuterAdmin) &Container`, calling `getInner()` returns `auth(InnerAdmin) &InnerResource` — the entitlement propagates through the mapping.

**Mapping rules**:
- Mapping a conjunction set produces a conjunction set
- Mapping a disjunction set produces a disjunction set

### Identity Mapping

`Identity` is a built-in mapping that maps every entitlement to itself:

```cadence
access(all) resource Wrapper {
    access(mapping Identity) let wrapped: @InnerResource

    access(mapping Identity) fun getWrapped(): auth(mapping Identity) &InnerResource {
        return &self.wrapped as auth(mapping Identity) &InnerResource
    }
}
```

If you borrow with `auth(E) &Wrapper`, calling `getWrapped()` returns `auth(E) &InnerResource`.

**Important**: Accessing an Identity-mapped field with an owned value yields an empty entitlement set (unauthorized reference), because owned values don't carry explicit entitlements.

### Mapping Composition with `include`

Compose mappings by including others:
```cadence
entitlement mapping Combined {
    include MapA
    include MapB
    ExtraEntitlement -> TargetEntitlement
}
```

This copies all relations from included mappings plus any additional ones. Cyclical includes are rejected.

## Account Entitlements

Flow accounts use entitlements for fine-grained permission control:

### Storage
```cadence
auth(SaveValue) &Account       // save()
auth(LoadValue) &Account       // load()
auth(BorrowValue) &Account     // borrow()
auth(CopyValue) &Account       // copy()
auth(Storage) &Account          // All storage operations
```

### Capabilities
```cadence
auth(IssueStorageCapabilityController) &Account
auth(IssueAccountCapabilityController) &Account
auth(PublishCapability) &Account
auth(UnpublishCapability) &Account
auth(Capabilities) &Account     // All capability operations
```

### Keys and Contracts
```cadence
auth(AddKey) &Account           // Add key
auth(RevokeKey) &Account        // Revoke key
auth(Keys) &Account             // All key operations
auth(Contracts) &Account        // All contract operations
```

### Common Transaction Combinations
```cadence
auth(BorrowValue) &Account                                          // Read-only
auth(BorrowValue, SaveValue) &Account                               // Read + write
auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account  // + cap issuance
```

## Entitlements on References vs Capabilities

### References
```cadence
// Unauthorized — read-only access
let ref = &vault as &Vault

// Authorized — can call entitled functions
let authRef = &vault as auth(Withdraw) &Vault
authRef.withdraw(amount: 10.0)  // ✅
```

### Capabilities
```cadence
// Public capability — no entitlements (safe to publish)
let publicCap = account.capabilities.storage.issue<&Vault>(/storage/vault)

// Private capability — with entitlements (never publish)
let privateCap = account.capabilities.storage
    .issue<auth(Withdraw) &Vault>(/storage/vault)
```

**Never publish entitled capabilities** — anyone could borrow and use the entitlement.
