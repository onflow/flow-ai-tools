# Cadence Interface Rules

Interfaces define **what** must exist without specifying **how**. Cadence uses **nominal typing** — a type only implements an interface if it explicitly declares conformance.

## Three Interface Types

### Struct Interfaces
```cadence
access(all) struct interface NamedEntity {
    access(all) let name: String
    access(all) view fun getName(): String
}

access(all) struct User: NamedEntity {
    access(all) let name: String
    access(all) view fun getName(): String { return self.name }
    init(name: String) { self.name = name }
}
```

### Resource Interfaces
```cadence
access(all) resource interface Provider {
    access(Withdraw) fun withdraw(amount: UFix64): @Vault
    access(all) var balance: UFix64
}

access(all) resource Vault: Provider, Receiver {
    access(all) var balance: UFix64
    access(Withdraw) fun withdraw(amount: UFix64): @Vault {
        pre { self.balance >= amount: "Insufficient balance" }
        self.balance = self.balance - amount
        return <- create Vault(balance: amount)
    }
    init(balance: UFix64) { self.balance = balance }
}
```

### Contract Interfaces
```cadence
access(all) contract interface FungibleTokenStandard {
    access(all) entitlement Withdraw
    access(all) resource interface Provider {
        access(Withdraw) fun withdraw(amount: UFix64): @Vault
    }
    access(all) resource Vault: Provider, Receiver
}
```

## Pre/Post Conditions in Interfaces

Interfaces can define conditions that implementations inherit automatically:

```cadence
access(all) resource interface Vault {
    access(all) var balance: UFix64
    access(Withdraw) fun withdraw(amount: UFix64): @Vault {
        pre { self.balance >= amount: "Insufficient balance" }
        post { self.balance == before(self.balance) - amount: "Balance mismatch" }
    }
}
```

Implementations can add additional conditions on top of interface conditions.

## Default Functions

```cadence
access(all) resource interface Counter {
    access(all) var count: UInt64
    access(all) fun increment() { self.count = self.count + 1 }  // Default
    access(all) view fun getCount(): UInt64 { return self.count }  // Default
}

access(all) resource MyCounter: Counter {
    access(all) var count: UInt64
    // Uses default increment() and getCount()
    init() { self.count = 0 }
}
```

Override defaults by providing your own implementation.

## Interface Inheritance

```cadence
access(all) resource interface Base {
    access(all) view fun baseFunction(): String
}

access(all) resource interface Extended: Base {
    access(all) view fun extendedFunction(): String
}

// Must implement both
access(all) resource MyResource: Extended {
    access(all) view fun baseFunction(): String { return "base" }
    access(all) view fun extendedFunction(): String { return "extended" }
}
```

Multiple inheritance is supported:
```cadence
access(all) resource interface C: A, B {
    access(all) view fun methodC(): String
}
```

## Intersection Types

Represent values that implement specific interfaces:

```cadence
// Function accepts any resource implementing Provider
access(all) fun withdrawFromProvider(provider: &{Provider}, amount: UFix64): @Vault {
    return <- provider.withdraw(amount: amount)
}

// Multiple interfaces
access(all) fun process(vault: &{Provider, Balance}, amount: UFix64) { }
```

## Nested Interfaces

```cadence
access(all) contract MyContract {
    access(all) resource interface VaultPublic {
        access(all) view fun getBalance(): UFix64
    }

    access(all) resource Vault: VaultPublic {
        access(self) var balance: UFix64
        access(all) view fun getBalance(): UFix64 { return self.balance }
    }
}

// Reference: &{MyContract.VaultPublic}
```

## Best Practices

1. **Small, focused interfaces** — combine as needed rather than monolithic interfaces
2. **Use contract interfaces** for protocol standards (FungibleToken, NonFungibleToken)
3. **Include pre/post conditions** for safety invariants in state-changing functions
4. **Provide default implementations** for common behavior
5. **Accept intersection types** in function parameters for flexibility:
   ```cadence
   // ✅ Flexible
   access(all) fun processProvider(provider: &{Provider}) { }
   // ❌ Less flexible
   access(all) fun processVault(vault: &Vault) { }
   ```
