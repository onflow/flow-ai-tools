# Cadence Pre and Post Conditions

Conditions enforce contracts between callers and implementations. Both cause complete reversion if violated.

## Pre-Conditions

Validate inputs and preconditions before execution. Evaluated **before** function body.

```cadence
access(all) fun transfer(amount: UFix64, to: Address) {
    pre {
        amount > 0.0: "Amount must be positive: received \(amount)"
        amount <= self.balance: "Insufficient balance: available \(self.balance), required \(amount)"
        to != self.owner?.address: "Cannot transfer to self"
    }
    // Function body
}
```

## Post-Conditions

Validate results and state changes after execution.

### The `result` Constant
```cadence
access(all) view fun calculateTotal(values: [UFix64]): UFix64 {
    post {
        result >= 0.0: "Total cannot be negative: got \(result)"
    }
    var total: UFix64 = 0.0
    for value in values { total = total + value }
    return total
}
```

### The `before()` Function
Captures values from before function execution:
```cadence
access(all) fun increment() {
    post {
        self.counter == before(self.counter) + 1:
            "Counter not incremented correctly"
    }
    self.counter = self.counter + 1
}
```

## Conditions in Functions

```cadence
access(Withdraw) fun withdraw(amount: UFix64): @Vault {
    pre {
        amount > 0.0: "Amount must be positive: received \(amount)"
        amount <= self.balance: "Insufficient balance: available \(self.balance), required \(amount)"
    }
    post {
        result.balance == amount: "Incorrect withdrawal amount"
        self.balance == before(self.balance) - amount: "Balance mismatch"
    }
    self.balance = self.balance - amount
    return <- create Vault(balance: amount)
}
```

## Conditions in Transactions

Pre-conditions execute **after** `prepare`, **before** `execute`:
```cadence
transaction(amount: UFix64, recipient: Address) {
    let vault: &Vault

    prepare(signer: auth(BorrowValue) &Account) {
        self.vault = signer.storage.borrow<&Vault>(from: /storage/vault)
            ?? panic("Could not borrow Vault reference from /storage/vault")
    }

    pre {
        amount > 0.0: "Amount must be positive: received \(amount)"
        amount <= self.vault.balance: "Insufficient balance"
    }

    execute {
        let withdrawn <- self.vault.withdraw(amount: amount)
        // ... use withdrawn vault
        destroy withdrawn
    }

    post {
        self.vault.balance >= 0.0: "Balance cannot be negative"
    }
}
```

**Note:** `result` is only available in **function** post-conditions — it refers to the return value. Transactions don't return values, so `result` is not available in transaction post-conditions. Use `before()` and field comparisons instead.

## View Context Restrictions

Conditions are read-only:
- **Allowed**: Reading fields, calling view functions, boolean operations, comparisons, `before()`, `result` (functions only)
- **Not allowed**: Modifying fields, calling non-view functions, resource operations, emitting events

## Conditions in Interfaces

Interface conditions are automatically checked on all implementations:

```cadence
access(all) resource interface Vault {
    access(all) var balance: UFix64
    access(Withdraw) fun withdraw(amount: UFix64): @Vault {
        pre { self.balance >= amount: "Insufficient balance" }
        post { self.balance == before(self.balance) - amount: "Balance mismatch" }
    }
}

// Implementation inherits conditions and can add more:
access(all) resource MyVault: Vault {
    access(Withdraw) fun withdraw(amount: UFix64): @Vault {
        pre { !self.locked: "Vault is locked" }  // Additional condition
        self.balance = self.balance - amount
        return <- create MyVault(balance: amount)
    }
}
```

## Best Practices

### Descriptive Error Messages
```cadence
// ✅ Clear
pre { amount > 0.0: "Transfer amount must be greater than zero" }
pre { amount <= self.balance: "Insufficient balance: have \(self.balance), need \(amount)" }

// ❌ Vague
pre { amount > 0.0: "Invalid amount" }
```

### Single Responsibility per Condition
```cadence
// ✅ Separate conditions
pre {
    amount > 0.0: "Amount must be positive"
    amount <= maxAmount: "Amount exceeds maximum"
    recipient != sender: "Cannot transfer to self"
}

// ❌ Combined
pre {
    amount > 0.0 && amount <= maxAmount && recipient != sender: "Invalid parameters"
}
```

### Use `before()` for State Tracking
```cadence
post {
    self.counter == before(self.counter) + 1: "Counter not incremented"
    self.balance >= before(self.balance): "Balance decreased unexpectedly"
}
```

## Common Patterns

### Balance Validation
```cadence
pre { amount > 0.0: "Amount must be positive" }
pre { self.balance >= amount: "Insufficient balance" }
post { result.balance == amount: "Withdrawn amount incorrect" }
post { self.balance == before(self.balance) - amount: "Balance mismatch" }
```

### State Transition
```cadence
access(all) fun complete() {
    pre { self.status == Status.active: "Can only complete active items" }
    post { self.status == Status.completed: "Status not updated" }
    self.status = Status.completed
}
```
