# Cadence Security Best Practices

## Access Control

### Practice 1: Default to Private
Start with `access(self)`, expand only when necessary. Only use `access(all)` for view functions, intentionally public APIs, and interface implementations.

### Practice 2: Protect Composite-Typed Fields
Resources, structs, and capabilities stored as fields MUST be `access(self)`:
```cadence
// ❌ CRITICAL: Anyone can copy this capability
access(all) let adminCapability: Capability<&Admin>

// ✅ CORRECT
access(self) let adminCapability: Capability<&Admin>
access(Admin) fun performAdminAction() {
    if let admin = self.adminCapability.borrow() { admin.doSomething() }
}
```

### Practice 3: Use Entitlements for Privileged Operations
Never use `access(all)` for state-modifying or privileged operations.

## Capability Security

### Practice 4: Issue Capabilities Sparingly
Check if capability already exists before issuing new ones.

### Practice 5: Publish with Verification
Check for existing published capabilities before publishing.

### Practice 6: Validate Before Borrowing
```cadence
// ✅ Handle optional
if let receiver = getAccount(address)
    .capabilities.borrow<&{FungibleToken.Receiver}>(/public/receiver) {
    receiver.deposit(from: <-vault)
} else {
    destroy vault
}

// ❌ Force unwrap
let receiver = cap.borrow()!  // Panics if invalid
```

### Practice 7: Never Expose Capabilities in Public Fields
Capabilities in public fields can be copied by anyone.

### Practice 8: Never Expose Capabilities in Public Arrays/Dictionaries
```cadence
// ❌ Anyone can access all capabilities
access(all) let capabilities: [Capability<&Admin>]

// ✅ Private storage
access(self) let capabilities: {Address: Capability<&Admin>}
```

## Reference Security

### Practice 9: Use Capabilities for Persistence (Not References)
References cannot be stored — use `Capability<&T>` instead of `&T` in fields.

### Practice 10: Minimize Entitlements on References
Grant only necessary entitlements when creating authorized references.

## Account Security

### Practice 11: Never Trust User Storage
Users control their own storage completely. Use capabilities with explicit types instead.

### Practice 12: Avoid Passing Authorized Account References
```cadence
// ❌ DANGEROUS
access(all) fun dangerous(account: auth(Storage) &Account) { }

// ✅ Pass specific capabilities
access(all) fun safe(vaultCap: Capability<auth(Withdraw) &Vault>) { }

// ✅ BEST: Perform operations in transaction prepare block
```

### Practice 13: Minimal Transaction Entitlements
```cadence
auth(BorrowValue) &Account                          // Read-only
auth(BorrowValue, SaveValue) &Account                // Read + write
auth(IssueStorageCapabilityController, PublishCapability) &Account              // Cap issuance + publish
```

## Type Safety

### Practice 14: Match Type Specificity to Intent

Use the most specific type your function actually requires. At open interface boundaries (standards implementations, marketplaces, vaults that hold multiple types), interface types are correct — pair them with an internal force-cast to verify the concrete type.

```cadence
// ✅ Correct for internal/single-type functions
access(all) fun processMyNFT(nft: @MyNFT) { }

// ✅ Correct for standards-conforming APIs (marketplace, collection deposit, FT receiver)
// Accept any conforming type, cast internally to verify
access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
    let nft <- token as! @MyNFT  // Panics cleanly if wrong type — this is intended
    // ...
}

// ❌ Wrong: accepting an interface type without casting, then using it as concrete type
access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
    // Using token as if it's @MyNFT without verifying — silent type confusion
}
```

**Rule:** Use `@ConcreteType` for functions that must only accept that exact type. Use `@{Interface}` at standard API boundaries that genuinely accept any conforming value, and always cast (`as!`) internally to your expected concrete type.

### Practice 15: Cast Less-Specific Types
Verify and cast to expected concrete types when receiving generic types. A failing cast panics cleanly — this is the intended security boundary, not a problem to avoid.

## Resource Safety

### Practice 16: Handle All Resources in Every Code Path
```cadence
// ✅ Both paths handle resource
if save {
    account.storage.save(<-vault, to: /storage/vault)
} else {
    destroy vault
}
```

### Practice 17: Resource Cleanup in Error Cases
```cadence
// ✅ Handle resource before panicking
if !someCondition() {
    destroy vault
    panic("Condition not met")
}
```

### Practice 17b: Always Handle Resources Before Panic-Prone Code
Cadence does NOT have `defer`. Explicitly move or destroy resources before any operation that could panic:
```cadence
fun process(vault: @{FungibleToken.Vault}) {
    let balance = vault.balance
    if balance != 0.0 {
        destroy vault
        panic("Transfer incomplete: balance is ".concat(balance.toString()))
    }
    doWork()
    destroy vault
}
```

## Transaction Security

### Practice 18: Audit Transactions Like Contracts
Transactions can contain arbitrary code — review entitlements carefully.

### Practice 19: Users Should Understand Requested Entitlements
Verify what entitlements are requested, what resources are accessed, and where resources are moved.

## Events

### Practice 20: Emit Events for Significant Actions
```cadence
access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
access(all) event TokensDeposited(amount: UFix64, to: Address?)
```

## Security Checklist

- [ ] All fields use `access(self)` or `access(contract)` by default
- [ ] Privileged operations use entitlements
- [ ] No capabilities in public fields, arrays, or dictionaries
- [ ] Capabilities validated before borrowing
- [ ] Minimal entitlements requested in transactions
- [ ] Resources handled in all code paths
- [ ] Types are as specific as possible
- [ ] User storage not trusted without validation
- [ ] Events emitted for significant actions
