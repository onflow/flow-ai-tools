# Cadence Contract Rules

Contracts are collections of type definitions, data, and functions stored permanently in account contract storage.

## Contract Structure

```cadence
access(all) contract MyContract {
    // Type definitions (resources, structs, interfaces, enums, events)
    access(all) resource NFT {
        access(all) let id: UInt64
        init(id: UInt64) { self.id = id }
    }

    // State fields
    access(self) var totalSupply: UInt64

    // Functions
    access(all) view fun getTotalSupply(): UInt64 { return self.totalSupply }

    // Initializer (runs once on deployment)
    init() { self.totalSupply = 0 }
}
```

## Contract Initializer

Runs **exactly once** on first deployment. Sets up initial state, can write to account storage.

### Common Patterns
```cadence
init() {
    // State initialization
    self.totalSupply = 0
    self.paused = false

    // Admin resource creation
    let admin <- create Admin()
    self.account.storage.save(<-admin, to: /storage/tokenAdmin)

    // Public capability setup
    let publicCap = self.account.capabilities.storage
        .issue<&Vault>(/storage/mainVault)
    self.account.capabilities.publish(publicCap, at: /public/tokenVault)

    // Event emission
    emit ContractInitialized()
}
```

## The `account` Field

Every contract has implicit `self.account` providing full access to the deploying account:
- `self.account.storage` — Storage management
- `self.account.capabilities` — Capability management
- `self.account.contracts` — Contract management
- `self.account.keys` — Key management
- `self.account.address` — Account address

## Contract Interfaces

Define behavioral contracts. Events declared in a contract interface define the event type for the standard but implementing contracts do not redeclare them. Nested resource/struct interfaces declared in a contract interface are available to implementors. Fields and functions ARE required.

```cadence
access(all) contract interface TokenInterface {
    entitlement Withdraw
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    access(all) resource interface Provider {
        access(Withdraw) fun withdraw(amount: UFix64): @Vault
    }

    // Required fields and functions
    access(all) var totalSupply: UFix64
    access(all) view fun getTotalSupply(): UFix64
}

access(all) contract MyToken: TokenInterface {
    access(all) var totalSupply: UFix64
    access(all) view fun getTotalSupply(): UFix64 { return self.totalSupply }
    init() { self.totalSupply = 1000.0 }
}
```

## Contract Deployment and Management

```cadence
// Deploy
signer.contracts.add(name: contractName, code: code.utf8)

// Update (preserves data, doesn't re-run init)
signer.contracts.update(name: contractName, code: newCode.utf8)

// Remove
signer.contracts.remove(name: contractName)

// Get info
let names = account.contracts.names
let contract = account.contracts.get(name: "MyContract")
let contractRef = account.contracts.borrow<&MyContract>(name: "MyContract")
```

## Contract Nesting

**Allowed**: Resources, structs, interfaces, enums, events, functions
**Not allowed**: Contracts, contract interfaces

## Contract Upgrade Rules

### Valid Changes (Allowed)
- Add, change, or delete functions (signatures, bodies, access modifiers)
- Change field access modifiers
- Add interface conformance to structs/resources
- Add new struct/resource/interface/enum declarations
- Add enum cases at the END of existing cases
- Modify events and constructors freely
- Remove existing fields (stored data for that field becomes inaccessible but causes no crash — Cadence encodes fields by name, not position)
- Reorder fields (Cadence field encoding is name-based, so order is irrelevant to deserialization)

### Invalid Changes (NOT Allowed)
- Adding new non-optional fields (init doesn't re-run; stored values would have no data — use optional fields + lazy init instead)
- Changing the type of an existing field (causes deserialization errors)
- Removing existing struct/resource/interface/enum declarations
- Renaming declarations
- Changing declaration types (e.g., struct to resource)
- Removing interface conformance from structs/resources
- Reordering, renaming, or removing enum cases
- Adding enum cases in the middle (only at the end)
- Removing contracts that contain enum declarations

## Best Practices

### Single Responsibility
Each contract should have one clear purpose.

### Initialize All State in `init()`
```cadence
init() {
    self.counter = 0
    self.name = "MyContract"
    self.active = true
}
```

### Events for Observability
```cadence
access(all) event ContractInitialized()
access(all) event StateUpdated(newValue: UInt64)
emit StateUpdated(newValue: newValue)
```

### Minimal Public Surface
```cadence
access(all) contract SecureContract {
    access(self) var internalState: {String: UInt64}

    access(all) view fun getValue(key: String): UInt64? {
        return self.internalState[key]
    }

    access(Admin) fun setValue(key: String, value: UInt64) {
        self.internalState[key] = value
    }
}
```
