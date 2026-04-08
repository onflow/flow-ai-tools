# Cadence Design Patterns

## Pattern 1: Named Constants
```cadence
access(all) contract GoodContract {
    access(all) let FEE_PERCENTAGE: UFix64
    access(all) let MINIMUM_AMOUNT: UFix64
    init() {
        self.FEE_PERCENTAGE = 0.05
        self.MINIMUM_AMOUNT = 10.0
    }
}
```

## Pattern 2: Script-Accessible Public Data
Expose data through public view functions for fee-free script queries:
```cadence
access(all) view fun getTotalSupply(): UFix64 { return self.totalSupply }
```

## Pattern 3: Report Structs for Resources
Scripts cannot return resources — create struct reports:
```cadence
access(all) struct NFTReport {
    access(all) let id: UInt64
    access(all) let owner: Address
    access(all) let metadata: {String: String}
    init(id: UInt64, owner: Address, metadata: {String: String}) { /* ... */ }
}

access(all) resource NFT {
    access(all) view fun generateReport(): NFTReport {
        return NFTReport(id: self.id, owner: self.owner?.address ?? panic("No owner"), metadata: self.metadata)
    }
}
```

## Pattern 4: Singleton Admin Resource
Create admin in `init()` only — no public creation function:
```cadence
init() {
    let admin <- create Admin()
    self.account.storage.save(<-admin, to: /storage/contractAdmin)
}
```

## Pattern 5: Descriptive Naming
Use full words, indicate purpose, use camelCase:
```cadence
// ❌ transaction(pcnt: UFix64, addr: Address)
// ✅ transaction(taxPercentage: UFix64, recipientAddress: Address)
```

## Pattern 6: Plural Names for Collections
```cadence
access(self) var accounts: [Address]  // Not "account"
for account in self.accounts { }
```

## Pattern 7: Transaction Post-Conditions
Document and enforce expected results:
```cadence
post {
    self.buyerCollection.owns(nftID): "Buyer does not own NFT after purchase"
}
```

## Pattern 8: Borrow Instead of Load/Save
```cadence
// ❌ Expensive: Load and save
let vault <- signer.storage.load<@Vault>(from: /storage/vault)!
vault.someFunction()
signer.storage.save(<-vault, to: /storage/vault)

// ✅ Efficient: Borrow reference
let vaultRef = signer.storage.borrow<&Vault>(from: /storage/vault)
    ?? panic("Could not borrow Vault reference from /storage/vault")
vaultRef.someFunction()  // Resource stays in storage
```

## Pattern 9: Capability Bootstrapping via Inbox
```cadence
// Publisher
provider.inbox.publish(controller.capability, name: "myResource", recipient: recipientAddress)

// Claimer
let cap = recipient.inbox.claim<&MyResource>(name: "myResource", provider: providerAddress)
```

## Pattern 10: Pre-Issuance Capability Checks
```cadence
let existing = signer.capabilities.storage.getControllers(forPath: /storage/vault)
if existing.length > 0 { return }  // Already exists
let controller = signer.capabilities.storage.issue<&Vault>(/storage/vault)
```

## Pattern 11: Capability Revocation
Store controllers and delete when access should be removed:
```cadence
signer.capabilities.storage.delete(capabilityID)
```

## Pattern 12: Resource Wrapper
Add functionality without modifying original:
```cadence
access(all) resource EnhancedToken {
    access(self) let token: @Token
    access(all) let metadata: {String: String}
    access(all) fun getID(): UInt64 { return self.token.id }
}
```

## Pattern 13: Resource Collection
Standard dictionary-based collection with deposit/withdraw:
```cadence
access(all) resource Collection {
    access(self) var items: @{UInt64: Item}
    access(all) fun deposit(item: @Item) {
        let old <- self.items[item.id] <- item
        destroy old
    }
    access(Withdraw) fun withdraw(id: UInt64): @Item {
        return <- self.items.remove(key: id) ?? panic("Item not found")
    }
    access(all) view fun borrowItem(id: UInt64): &Item? { return &self.items[id] }
    access(all) view fun getIDs(): [UInt64] { return self.items.keys }
}
```

## Pattern 14: Storage Path Naming
```cadence
// ✅ Descriptive
/storage/flowTokenVault
/storage/exampleNFTCollection
```

## Pattern 15: Storage Existence Check
```cadence
if signer.storage.borrow<&AnyResource>(from: /storage/myResource) != nil {
    panic("Path already in use")
}
signer.storage.save(<-resource, to: /storage/myResource)
```

## Pattern 16: Descriptive Panic Messages

| Operation | Format |
|-----------|--------|
| Storage borrow | `"Could not borrow <Type> reference from /storage/path"` |
| Capability borrow | `"Could not borrow <Type> reference from /public/path"` |
| Storage load | `"<Type> not found at /storage/path"` |
| Collection lookup | `"<Type> with ID \(id) not found in collection"` |
| Balance check | `"Insufficient balance: available \(self.balance), required \(amount)"` |

Use string interpolation (`\(value)`) to include actual values:
```cadence
// ❌ "NFT not found"
// ✅ "NFT with ID \(id) not found in collection"
```

## Pattern 17: Contract Error Message Helpers
Define reusable error message functions for consistency:
```cadence
access(all) view fun vaultNotFoundError(): String {
    return "Could not borrow MyToken Vault reference from \(self.vaultStoragePath)"
}

// Usage in transactions
let vault = signer.storage.borrow<&Vault>(from: MyToken.vaultStoragePath)
    ?? panic(MyToken.vaultNotFoundError())
```
