# Cadence Transaction Rules

Transactions use explicit execution phases to separate concerns and make security implications clear.

## Transaction Structure

```cadence
import "FungibleToken"

transaction(amount: UFix64, recipient: Address) {
    let senderVault: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let recipientReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        self.senderVault = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FungibleToken Vault reference from /storage/flowTokenVault")
        self.recipientReceiver = getAccount(recipient)
            .capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow FungibleToken Receiver reference from /public/flowTokenReceiver")
    }

    pre {
        amount > 0.0: "Amount must be positive: received \(amount)"
    }

    execute {
        let vault <- self.senderVault.withdraw(amount: amount)
        self.recipientReceiver.deposit(from: <-vault)
    }

    post {
        self.senderVault.balance >= 0.0: "Sender balance cannot be negative"
    }
}
```

## The Four Phases

**CRITICAL execution order: `prepare` → `pre` → `execute` → `post`**

### Phase 1: `prepare`
- **ONLY place** where signing accounts are accessible
- Use for: borrowing from storage, creating capabilities, saving resources
- Minimize logic — only account-access operations

```cadence
prepare(signer: auth(BorrowValue, SaveValue, StorageCapabilities) &Account) {
    self.vault = signer.storage.borrow<&{FungibleToken.Vault}>(from: /storage/vault)
        ?? panic("Could not borrow FungibleToken Vault reference from /storage/vault")
}
```

**Multiple signers:**
```cadence
prepare(signer1: auth(BorrowValue) &Account, signer2: auth(BorrowValue) &Account) { }
```

### Phase 2: `pre` (Pre-conditions)
- Validates inputs AFTER prepare, BEFORE execute
- View context only — no state modifications
- If any condition fails, transaction reverts

```cadence
pre {
    amount > 0.0: "Amount must be positive: received \(amount)"
    self.senderVault.balance >= amount: "Insufficient balance"
}
```

### Phase 3: `execute`
- Main business logic and state modifications
- **Cannot access signing accounts** — use fields set in prepare
- Can access public info via `getAccount()`

### Phase 4: `post` (Post-conditions)
- Verifies expected results AFTER execute
- Can use `before()` to reference pre-execution values
- **`result` is NOT available** — transactions don't return values. Use `before()` and field comparisons instead.

```cadence
post {
    self.senderVault.balance == before(self.senderVault.balance) - amount:
        "Balance not decreased by \(amount)"
}
```

## Transaction Parameters

**Allowed**: `Int`, `UInt64`, `UFix64`, `Bool`, `String`, `Address`, arrays, dictionaries, optionals, structs
**NOT allowed**: Resources, capabilities, references, functions

## Field Declarations
Declare fields to share state between phases:
```cadence
transaction(amount: UFix64) {
    let vault: &{FungibleToken.Vault}
    let startBalance: UFix64

    prepare(signer: auth(BorrowValue) &Account) {
        self.vault = signer.storage.borrow<&{FungibleToken.Vault}>(from: /storage/vault)
            ?? panic("Could not borrow vault")
        self.startBalance = self.vault.balance
    }
}
```

## Required Entitlements — Minimal Privilege

```cadence
// Read-only
auth(BorrowValue) &Account

// Read and write storage
auth(BorrowValue, SaveValue) &Account

// Storage and capabilities
auth(BorrowValue, SaveValue, StorageCapabilities) &Account

// Contract deployment
auth(Contracts) &Account

// Key management
auth(Keys) &Account
```

**Never request more than needed:**
```cadence
// ❌ WRONG: Over-privileged
prepare(signer: auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account) {
    let vault = signer.storage.borrow<&Vault>(from: /storage/vault)  // Only needs BorrowValue
}
```

## Security Considerations

- **Validate external data**: Never force-unwrap capabilities from external accounts
- **Resource safety**: Ensure all resources are handled in all code paths
- **Keep prepare minimal**: Business logic goes in `execute`

## Common Patterns

### Token Transfer
```cadence
transaction(amount: UFix64, to: Address) {
    // Borrow references in prepare to avoid moving the vault out of storage
    let senderVault: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let recipientReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        self.senderVault = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: /storage/vault)
            ?? panic("Could not borrow vault")
        self.recipientReceiver = getAccount(to)
            .capabilities.borrow<&{FungibleToken.Receiver}>(/public/receiver)
            ?? panic("Could not borrow receiver")
    }
    execute {
        let vault <- self.senderVault.withdraw(amount: amount)
        self.recipientReceiver.deposit(from: <-vault)
    }
}
```

### Resource Setup
```cadence
transaction() {
    prepare(signer: auth(SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {
        let resource <- MyContract.createResource()
        signer.storage.save(<-resource, to: /storage/myResource)
        let cap = signer.capabilities.storage.issue<&MyContract.Resource>(/storage/myResource)
        signer.capabilities.publish(cap, at: /public/myResource)
    }
}
```
