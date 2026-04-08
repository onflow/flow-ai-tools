# Cadence Reference Rules

References are **non-owning pointers** providing temporary access without transferring ownership. They are ephemeral and cannot be stored.

## Creating References

```cadence
let resource <- createResource()
let ref = &resource as &MyResource      // Basic reference
let interfaceRef = &resource as &{MyInterface}  // Interface reference

// With type annotation
let ref: &MyResource = &resource as &MyResource
```

## Authorized References

Use `auth()` for references with entitlements:

```cadence
access(all) entitlement Owner
access(all) entitlement Admin

let vault <- create Vault(balance: 100.0)

let ownerRef = &vault as auth(Owner) &Vault
ownerRef.withdraw(amount: 10.0)  // Allowed

let adminRef = &vault as auth(Admin) &Vault
adminRef.setBalance(newBalance: 200.0)  // Allowed

let fullRef = &vault as auth(Owner, Admin) &Vault  // Both entitlements
```

## Borrowing from Storage (Most Common)

```cadence
// Unauthorized (read-only)
let vaultRef = signer.storage.borrow<&Vault>(from: /storage/vault)
    ?? panic("Could not borrow Vault reference from /storage/vault")

// Authorized (can call entitled functions)
let vaultRef = signer.storage
    .borrow<auth(FungibleToken.Withdraw) &Vault>(from: /storage/vault)
    ?? panic("Could not borrow Vault reference from /storage/vault")
let withdrawn <- vaultRef.withdraw(amount: 10.0)
```

## Reference Validity

**References become invalid when the referenced value is moved or destroyed:**

```cadence
// ✅ CORRECT: Use reference before moving
let resource <- createResource()
let ref = &resource as &Resource
let value = ref.getValue()  // Valid
destroy resource             // ref now invalid

// ❌ WRONG: Using reference after move
let resource <- createResource()
let ref = &resource as &Resource
let moved <- resource        // resource moved
ref.someFunction()           // RUNTIME ERROR
```

## References Cannot Be Stored

References are ephemeral — use capabilities for persistent access:

```cadence
// ❌ COMPILE ERROR
access(self) let vaultRef: &Vault

// ✅ CORRECT: Store capability
access(self) let vaultCap: Capability<&Vault>

access(all) fun useVault() {
    if let vaultRef = self.vaultCap.borrow() {
        vaultRef.someFunction()
    }
}
```

## Covariance

`&T` is a subtype of `&U` when `T` is a subtype of `U`:

```cadence
let dog <- create Dog()
let animalRef: &{Animal} = &dog as &{Animal}  // Valid
animalRef.makeSound()    // OK
// animalRef.wagTail()   // COMPILE ERROR: not in Animal interface
```

## Dereferencing

Only primitive values can be dereferenced:
```cadence
let num: Int = 42
let numRef = &num as &Int
let numCopy = *numRef     // Creates copy

// ❌ Cannot dereference resources or structs
```

## Key Patterns

### Safe Borrowing
```cadence
if let ref = signer.storage.borrow<&Vault>(from: /storage/vault) {
    log(ref.balance)
}
// Reference invalid after scope
```

### Capability Borrowing
```cadence
let cap = getAccount(address).capabilities.get<&{VaultPublic}>(/public/vault)
if let ref = cap.borrow() {
    ref.deposit(from: <-tokens)
}
```

### Interface References for Restriction
```cadence
let publicRef: &{PublicInterface} = &vault as &{PublicInterface}
publicRef.publicMethod()     // OK
// publicRef.adminMethod()   // COMPILE ERROR: not in interface
```

## Safety Rules

1. **Don't store references** — use capabilities for persistence
2. **References don't transfer ownership** — original value stays valid
3. **Check validity** — ensure resource hasn't been moved/destroyed
4. **Minimal entitlements** — grant only needed entitlements on authorized references
