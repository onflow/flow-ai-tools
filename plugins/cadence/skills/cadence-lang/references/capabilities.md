# Cadence Capabilities and Security

Capabilities represent **the right to access an object**. They are unforgeable, transferable, and revocable.

## Capability Structure
```cadence
Capability<T: &Any>
capability.address: Address    // Target account
capability.id: UInt64          // Unique ID per account
capability.borrow(): T?        // Get optional reference
capability.check(): Bool       // Verify validity
```

## Two Types
1. **Storage Capabilities** — access objects at storage paths
2. **Account Capabilities** — access entire accounts

## Capability Lifecycle

### Phase 1: Issue
```cadence
let controller = account.capabilities.storage
    .issue<&MyResource>(/storage/myResource)
```

### Phase 2: Publish
```cadence
account.capabilities.publish(controller.capability, at: /public/myResource)
```

### Phase 3: Get/Borrow
```cadence
let cap = getAccount(address)
    .capabilities.get<&{FungibleToken.Receiver}>(/public/receiver)

if let ref = cap.borrow() {
    ref.deposit(from: <-vault)
}

// Convenience: get and borrow in one step
if let ref = getAccount(address)
    .capabilities.borrow<&{FungibleToken.Receiver}>(/public/receiver) {
    ref.deposit(from: <-vault)
}
```

### Phase 4: Revoke
```cadence
// Get the controller, then delete it
let controller = account.capabilities.storage
    .getController(byCapabilityID: capabilityID)
controller?.delete()
// All copies of this capability become invalid
```

## Secure Patterns

### Pattern 1: Minimal Exposure
Only publish concrete type with no entitlements:
```cadence
// ✅ CORRECT: No entitlements on public cap
let cap = account.capabilities.storage.issue<&Vault>(/storage/vault)
account.capabilities.publish(cap, at: /public/vault)

// ❌ WRONG: Entitled public cap
let cap = account.capabilities.storage
    .issue<auth(Withdraw) &Vault>(/storage/vault)
account.capabilities.publish(cap, at: /public/vault)  // SECURITY FLAW
```

### Pattern 2: Entitled Capabilities (Private)
```cadence
// Private — not published
let withdrawCap = account.capabilities.storage
    .issue<auth(Withdraw) &Vault>(/storage/vault)

// Public — no entitlements
let publicCap = account.capabilities.storage.issue<&Vault>(/storage/vault)
account.capabilities.publish(publicCap, at: /public/vault)
```

## Management Best Practices

### Store Controllers for Revocation
```cadence
let controller = account.capabilities.storage
    .issue<&MyResource>(/storage/myResource)
account.storage.save(controller, to: /storage/myResourceController)

// Later: revoke by getting controller and calling delete()
let ctrl = account.capabilities.storage
    .getController(byCapabilityID: controller.capabilityID)
ctrl?.delete()
```

### Tag Capabilities
```cadence
controller.setTag("FlowToken Receiver - Public Deposit Access")
```

### Audit Capabilities
```cadence
let controllers = account.capabilities.storage.getControllers(forPath: /storage/vault)
for controller in controllers {
    log("Cap ID: ".concat(controller.capabilityID.toString()))
    log("Tag: ".concat(controller.tag ?? "No tag"))
}
```

### Principle of Least Privilege
```cadence
// ❌ Over-privileged
let cap = account.capabilities.storage
    .issue<auth(Admin, Withdraw, Mutate) &Resource>(/storage/resource)

// ✅ Minimal
let cap = account.capabilities.storage
    .issue<auth(Withdraw) &Resource>(/storage/resource)
```

## Check Before Borrow
```cadence
// ✅ Handle optional
if let receiver = cap.borrow() {
    receiver.deposit(from: <-vault)
} else {
    destroy vault  // Handle failure — don't lose resource
}

// ❌ Force unwrap
let receiver = cap.borrow()!  // May panic
```

## Capability Retargeting
```cadence
// Move resource then retarget
controller.retarget(/storage/newPath)
```
Note: Only works for storage capabilities, not account capabilities.

## Common Vulnerabilities

### Publishing Full Access
Always use entitlements on resources and publish only un-entitled caps.

### Forgetting to Revoke
Store controllers and delete when access should be removed.

### Type Confusion
Ensure capability type annotation matches the actual stored type.

## Entitlement Mappings
```cadence
entitlement mapping MyMap {
    AdminAccess -> Admin
    UserAccess -> User
}

access(all) resource Container {
    access(mapping MyMap) fun getInner(): auth(mapping MyMap) &InnerResource {
        return &self.innerResource
    }
}
```
