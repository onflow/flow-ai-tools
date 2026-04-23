# Scaffold: Cadence Transaction

## Interview the User

Before generating, ask for:
1. **What the transaction does** — transfer, setup, mint, update, etc.
2. **Which contracts are involved** — what to import
3. **What parameters are needed** — amounts, addresses, IDs
4. **What account entitlements are required** — read-only, write, capabilities

## Transaction Rules (Always Apply)

### Phase Discipline (physical write order)
```
prepare → pre → execute → post
```
- `prepare`: ONLY account access operations (borrow capabilities, validate storage)
- `pre`: Input validation — single boolean expressions only
- `execute`: Primary business logic
- `post`: Outcome verification using `before()` for comparisons

### Entitlement Discipline
- `auth(BorrowValue)` — read-only
- `auth(BorrowValue, SaveValue)` — read + write
- `auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability)` — setup (issue and publish capabilities)
- Never: `auth(Storage, Contracts, Keys)` unless explicitly required

### Resource Safety
- Handle resources in ALL code paths (moves, panics, conditionals)
- Validate transfers: confirm vault balance is 0 before destruction
- Handle resources before any panic-prone operations (Cadence does NOT have `defer`)
- Always nil-check capability borrows

### General
- Accept addresses as parameters — never hardcode
- Use string-based imports: `import "ContractName"`
- Descriptive panic messages with interpolated values

## Transaction Template

```cadence
import "FungibleToken"
import "MyContract"

transaction(amount: UFix64, recipient: Address) {
    // Cross-phase fields
    let senderVault: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let recipientReceiver: &{FungibleToken.Receiver}
    let startBalance: UFix64

    prepare(signer: auth(BorrowValue) &Account) {
        // ONLY account access here
        self.senderVault = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: /storage/vault)
            ?? panic("Could not borrow FungibleToken Vault reference from /storage/vault")

        self.recipientReceiver = getAccount(recipient)
            .capabilities.borrow<&{FungibleToken.Receiver}>(/public/receiver)
            ?? panic("Could not borrow FungibleToken Receiver from /public/receiver for \(recipient)")

        self.startBalance = self.senderVault.balance
    }

    pre {
        amount > 0.0: "Amount must be positive: received \(amount)"
        self.senderVault.balance >= amount: "Insufficient balance: have \(self.senderVault.balance), need \(amount)"
    }

    execute {
        let vault <- self.senderVault.withdraw(amount: amount)
        self.recipientReceiver.deposit(from: <-vault)
    }

    post {
        self.senderVault.balance == self.startBalance - amount:
            "Balance not decreased by \(amount)"
    }
}
```

## Setup Transaction Template

```cadence
import "MyContract"

transaction() {
    prepare(signer: auth(SaveValue, BorrowValue, IssueStorageCapabilityController, PublishCapability) &Account) {
        // Check if already set up
        if signer.storage.borrow<&MyContract.Collection>(from: MyContract.StoragePath) != nil {
            return  // Already initialized
        }

        // Create and save resource
        let collection <- MyContract.createEmptyCollection()
        signer.storage.save(<-collection, to: MyContract.StoragePath)

        // Create and publish capability
        let cap = signer.capabilities.storage
            .issue<&MyContract.Collection>(MyContract.StoragePath)
        signer.capabilities.publish(cap, at: MyContract.PublicPath)
    }
}
```

## Post-Generation

After generating, add inline comments explaining:
- Why each entitlement was chosen
- What each phase does
- Security rationale for access patterns

Also add `///` doc comments for the transaction and any helper functions so the intent and call expectations are explicit.

> **See also:** `cadence-lang` skill → `documentation.md` for docstring and inline comment conventions, `transactions.md` for phase rules, `entitlements.md` for account entitlement patterns, `conditions.md` for pre/post condition syntax, `capabilities.md` for capability setup patterns. Use `flow-cli` skill to test with `flow transactions send`.
